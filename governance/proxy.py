"""
WOW AI × Traccia — OpenAI API Proxy
=====================================
Sits between OpenClaw (Node.js) and OpenAI API.
Intercepts every agent LLM call and records real-time traces + costs to Traccia.

Architecture:
  OpenClaw → http://localhost:8001/v1 → THIS PROXY → https://api.openai.com/v1
                                              ↕
                                        api.traccia.ai  (real-time traces + costs)

Why we call the metrics recorder directly:
  Traccia's auto-patcher (patch_openai) only wraps the SYNC openai client.
  Our proxy uses httpx (async), which the patcher never sees. So patcher-based
  cost recording was silently skipped → $0 in the Costs tab.

  Fix: after each response, call recorder.record_cost() / record_token_usage()
  directly. These are the same methods the patcher calls internally, bypassing the
  broken gpt-4.1-mini pricing gap (Traccia's built-in table only covers gpt-4/gpt-4o).
  We compute cost ourselves using real OpenAI pricing constants.

  runtime_config.run_identity(agent_name=...) tags all metrics with the calling
  agent so the Costs tab breaks down spend by agent correctly.

Start:
  cd <project_root>
  python -m uvicorn governance.proxy:app --host 0.0.0.0 --port 8001

OpenClaw config (in ~/.openclaw/openclaw.json):
  "openai": { "baseUrl": "http://localhost:8001/v1", ... }
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

# gpt-4.1-mini pricing (per 1M tokens)
COST_PER_1M_INPUT  = 0.40   # $0.40 input (cached: $0.10)
COST_PER_1M_OUTPUT = 1.60   # $1.60 output

# ── Traccia init ───────────────────────────────────────────────────────────────
# auto_start_trace=False: each agent call creates its own trace.
# A shared root trace named "governance.proxy" appeared as a spurious agent.
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
    """Extract WOW AI agent name from the system message in an OpenAI request."""
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

    We call the metrics recorder directly instead of relying on patch_openai():
      - patch_openai() only wraps the sync openai client; our httpx proxy bypasses it.
      - Traccia's built-in pricing table lacks gpt-4.1-mini (only has gpt-4/gpt-4o),
        so _compute_cost() would return None even if the patcher fired.

    runtime_config.run_identity() tags metrics with the agent name so the Costs tab
    shows per-agent spend (master-manager, coder, researcher, etc.).
    """
    if not TRACCIA_API_KEY:
        return
    try:
        from traccia.metrics.recorder import get_metrics_recorder
        recorder = get_metrics_recorder()
        if not recorder:
            return

        attrs = {
            "gen_ai.system":       "openai",
            "gen_ai.request.model": model,
            "agent.name":          agent_name,
            "agent.id":            agent_name,
            "environment":         "production",
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
app = FastAPI(title="WOW AI × Traccia Proxy", version="2.1.0")

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
    global _session_cost_usd

    body     = await request.json()
    auth     = request.headers.get("authorization", "")
    model    = body.get("model", "gpt-4.1-mini")
    messages = body.get("messages", [])
    is_streaming = body.get("stream", False)

    agent_name = extract_agent_name(messages)

    # Conservative token estimate for policy check (//3 ≈ prose chars-per-token)
    all_text = " ".join(str(m.get("content", "")) for m in messages)
    estimated_tokens = max(len(all_text) // 3, 1)

    allowed, policy_reason = check_policies(agent_name, estimated_tokens)
    if not allowed:
        return JSONResponse(
            status_code=400,
            content={"error": {"message": f"Policy violation: {policy_reason}", "type": "policy_block"}},
        )

    # Inject stream_options so OpenAI includes usage in the final streaming chunk
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

    # @traccia.observe creates the TRACE span (shows in Traces tab with agent name).
    # _push_metrics() records cost/tokens to the METRICS backend (shows in Costs tab).
    @traccia.observe(name=agent_name)
    async def _call():
        async with httpx.AsyncClient(timeout=120) as client:
            resp = await client.post(
                f"{OPENAI_BASE_URL}/chat/completions",
                json=body,
                headers={"Authorization": auth, "Content-Type": "application/json"},
            )
            return resp

    resp = await _call()
    elapsed = time.perf_counter() - t0

    data = resp.json()
    usage = data.get("usage", {})
    input_tokens  = usage.get("prompt_tokens",     max(len(str(body)) // 3, 1))
    output_tokens = usage.get("completion_tokens", 0)
    cost = compute_cost(input_tokens, output_tokens)
    _session_cost_usd += cost

    print(f"[Proxy] {agent_name} done | {elapsed:.2f}s | "
          f"in={input_tokens} out={output_tokens} | ${cost:.5f} (session: ${_session_cost_usd:.5f})")

    _push_metrics(agent_name, model, input_tokens, output_tokens, cost, elapsed)

    return JSONResponse(content=data, status_code=resp.status_code)


async def _stream_with_trace(
    body: dict, auth: str, agent_name: str, model: str, t0: float
) -> AsyncGenerator[bytes, None]:
    global _session_cost_usd

    input_tokens  = 0
    output_tokens = 0
    error_msg     = None

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
        error_msg = str(e)
        print(f"[Proxy] Stream error for {agent_name}: {e}")

    elapsed = time.perf_counter() - t0
    if input_tokens == 0:
        input_tokens  = max(len(str(body)) // 3, 1)
        output_tokens = 100

    cost = compute_cost(input_tokens, output_tokens)
    _session_cost_usd += cost

    print(f"[Proxy] {agent_name} stream done | {elapsed:.2f}s | "
          f"in={input_tokens} out={output_tokens} | ${cost:.5f} (session: ${_session_cost_usd:.5f})")

    _push_metrics(agent_name, model, input_tokens, output_tokens, cost, elapsed)


# ── Startup / shutdown ─────────────────────────────────────────────────────────
@app.on_event("startup")
async def on_startup():
    print("[Proxy] WOW AI x Traccia proxy v2.1 listening on :8001")
    print(f"[Proxy] Forwarding to : {OPENAI_BASE_URL}")
    if TRACCIA_API_KEY:
        print("[Proxy] Traccia enabled - open traccia.ai/dashboard")
        # Verify metrics recorder is available at boot so failures are visible in logs
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
