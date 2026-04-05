#!/usr/bin/env bash
# =============================================================================
# WOW AI — Start the Orchestrator (Self-Healing, Auto-Restart)
# =============================================================================
# Fully automatic. Handles gateway service conflicts, token mismatches, and
# auto-opens the dashboard. Keeps running until Ctrl+C.
# =============================================================================

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-3000}"

echo ""
echo "========================================"
echo "  WOW AI — Starting Orchestrator"
echo "========================================"
echo ""

# ─── 1. Ensure .env exists ────────────────────────────────────────────────────
if [ ! -f ".env" ]; then
    [ -f ".env.example" ] && cp .env.example .env || { log_error ".env missing"; exit 1; }
    log_warn ".env created from .env.example — add your API keys."
fi

# ─── 2. Auto-heal gateway tokens ──────────────────────────────────────────────
log_info "Auto-healing gateway tokens..."
bash "$SCRIPT_DIR/sync-token.sh" && log_ok "Gateway tokens healthy" || \
    log_warn "Token sync had issues (continuing — dashboard URL will still work)"

# Source .env AFTER sync so we get the fresh token
set -a; source .env; set +a

# ─── 3. Start PostgreSQL ──────────────────────────────────────────────────────
log_info "Starting PostgreSQL..."
docker compose up -d postgres 2>/dev/null
for i in {1..30}; do
    docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" &>/dev/null \
        && { log_ok "PostgreSQL is ready"; break; }
    sleep 2
    [ "$i" -eq 30 ] && { log_error "PostgreSQL failed to start"; exit 1; }
done

# ─── 4. Check Redis ───────────────────────────────────────────────────────────
log_info "Checking Redis/Memurai..."
powershell.exe -Command "(Get-Service -Name 'Memurai' -ErrorAction SilentlyContinue).Status" 2>/dev/null \
    | grep -qi "running" && log_ok "Memurai running" || log_warn "Redis not detected (non-critical)"

# ─── 5. Check Ollama ──────────────────────────────────────────────────────────
log_info "Checking Ollama..."
if ! curl -sf http://localhost:${OLLAMA_PORT:-11434}/api/tags &>/dev/null; then
    ollama serve &>/dev/null & sleep 4
    curl -sf http://localhost:${OLLAMA_PORT:-11434}/api/tags &>/dev/null \
        && log_ok "Ollama started" || log_warn "Ollama unavailable (cloud fallbacks will be used)"
else
    log_ok "Ollama is running"
fi

# ─── 6. Validate OpenClaw config ──────────────────────────────────────────────
command -v openclaw &>/dev/null || { log_error "openclaw not found: npm install -g openclaw"; exit 1; }
if ! openclaw config validate &>/dev/null; then
    log_warn "Config invalid — running openclaw doctor --fix..."
    openclaw doctor --fix 2>/dev/null || true
    openclaw config validate &>/dev/null || { log_error "Config still invalid"; exit 1; }
fi
log_ok "OpenClaw config valid"

# ─── 7. Version check (non-blocking — warns if update available) ──────────────
INSTALLED_VER=$(openclaw --version 2>/dev/null | grep -oE '[0-9]{4}\.[0-9]+\.[0-9]+' | head -1 || echo "")
LATEST_VER=$(npm show openclaw version 2>/dev/null || echo "")
if [ -n "$INSTALLED_VER" ] && [ -n "$LATEST_VER" ] && [ "$INSTALLED_VER" != "$LATEST_VER" ]; then
    log_warn "OpenClaw update available: $INSTALLED_VER → $LATEST_VER"
    log_warn "Run 'npm install -g openclaw@latest && openclaw doctor' to upgrade."
else
    log_ok "OpenClaw $INSTALLED_VER (up to date)"
fi

# ─── 8. Stop any existing gateway (CRITICAL — releases Windows service lock) ──
# openclaw gateway --force kills the process but NOT the Windows Scheduled Task
# lock. If the service is registered, the lock persists → "lock timeout after 5000ms".
# `openclaw gateway stop` properly stops the service AND releases the lock.
log_info "Stopping any existing gateway (releasing service lock)..."
openclaw gateway stop 2>/dev/null || true
# Belt-and-suspenders: also stop via Windows Task Scheduler.
# NOTE: cmd.exe /c is intentionally NOT used here — MSYS2 (Git Bash) converts the
# leading /c to C:/ (a Windows drive path), so cmd.exe never sees the /c flag and
# starts an interactive session, which BLOCKS the script. Use PowerShell instead.
powershell.exe -Command "Stop-ScheduledTask -TaskName 'OpenClaw Gateway' -ErrorAction SilentlyContinue" \
    2>/dev/null || true
# Kill anything still holding the gateway port
powershell.exe -Command "
  \$procs = Get-NetTCPConnection -LocalPort $GATEWAY_PORT -ErrorAction SilentlyContinue
  if (\$procs) {
    \$procs | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force -ErrorAction SilentlyContinue }
  }
" 2>/dev/null || true
sleep 2  # give OS time to release the lock file and port
log_ok "Port $GATEWAY_PORT cleared"

# ─── 9. Dashboard URL watcher (background — fires once gateway is ready) ──────
# Waits for the gateway to respond, then generates a tokenized URL and opens it.
# The tokenized URL auto-authenticates the browser (bypasses device_token_mismatch).
(
    for i in {1..25}; do
        sleep 2
        if curl -sf --max-time 2 "http://127.0.0.1:$GATEWAY_PORT/" &>/dev/null 2>&1 || \
           curl -sf --max-time 2 "http://127.0.0.1:$GATEWAY_PORT/__openclaw__/canvas/" &>/dev/null 2>&1; then
            break
        fi
    done
    sleep 1

    DASH_URL=$(openclaw dashboard --no-open 2>/dev/null | grep -oE 'http://[^ ]+' | head -1)

    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║   DASHBOARD READY — OPENING IN BROWSER...   ║${NC}"
    echo -e "${CYAN}${BOLD}╠══════════════════════════════════════════════╣${NC}"
    if [ -n "$DASH_URL" ]; then
        echo -e "${CYAN}${BOLD}║${NC}  ${GREEN}${BOLD}$DASH_URL${NC}"
        echo -e "${CYAN}${BOLD}║${NC}  Token is embedded — auto-login, no prompt."
        echo -e "${CYAN}${BOLD}║${NC}  If still fails: press F5 once in the browser."
        echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        # Auto-open in browser (Windows Git Bash / MINGW64)
        # Use PowerShell — cmd.exe /c "start..." fails in MSYS2 (same /c path-conversion bug)
        powershell.exe -Command "Start-Process '$DASH_URL'" 2>/dev/null || true
    else
        echo -e "${CYAN}${BOLD}║${NC}  ${YELLOW}Run in a new terminal: openclaw dashboard${NC}"
        echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    fi
) &

echo ""
echo "========================================"
echo "  All services running!"
echo "========================================"
echo "  Gateway:    ws://127.0.0.1:$GATEWAY_PORT"
echo "  PostgreSQL: localhost:${POSTGRES_PORT:-5432}"
echo "  Telegram:   @ohboy441clawbot"
echo ""
echo "  Dashboard opens automatically in ~10 seconds."
echo "  Press Ctrl+C to stop the gateway."
echo "========================================"
echo ""

# ─── 10. Start gateway in foreground ──────────────────────────────────────────
# `openclaw gateway run` is the explicit foreground subcommand (future-proof).
# --force: kills any remaining listener on the port before binding.
# If this exits unexpectedly → the background watcher also exits.
openclaw gateway run --force
