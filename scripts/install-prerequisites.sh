#!/usr/bin/env bash
# =============================================================================
# WOW AI — Prerequisites Installer (Windows)
# =============================================================================
# Installs all required software using winget (Windows Package Manager).
# Run from Git Bash or WSL: chmod +x scripts/install-prerequisites.sh && ./scripts/install-prerequisites.sh
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "========================================"
echo "  WOW AI — Prerequisites Installer"
echo "========================================"
echo ""

# Check winget
if ! command -v winget &>/dev/null; then
    echo "ERROR: winget not found. Install it from the Microsoft Store (App Installer)."
    exit 1
fi

install_if_missing() {
    local name="$1"
    local winget_id="$2"
    local check_cmd="$3"

    if eval "$check_cmd" &>/dev/null; then
        log_ok "$name is already installed"
    else
        log_info "Installing $name..."
        winget install --id "$winget_id" --accept-source-agreements --accept-package-agreements 2>&1 | tail -5
        log_ok "$name installed"
    fi
}

# --- Install Node.js 22 LTS ---
install_if_missing "Node.js 22" "OpenJS.NodeJS.22" "node --version"

# --- Install Git ---
install_if_missing "Git" "Git.Git" "git --version"

# --- Install Docker Desktop ---
install_if_missing "Docker Desktop" "Docker.DockerDesktop" "docker --version"

# --- Install Ollama ---
install_if_missing "Ollama" "Ollama.Ollama" "ollama --version"

# --- Install OpenClaw ---
if openclaw --version &>/dev/null 2>&1 || npx openclaw --version &>/dev/null 2>&1; then
    log_ok "OpenClaw is already installed"
else
    log_info "Installing OpenClaw via npm..."
    npm install -g openclaw@latest 2>&1 | tail -3
    log_ok "OpenClaw installed"
fi

echo ""
echo "========================================"
echo "  Prerequisites Installation Complete"
echo "========================================"
echo ""
echo "  IMPORTANT: After installing Docker Desktop:"
echo "    1. Open Docker Desktop from the Start menu"
echo "    2. Accept the license agreement"
echo "    3. Wait for Docker to finish starting"
echo "    4. Then run: docker compose up -d"
echo ""
echo "  IMPORTANT: After installing Ollama:"
echo "    1. Ollama runs as a background service"
echo "    2. Run: ./scripts/install-models.sh to download AI models"
echo ""
echo "  Next step: ./scripts/validate.sh (to verify everything)"
echo ""
