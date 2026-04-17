"""
WOW AI × Traccia — OpenAI API Proxy
=====================================
Sits between OpenClaw (Node.js) and OpenAI API.
Intercepts every agent LLM call and records real-time traces to Traccia.

Architecture:
  OpenClaw → http://localhost:8001/v1 → THIS PROXY → https://api.openai.com/v1
                                              ↕
                                        api.traccia.ai  (real-time traces)

Start:
  cd <project_root>
  python -m uvicorn governance.proxy:app --host 0.0.0.0 --port 8001

OpenClaw config change needed (in ~/.openclaw/openclaw.json):
  "openai": { "baseUrl": "http://localhost:8001/v1", ... }
"""

import json
import os
import time
import asyncio
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

COST_PER_1M_INPUT  = 0.20   # gpt-4.1-mini input
COST_PER_1M_OUTPUT = 0.80   # gpt-4.1-mini output

# ── Traccia init ──────────────────────────────────────────────────────────────
# auto_start_trace=False: each agent call creates its own trace, not a shared root.
# A shared root caused "governance.proxy" to appear as a spurious agent in the dashboard.
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
                # Content can be a list of dicts for vision requests
                content = " ".join(
                    part.get("text", "") for part in content if isinstance(part, dict)
                )
            content_upper = content.upper()
            for agent_name, patterns in AGENT_PATTERNS.items():
                if any(p in content_upper for p in patterns):
                    return agent_name
    return "unknown-agent"

def estimate_cost(input_tokens: int, output_tokens: int) -> float:
    return (input_tokens / 1_000_000 * COST_PER_1M_INPUT +
            output_tokens / 1_000_000 * COST_PER_1M_OUTPUT)

# ── Policy enforcement ────────────────────────────────────────────────────────
# gpt-4.1-mini supports 1M input tokens ($0.40/1M). Master-manager SOUL.md alone
# is ~34K chars. Limit set to 500K tokens (~$0.20 max per call) — blocks runaway
# loops, not normal agent operation.
POLICIES = {
    "max_tokens_per_call":  500_000,  # hard-block above this (gpt-4.1-mini limit is 1M)
    "max_session_cost_usd": 2.00,     # soft-warn above this
    "agent_allowlist": [
        "master-manager", "architect", "coder", "qa",
        "researcher", "devops", "tool-maker", "unknown-agent",
    ],
}

def check_policies(agent_name: str, estimated_input_tokens: int) -> tuple[bool, str]:
    """
    Returns (allowed: bool, reason: str).
    Logs policy checks to Traccia via guardrail_span if available.
    """
    global _session_cost_usd

    # Policy 1: token limit
    if estimated_input_tokens > POLICIES["max_tokens_per_call"]:
        reason = (f"Agent '{agent_name}' estimated {estimated_input_tokens} tokens "
                  f"- exceeds hard limit of {POLICIES['max_tokens_per_call']}")
        print(f"[Traccia Policy] HARD BLOCK - {reason}")
        try:
            from traccia.guardrails import guardrail_span
            from traccia.guardrails.schema import (
                GuardrailFinding, EnforcementMode, GuardrailCategory, Confidence, SourceType
            )
            with guardrail_span("token-limit-policy", category="token_limit",
                                enforcement_mode="block", policy_id="wow-token-policy-001"):
                GuardrailFinding(
                    category=GuardrailCategory.SAFETY,
                    name="token-limit-policy",
                    source_type=SourceType.CUSTOM,
                    confidence=Confidence.HIGH,
                    triggered=True,
                    enforcement_mode=EnforcementMode.BLOCK,
                    detection_reason=reason,
                )
        except Exception:
            pass
        return False, reason

    # Policy 2: session cost (soft warn — don't block)
    if _session_cost_usd > POLICIES["max_session_cost_usd"]:
        print(f"[Traccia Policy] SOFT WARN - session cost ${_session_cost_usd:.4f} "
              f"exceeds ${POLICIES['max_session_cost_usd']} threshold")
        try:
            from traccia.guardrails import guardrail_span
            with guardrail_span("cost-limit-policy", category="cost_limit",
                                enforcement_mode="warn", policy_id="wow-cost-policy-001"):
                pass
        except Exception:
            pass

    # Policy 3: agent allowlist
    if agent_name not in POLICIES["agent_allowlist"]:
        reason = f"Agent '{agent_name}' is not in the approved allowlist"
        print(f"[Traccia Policy] HARD BLOCK - {reason}")
        return False, reason

    return True, "ok"

# ── FastAPI app ───────────────────────────────────────────────────────────────
app = FastAPI(title="WOW AI × Traccia Proxy", version="1.0.0")

@app.get("/health")
async def health():
    return {"status": "ok", "traccia": bool(TRACCIA_API_KEY), "proxy_target": OPENAI_BASE_URL}

# ── Models passthrough (OpenClaw calls /v1/models on startup) ─────────────────
@app.get("/v1/models")
async def list_models(request: Request):
    auth = request.headers.get("authorization", "")
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(
            f"{OPENAI_BASE_URL}/models",
            headers={"Authorization": auth},
        )
        return JSONResponse(content=resp.json(), status_code=resp.status_code)

# ── Main proxy endpoint ───────────────────────────────────────────────────────
@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    global _session_cost_usd

    body = await request.json()
    auth = request.headers.get("authorization", "")
    model = body.get("model", "gpt-4.1-mini")
    messages = body.get("messages", [])
    is_streaming = body.get("stream", False)

    agent_name = extract_agent_name(messages)

    # Estimate token count for policy check.
    # GPT tokenizer averages ~4 chars/token for code, ~3 chars/token for prose.
    # Using //3 gives a conservative (slightly high) estimate without being punitive.
    all_text = " ".join(
        str(m.get("content", "")) for m in messages
    )
    estimated_tokens = max(len(all_text) // 3, 1)

    allowed, policy_reason = check_policies(agent_name, estimated_tokens)
    if not allowed:
        return JSONResponse(
            status_code=400,
            content={"error": {"message": f"Policy violation: {policy_reason}", "type": "policy_block"}},
        )

    # Inject stream_options to get usage in streaming responses
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

    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(
            f"{OPENAI_BASE_URL}/chat/completions",
            json=body,
            headers={"Authorization": auth, "Content-Type": "application/json"},
        )

    elapsed = time.perf_counter() - t0
    data = resp.json()
    usage = data.get("usage", {})
    input_tokens  = usage.get("prompt_tokens", estimated_tokens := max(len(str(body)) // 4, 1))
    output_tokens = usage.get("completion_tokens", 0)
    cost = estimate_cost(input_tokens, output_tokens)
    _session_cost_usd += cost

    print(f"[Proxy] {agent_name} done | {elapsed:.2f}s | "
          f"in={input_tokens} out={output_tokens} | ${cost:.5f} (session: ${_session_cost_usd:.5f})")

    _record_trace(agent_name, model, input_tokens, output_tokens, cost, elapsed, error=None)

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
                    # Parse SSE chunks to extract usage from the final chunk
                    try:
                        text = raw_chunk.decode("utf-8", errors="ignore")
                        for line in text.splitlines():
                            if not line.startswith("data: "):
                                continue
                            payload = line[6:].strip()
                            if payload == "[DONE]":
                                continue
                            chunk_data = json.loads(payload)
                            # OpenAI sends usage in the last chunk when stream_options.include_usage=true
                            if "usage" in chunk_data and chunk_data["usage"]:
                                u = chunk_data["usage"]
                                input_tokens  = u.get("prompt_tokens", 0)
                                output_tokens = u.get("completion_tokens", 0)
                    except Exception:
                        pass

    except Exception as e:
        error_msg = str(e)
        print(f"[Proxy] Stream error for {agent_name}: {e}")

    elapsed = time.perf_counter() - t0
    if input_tokens == 0:
        # Fallback estimate if usage wasn't in stream
        input_tokens = max(len(str(body)) // 4, 1)
        output_tokens = 100  # rough fallback

    cost = estimate_cost(input_tokens, output_tokens)
    _session_cost_usd += cost

    print(f"[Proxy] {agent_name} stream done | {elapsed:.2f}s | "
          f"in={input_tokens} out={output_tokens} | ${cost:.5f} (session: ${_session_cost_usd:.5f})")

    _record_trace(agent_name, model, input_tokens, output_tokens, cost, elapsed, error=error_msg)


def _record_trace(
    agent_name: str, model: str,
    input_tokens: int, output_tokens: int,
    cost_usd: float, latency_s: float,
    error: str | None,
) -> None:
    """Send a structured LLM span to Traccia so tokens/cost/latency show in dashboard."""
    if not TRACCIA_API_KEY:
        return
    try:
        # Pass token counts as structured attributes so Traccia renders them correctly.
        # Standard OTel/GenAI semantic conventions for LLM spans:
        span_attrs = {
            "gen_ai.system":                  "openai",
            "gen_ai.request.model":           model,
            "gen_ai.usage.input_tokens":      input_tokens,
            "gen_ai.usage.output_tokens":     input_tokens + output_tokens,  # total
            "gen_ai.usage.prompt_tokens":     input_tokens,
            "gen_ai.usage.completion_tokens": output_tokens,
            "llm.usage.cost_usd":             round(cost_usd, 6),
            "llm.latency_s":                  round(latency_s, 3),
            "wow_ai.agent":                   agent_name,
        }
        if error:
            span_attrs["error.message"] = error

        @traccia.observe(name=agent_name, as_type="llm", attributes=span_attrs)
        def _send() -> str:
            return (
                f"agent={agent_name} model={model} "
                f"in={input_tokens} out={output_tokens} "
                f"cost_usd={cost_usd:.6f} latency_s={latency_s:.3f}"
                + (f" error={error}" if error else "")
            )

        _send()
    except Exception as e:
        print(f"[Traccia] Trace record warning: {e}")


# ── Startup / shutdown ────────────────────────────────────────────────────────
@app.on_event("startup")
async def on_startup():
    print("[Proxy] WOW AI x Traccia proxy listening on :8001")
    print(f"[Proxy] Forwarding to : {OPENAI_BASE_URL}")
    if TRACCIA_API_KEY:
        print("[Proxy] Traccia enabled - open traccia.ai/dashboard")
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
