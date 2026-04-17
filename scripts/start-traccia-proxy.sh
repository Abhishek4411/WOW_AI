#!/usr/bin/env bash
# =============================================================================
# WOW AI — Traccia Governance Proxy Startup
# =============================================================================
# Starts the OpenAI API proxy that intercepts all OpenClaw agent calls and
# records real-time traces to the Traccia dashboard.
#
# How it works:
#   OpenClaw is configured to call http://localhost:8001/v1 (not api.openai.com).
#   This proxy intercepts every /v1/chat/completions call, records traces to
#   Traccia, then forwards the request to real OpenAI and streams back the reply.
#
# Usage:
#   bash scripts/start-traccia-proxy.sh
#
# Logs:
#   traccia/.proxy.log   — uvicorn output
#   traccia/.proxy.pid   — PID of the uvicorn process
# =============================================================================

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

log_info()  { echo -e "${BLUE}[Traccia]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[Traccia]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[Traccia]${NC} $1"; }
log_error() { echo -e "${RED}[Traccia]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TRACCIA_DIR="$PROJECT_ROOT/governance"
VENV_DIR="$TRACCIA_DIR/.venv"
PID_FILE="$TRACCIA_DIR/.proxy.pid"
LOG_FILE="$TRACCIA_DIR/.proxy.log"
PROXY_PORT=8001

# ─── 0. Check Python is available ─────────────────────────────────────────────
if ! command -v python &>/dev/null && ! command -v python3 &>/dev/null; then
    log_error "Python not found. Install Python 3.9+ and re-run."
    exit 1
fi
PYTHON=$(command -v python3 || command -v python)

# ─── 1. Kill any existing proxy on port 8001 ──────────────────────────────────
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        log_info "Stopping existing proxy (PID $OLD_PID)..."
        kill "$OLD_PID" 2>/dev/null || true
        sleep 1
    fi
    rm -f "$PID_FILE"
fi

# Also kill anything on port 8001 via PowerShell (Windows)
powershell.exe -Command "
  \$procs = Get-NetTCPConnection -LocalPort $PROXY_PORT -ErrorAction SilentlyContinue
  if (\$procs) {
    \$procs | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 500
  }
" 2>/dev/null || true

# ─── 2. Create/update venv ────────────────────────────────────────────────────
if [ ! -d "$VENV_DIR" ]; then
    log_info "Creating Python venv at traccia/.venv ..."
    "$PYTHON" -m venv "$VENV_DIR" || { log_error "venv creation failed"; exit 1; }
fi

VENV_PYTHON="$VENV_DIR/Scripts/python"       # Windows Git Bash path
[ ! -f "$VENV_PYTHON" ] && VENV_PYTHON="$VENV_DIR/bin/python"  # Unix fallback

# ─── 3. Install dependencies ──────────────────────────────────────────────────
log_info "Installing/updating traccia dependencies..."
"$VENV_PYTHON" -m pip install --quiet --upgrade -r "$TRACCIA_DIR/requirements.txt" \
    && log_ok "Dependencies ready" \
    || { log_error "pip install failed — check traccia/requirements.txt"; exit 1; }

# ─── 4. Verify TRACCIA_API_KEY is set ─────────────────────────────────────────
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a; source "$PROJECT_ROOT/.env"; set +a
fi

if [ -z "${TRACCIA_API_KEY:-}" ] || [ "$TRACCIA_API_KEY" = "tr_dev_your_traccia_api_key_here" ]; then
    log_warn "TRACCIA_API_KEY not set — proxy will run but Traccia tracing is disabled"
    log_warn "Add TRACCIA_API_KEY to your .env file to enable real-time governance"
fi

# ─── 5. Start proxy in background ────────────────────────────────────────────
log_info "Starting Traccia proxy on port $PROXY_PORT..."
cd "$PROJECT_ROOT"

PYTHONIOENCODING=utf-8 "$VENV_PYTHON" -m uvicorn governance.proxy:app \
    --host 0.0.0.0 \
    --port "$PROXY_PORT" \
    --workers 1 \
    --log-level warning \
    > "$LOG_FILE" 2>&1 &

PROXY_PID=$!
echo "$PROXY_PID" > "$PID_FILE"

# ─── 6. Wait for proxy to be ready (up to 15 seconds) ────────────────────────
for i in {1..15}; do
    sleep 1
    if curl -sf --max-time 2 "http://localhost:$PROXY_PORT/health" &>/dev/null; then
        log_ok "Traccia proxy ready on :$PROXY_PORT (PID $PROXY_PID)"
        if [ -n "${TRACCIA_API_KEY:-}" ] && [ "$TRACCIA_API_KEY" != "tr_dev_your_traccia_api_key_here" ]; then
            log_ok "Open traccia.ai/dashboard to see real-time agent traces"
        fi
        exit 0
    fi
    if ! kill -0 "$PROXY_PID" 2>/dev/null; then
        log_error "Proxy process died. Check traccia/.proxy.log for details:"
        tail -20 "$LOG_FILE" 2>/dev/null || true
        exit 1
    fi
done

log_error "Proxy did not respond after 15 seconds. Check traccia/.proxy.log"
exit 1
