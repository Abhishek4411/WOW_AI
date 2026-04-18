"""
WOW AI × Traccia — OpenAI API Proxy
=====================================
Sits between OpenClaw (Node.js) and OpenAI API.
Intercepts every agent LLM call and records real-time traces + costs to Traccia.

Architecture:
  OpenClaw → http://localhost:8001/v1 → THIS PROXY → https://api.openai.com/v1
                                              ↕
                                        api.traccia.ai  (real-time traces + costs)

How tracing works:
  Traccia's AgentEnrichmentProcessor.on_end() resolves agent identity in this order:
    1. span attribute "agent.id"   ← we set this explicitly per request
    2. runtime_config.get_agent_id()
    3. init-time default

  So we:
    a) Get a tracer named after the agent: traccia.get_tracer(agent_name)
       → tracer.instrumentation_scope == agent_name (last-resort fallback)
    b) Start a span with "agent.id" and "agent.name" set explicitly
       → AgentEnrichmentProcessor picks these up on span end
    c) Set real token counts ON the span after the httpx response
       → Traces tab shows actual tokens instead of 0
    d) Call _push_metrics() after each call to record cost/tokens directly
       to Traccia's metrics backend, bypassing the built-in pricing table
       that lacks gpt-4.1-mini (table only covers gpt-4/gpt-4o).
       → Costs tab shows real USD spend broken down by agent.

Start:
  cd <project_root>
  python -m uvicorn governance.proxy:app --host 0.0.0.0 --port 8001
"""

import json
import os
import time
from typing import AsyncGenerator

import httpx
import traccia
from traccia import runtime_config
from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, StreamingResponse

# ── Load env ──────────────────────────────────────────────────────────────────
load_dotenv()

TRACCIA_API_KEY = os.getenv("TRACCIA_API_KEY", "")
OPENAI_BASE_URL = "https://api.openai.com/v1"

# gpt-4.1-mini pricing (per 1M tokens) — Traccia's built-in table lacks this model
COST_PER_1M_INPUT  = 0.40   # $0.40 input
COST_PER_1M_OUTPUT = 1.60   # $1.60 output

# ── Traccia init ───────────────────────────────────────────────────────────────
if TRACCIA_API_KEY:
    traccia.init(
        api_key=TRACCIA_API_KEY,
        auto_start_trace=False,
        project_id="wow-ai-orchestrator",
        env="production",
    )
    runtime_config.set_env("production")
    runtime_config.set_project_id("wow-ai-orchestrator")
    print("[Traccia] Initialized -- traces -> traccia.ai/dashboard")
else:
    print("[Traccia] WARNING: TRACCIA_API_KEY not set - tracing disabled, proxy still works")

# ── Session cost tracker ───────────────────────────────────────────────────────
_session_cost_usd: float = 0.0

# ── Agent name extraction ──────────────────────────────────────────────────────
AGENT_PATTERNS: dict[str, list[str]] = {
    "master-manager": ["MASTER MANAGER", "MASTER_MANAGER", "WOW AI MASTER", "MASTER MANAGER AGENT"],
    "architect":      ["ARCHITECT"],
    "coder":          ["CODER"],
    "qa":             ["QUALITY ASSURANCE", "QA AGENT", "YOU ARE THE QA"],
    "researcher":     ["RESEARCHER"],
    "devops":         ["DEVOPS"],
    "tool-maker":     ["TOOL-MAKER", "TOOL MAKER"],
}

def extract_agent_name(messages: list[dict]) -> str:
    for msg in messages:
        if msg.get("role") == "system":
            content = msg.get("content", "")
            if isinstance(content, list):
                content = " ".join(
                    part.get("text", "") for part in content if isinstance(part, dict)
                )
            content_upper = content.upper()
            for agent_name, patterns in AGENT_PATTERNS.items():
                if any(p in content_upper for p in patterns):
                    return agent_name
    return "unknown-agent"

def compute_cost(input_tokens: int, output_tokens: int) -> float:
    return (input_tokens / 1_000_000 * COST_PER_1M_INPUT +
            output_tokens / 1_000_000 * COST_PER_1M_OUTPUT)

# ── Traccia cost + token recording ────────────────────────────────────────────
def _push_metrics(
    agent_name: str, model: str,
    input_tokens: int, output_tokens: int,
    cost_usd: float, latency_s: float,
) -> None:
    """
    Push token usage, cost, and latency to Traccia's metrics backend.

    Traccia's pricing table only covers gpt-4/gpt-4o; gpt-4.1-mini is absent so
    its built-in _compute_cost() returns None. We calculate cost ourselves and push
    directly via recorder.record_cost(). runtime_config.run_identity() tags all
    metrics with the agent name so the Costs tab shows per-agent spend.
    """
    if not TRACCIA_API_KEY:
        return
    try:
        from traccia.metrics.recorder import get_metrics_recorder
        recorder = get_metrics_recorder()
        if not recorder:
            print("[Traccia] Metrics recorder not available — skipping cost push")
            return

        attrs = {
            "gen_ai.system":        "openai",
            "gen_ai.request.model": model,
            "agent.name":           agent_name,
            "agent.id":             agent_name,
            "environment":          "production",
        }

        with runtime_config.run_identity(agent_id=agent_name, agent_name=agent_name):
            recorder.record_token_usage(
                prompt_tokens=input_tokens,
                completion_tokens=output_tokens,
                attributes=attrs,
            )
            recorder.record_cost(cost_usd, attributes=attrs)
            recorder.record_duration(latency_s, attributes=attrs)

    except Exception as e:
        print(f"[Traccia] Metrics push FAILED: {type(e).__name__}: {e}")

# ── Traccia span helpers ───────────────────────────────────────────────────────
def _start_agent_span(agent_name: str, model: str):
    """
    Create a Traccia span named after the agent with explicit agent.id attribute.

    AgentEnrichmentProcessor.on_end() reads span attributes in this priority order:
      attrs["agent.id"] > runtime_config.get_agent_id() > init-time default

    Setting agent.id on the span guarantees the Traces tab shows the correct agent
    name (master-manager, coder, etc.) instead of the module name (governance.proxy).

    Using traccia.get_tracer(agent_name) also sets instrumentation_scope to the
    agent name, which AgentEnrichmentProcessor uses as a last-resort fallback.
    """
    if not TRACCIA_API_KEY:
        return None
    try:
        tracer = traccia.get_tracer(agent_name)
        span = tracer.start_span(
            agent_name,
            attributes={
                "agent.id":             agent_name,
                "agent.name":           agent_name,
                "gen_ai.system":        "openai",
                "gen_ai.request.model": model,
                "span.type":            "llm",
                "environment":          "production",
            },
        )
        return span
    except Exception as e:
        print(f"[Traccia] Span creation FAILED: {type(e).__name__}: {e}")
        return None

def _enrich_span(span, input_tokens: int, output_tokens: int, cost_usd: float) -> None:
    """Set LLM token + cost attributes on a span so Traces tab shows real numbers."""
    if span is None:
        return
    try:
        span.set_attribute("gen_ai.usage.prompt_tokens",     input_tokens)
        span.set_attribute("gen_ai.usage.completion_tokens", output_tokens)
        span.set_attribute("llm.usage.prompt_tokens",        input_tokens)
        span.set_attribute("llm.usage.completion_tokens",    output_tokens)
        span.set_attribute("llm.usage.total_tokens",         input_tokens + output_tokens)
        span.set_attribute("llm.usage.cost_usd",             round(cost_usd, 6))
    except Exception as e:
        print(f"[Traccia] Span enrich FAILED: {type(e).__name__}: {e}")

# ── Policy enforcement ─────────────────────────────────────────────────────────
POLICIES = {
    "max_tokens_per_call":  500_000,
    "max_session_cost_usd": 2.00,
    "agent_allowlist": [
        "master-manager", "architect", "coder", "qa",
        "researcher", "devops", "tool-maker", "unknown-agent",
    ],
}

def check_policies(agent_name: str, estimated_input_tokens: int) -> tuple[bool, str]:
    global _session_cost_usd

    if estimated_input_tokens > POLICIES["max_tokens_per_call"]:
        reason = (f"Agent '{agent_name}' estimated {estimated_input_tokens} tokens "
                  f"- exceeds hard limit of {POLICIES['max_tokens_per_call']}")
        print(f"[Policy] HARD BLOCK - {reason}")
        try:
            from traccia.guardrails import guardrail_span
            with guardrail_span("token-limit-policy", category="token_limit",
                                enforcement_mode="block", policy_id="wow-token-policy-001"):
                pass
        except Exception:
            pass
        return False, reason

    if _session_cost_usd > POLICIES["max_session_cost_usd"]:
        print(f"[Policy] SOFT WARN - session cost ${_session_cost_usd:.4f} "
              f"exceeds ${POLICIES['max_session_cost_usd']}")
        try:
            from traccia.guardrails import guardrail_span
            with guardrail_span("cost-limit-policy", category="cost_limit",
                                enforcement_mode="warn", policy_id="wow-cost-policy-001"):
                pass
        except Exception:
            pass

    if agent_name not in POLICIES["agent_allowlist"]:
        reason = f"Agent '{agent_name}' is not in the approved allowlist"
        print(f"[Policy] HARD BLOCK - {reason}")
        return False, reason

    return True, "ok"

# ── FastAPI app ────────────────────────────────────────────────────────────────
app = FastAPI(title="WOW AI × Traccia Proxy", version="3.1.0")

@app.get("/health")
async def health():
    return {"status": "ok", "traccia": bool(TRACCIA_API_KEY), "proxy_target": OPENAI_BASE_URL}

# ── Models passthrough (OpenClaw calls /v1/models on startup) ──────────────────
@app.get("/v1/models")
async def list_models(request: Request):
    auth = request.headers.get("authorization", "")
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(
            f"{OPENAI_BASE_URL}/models",
            headers={"Authorization": auth},
        )
        return JSONResponse(content=resp.json(), status_code=resp.status_code)

# ── Main proxy endpoint ────────────────────────────────────────────────────────
@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    body         = await request.json()
    auth         = request.headers.get("authorization", "")
    model        = body.get("model", "gpt-4.1-mini")
    messages     = body.get("messages", [])
    is_streaming = body.get("stream", False)

    agent_name = extract_agent_name(messages)

    all_text         = " ".join(str(m.get("content", "")) for m in messages)
    estimated_tokens = max(len(all_text) // 3, 1)

    allowed, policy_reason = check_policies(agent_name, estimated_tokens)
    if not allowed:
        return JSONResponse(
            status_code=400,
            content={"error": {"message": f"Policy violation: {policy_reason}", "type": "policy_block"}},
        )

    if is_streaming:
        body = {**body, "stream_options": {"include_usage": True}}

    print(f"[Proxy] {agent_name} -> {model} | stream={is_streaming} | ~{estimated_tokens} tokens")
    t0 = time.perf_counter()

    if is_streaming:
        return StreamingResponse(
            _stream_with_trace(body, auth, agent_name, model, t0),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )
    else:
        return await _non_stream_with_trace(body, auth, agent_name, model, t0)


async def _non_stream_with_trace(
    body: dict, auth: str, agent_name: str, model: str, t0: float
) -> JSONResponse:
    global _session_cost_usd

    span = _start_agent_span(agent_name, model)

    # Use span as context manager so it is set as the OTel current span.
    # Span stays open across the httpx call; attributes are set on it before __exit__.
    ctx = span.__enter__() if span is not None else None
    try:
        async with httpx.AsyncClient(timeout=120) as client:
            resp = await client.post(
                f"{OPENAI_BASE_URL}/chat/completions",
                json=body,
                headers={"Authorization": auth, "Content-Type": "application/json"},
            )

        elapsed = time.perf_counter() - t0
        data = resp.json()
        usage = data.get("usage", {})
        input_tokens  = usage.get("prompt_tokens",     max(len(str(body)) // 3, 1))
        output_tokens = usage.get("completion_tokens", 0)
        cost = compute_cost(input_tokens, output_tokens)
        _session_cost_usd += cost

        _enrich_span(span, input_tokens, output_tokens, cost)

        print(f"[Proxy] {agent_name} done | {elapsed:.2f}s | "
              f"in={input_tokens} out={output_tokens} | ${cost:.5f} (session: ${_session_cost_usd:.5f})")

        _push_metrics(agent_name, model, input_tokens, output_tokens, cost, elapsed)

        return JSONResponse(content=data, status_code=resp.status_code)

    except Exception as exc:
        if span is not None:
            try:
                span.record_exception(exc)
            except Exception:
                pass
        raise
    finally:
        if span is not None:
            span.__exit__(None, None, None)


async def _stream_with_trace(
    body: dict, auth: str, agent_name: str, model: str, t0: float
) -> AsyncGenerator[bytes, None]:
    global _session_cost_usd

    span = _start_agent_span(agent_name, model)
    if span is not None:
        span.__enter__()

    input_tokens  = 0
    output_tokens = 0

    try:
        async with httpx.AsyncClient(timeout=120) as client:
            async with client.stream(
                "POST",
                f"{OPENAI_BASE_URL}/chat/completions",
                json=body,
                headers={"Authorization": auth, "Content-Type": "application/json"},
            ) as resp:
                async for raw_chunk in resp.aiter_bytes():
                    yield raw_chunk
                    try:
                        text = raw_chunk.decode("utf-8", errors="ignore")
                        for line in text.splitlines():
                            if not line.startswith("data: "):
                                continue
                            payload = line[6:].strip()
                            if payload == "[DONE]":
                                continue
                            chunk_data = json.loads(payload)
                            if "usage" in chunk_data and chunk_data["usage"]:
                                u = chunk_data["usage"]
                                input_tokens  = u.get("prompt_tokens",     0)
                                output_tokens = u.get("completion_tokens", 0)
                    except Exception:
                        pass

    except Exception as e:
        print(f"[Proxy] Stream error for {agent_name}: {e}")

    elapsed = time.perf_counter() - t0
    if input_tokens == 0:
        input_tokens  = max(len(str(body)) // 3, 1)
        output_tokens = 100

    cost = compute_cost(input_tokens, output_tokens)
    _session_cost_usd += cost

    print(f"[Proxy] {agent_name} stream done | {elapsed:.2f}s | "
          f"in={input_tokens} out={output_tokens} | ${cost:.5f} (session: ${_session_cost_usd:.5f})")

    _enrich_span(span, input_tokens, output_tokens, cost)
    _push_metrics(agent_name, model, input_tokens, output_tokens, cost, elapsed)

    if span is not None:
        span.__exit__(None, None, None)


# ── Startup / shutdown ─────────────────────────────────────────────────────────
@app.on_event("startup")
async def on_startup():
    print("[Proxy] WOW AI x Traccia proxy v3.1 listening on :8001")
    print(f"[Proxy] Forwarding to : {OPENAI_BASE_URL}")
    if TRACCIA_API_KEY:
        print("[Proxy] Traccia enabled - open traccia.ai/dashboard")
        try:
            from traccia.metrics.recorder import get_metrics_recorder
            recorder = get_metrics_recorder()
            if recorder:
                print("[Proxy] Metrics recorder: READY — cost will appear in Traccia Costs tab")
            else:
                print("[Proxy] Metrics recorder: NOT READY — cost may not appear (check TRACCIA_API_KEY)")
        except Exception as e:
            print(f"[Proxy] Metrics recorder check failed: {e}")
    else:
        print("[Proxy] Traccia DISABLED - set TRACCIA_API_KEY in .env")

@app.on_event("shutdown")
async def on_shutdown():
    if TRACCIA_API_KEY:
        try:
            traccia.force_flush()
            print("[Traccia] Final flush complete")
        except Exception:
            pass
