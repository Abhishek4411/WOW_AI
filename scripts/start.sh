#!/usr/bin/env bash
# =============================================================================
# WOW AI — Start the Orchestrator
# =============================================================================
# Starts all services and the Master Manager agent.
# Run: chmod +x scripts/start.sh && ./scripts/start.sh
#
# SERVICES:
#   PostgreSQL:  Docker container (pgvector)
#   Redis:       Native Memurai (Windows) or redis-server (Linux)
#   Ollama:      Native local service
#   OpenClaw:    Native npm gateway
# =============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "========================================"
echo "  WOW AI — Starting Orchestrator"
echo "========================================"
echo ""

# --- Check .env ---
if [ ! -f ".env" ]; then
    log_error ".env file not found. Run: cp .env.example .env"
    exit 1
fi

# Source .env
set -a
source .env
set +a

# --- Start PostgreSQL (Docker) ---
log_info "Starting PostgreSQL..."
docker compose up -d postgres 2>/dev/null
for i in {1..30}; do
    if docker compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" &>/dev/null; then
        log_ok "PostgreSQL is ready"
        break
    fi
    sleep 2
    if [ "$i" -eq 30 ]; then
        log_error "PostgreSQL failed to start. Check: docker compose logs postgres"
        exit 1
    fi
done

# --- Check Redis (Memurai) ---
log_info "Checking Redis/Memurai..."
if powershell.exe -Command "(Get-Service -Name 'Memurai' -ErrorAction SilentlyContinue).Status" 2>/dev/null | grep -qi "running"; then
    log_ok "Memurai (Redis) is running"
elif powershell.exe -Command "(New-Object System.Net.Sockets.TcpClient).Connect('127.0.0.1', 6379)" 2>/dev/null; then
    log_ok "Redis is running on port 6379"
else
    log_warn "Redis/Memurai not detected. Start it or install Memurai."
fi

# --- Check Ollama ---
log_info "Checking Ollama..."
if curl -sf http://localhost:${OLLAMA_PORT:-11434}/api/tags &>/dev/null; then
    log_ok "Ollama is running"
else
    log_info "Starting Ollama..."
    ollama serve &>/dev/null &
    sleep 5
    if curl -sf http://localhost:${OLLAMA_PORT:-11434}/api/tags &>/dev/null; then
        log_ok "Ollama started"
    else
        log_error "Ollama failed to start. Run: ollama serve"
    fi
fi

# --- Start OpenClaw Gateway ---
log_info "Starting OpenClaw Gateway..."

if ! command -v openclaw &>/dev/null; then
    log_error "OpenClaw not installed. Run: npm install -g openclaw"
    exit 1
fi

# Validate config before starting (do NOT copy openclaw/openclaw.json here —
# the runtime config at ~/.openclaw/openclaw.json is managed by the openclaw CLI)
if ! openclaw config validate &>/dev/null; then
    log_error "OpenClaw config invalid. Run: openclaw doctor --fix"
    exit 1
fi
log_ok "OpenClaw config valid"

echo ""
echo "========================================"
echo "  All services are running!"
echo "========================================"
echo ""
echo "  Endpoints:"
echo "    Gateway:     ws://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-3000}"
echo "    PostgreSQL:  localhost:${POSTGRES_PORT:-5432}"
echo "    Redis:       localhost:6379"
echo "    Ollama:      http://localhost:${OLLAMA_PORT:-11434}"
echo ""
echo "  Telegram: @ohboy441clawbot"
echo "  Dashboard: openclaw dashboard"
echo ""
echo "  Starting gateway (Ctrl+C to stop)..."
echo "========================================"
echo ""

# Start OpenClaw gateway in foreground
openclaw gateway --force
