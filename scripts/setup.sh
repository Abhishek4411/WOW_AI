#!/usr/bin/env bash
# =============================================================================
# WOW AI — One-Click Setup Script
# =============================================================================
# This script sets up the complete local development environment.
# Run: chmod +x scripts/setup.sh && ./scripts/setup.sh
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "========================================"
echo "  WOW AI — Autonomous Agent Orchestrator"
echo "  Setup Script"
echo "========================================"
echo ""

# --- Check prerequisites ---
log_info "Checking prerequisites..."

check_command() {
    if command -v "$1" &>/dev/null; then
        log_ok "$1 is installed"
        return 0
    else
        log_error "$1 is NOT installed"
        return 1
    fi
}

MISSING=0
check_command "docker" || MISSING=1
check_command "docker" && docker compose version &>/dev/null && log_ok "Docker Compose is available" || { log_error "Docker Compose is NOT available"; MISSING=1; }
check_command "node" || MISSING=1
check_command "npm" || MISSING=1
check_command "git" || MISSING=1

if [ "$MISSING" -eq 1 ]; then
    log_error "Please install missing prerequisites before continuing."
    echo ""
    echo "Install guides:"
    echo "  Docker:  https://docs.docker.com/get-docker/"
    echo "  Node.js: https://nodejs.org/ (v20+)"
    echo "  Git:     https://git-scm.com/"
    exit 1
fi

# --- Check for .env file ---
log_info "Checking environment configuration..."

if [ ! -f ".env" ]; then
    log_warn ".env file not found. Creating from .env.example..."
    cp .env.example .env
    log_warn "IMPORTANT: Edit .env and add your API keys before starting!"
    echo ""
    echo "  Required API keys:"
    echo "    - GROQ_API_KEY      → https://console.groq.com"
    echo "    - GEMINI_API_KEY    → https://aistudio.google.com"
    echo "    - TELEGRAM_BOT_TOKEN → Create via @BotFather on Telegram"
    echo "    - GITHUB_TOKEN      → https://github.com/settings/tokens"
    echo ""
    read -p "  Press Enter after editing .env, or Ctrl+C to exit..."
fi

log_ok "Environment configuration ready"

# --- Install Ollama (if not installed) ---
log_info "Checking Ollama..."

if command -v ollama &>/dev/null; then
    log_ok "Ollama is already installed"
else
    log_info "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    log_ok "Ollama installed"
fi

# --- Start Docker services ---
log_info "Starting Docker services (PostgreSQL, Redis, Ollama)..."
docker compose up -d postgres redis ollama

log_info "Waiting for services to be healthy..."
sleep 10

# Check service health
docker compose ps

# --- Download Ollama models ---
log_info "Downloading AI models via Ollama..."
echo "  This may take a while depending on your internet speed."
echo ""

bash scripts/install-models.sh

# --- Install OpenClaw ---
log_info "Installing OpenClaw..."

if command -v openclaw &>/dev/null; then
    log_ok "OpenClaw is already installed"
else
    npm install -g openclaw
    log_ok "OpenClaw installed"
fi

# --- Install NemoClaw (optional) ---
log_info "Checking NemoClaw..."
echo ""
echo "  NemoClaw adds enterprise security (sandbox, policies)."
echo "  It is currently in ALPHA (March 2026)."
echo ""
read -p "  Install NemoClaw? (y/N): " INSTALL_NEMOCLAW

if [[ "$INSTALL_NEMOCLAW" =~ ^[Yy]$ ]]; then
    log_info "Installing NemoClaw..."
    curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash
    log_ok "NemoClaw installed"
else
    log_warn "Skipping NemoClaw. You can install it later."
fi

# --- Initialize Git repository ---
log_info "Initializing Git repository..."

if [ ! -d ".git" ]; then
    git init
    echo ".env" > .gitignore
    echo "node_modules/" >> .gitignore
    echo "logs/" >> .gitignore
    echo "*.log" >> .gitignore
    git add -A
    git commit -m "feat: initial WOW AI orchestrator scaffolding"
    log_ok "Git repository initialized"
else
    log_ok "Git repository already exists"
fi

# --- Summary ---
echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "  Next steps:"
echo "  1. Edit .env with your API keys (if not done)"
echo "  2. Run: ./scripts/start.sh"
echo "  3. Send a message to your Telegram bot"
echo ""
echo "  Services running:"
echo "    PostgreSQL:  localhost:5432"
echo "    Redis:       localhost:6379"
echo "    Ollama:      localhost:11434"
echo ""
echo "  Useful commands:"
echo "    docker compose logs -f    # View all logs"
echo "    docker compose ps         # Check service status"
echo "    docker compose down       # Stop all services"
echo ""
