#!/usr/bin/env bash
# =============================================================================
# WOW AI — Ollama Model Installer
# =============================================================================
# Downloads all required AI models for the agent swarm.
# Models are free and run locally — no API keys needed.
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
echo "  WOW AI — Model Installer"
echo "========================================"
echo ""

# Detect available VRAM
detect_vram() {
    if command -v nvidia-smi &>/dev/null; then
        VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
        if [ -n "$VRAM" ]; then
            echo "$VRAM"
            return
        fi
    fi
    echo "0"
}

VRAM=$(detect_vram)
log_info "Detected GPU VRAM: ${VRAM}MB"

# --- Model Selection Based on Hardware ---
echo ""
echo "  Model profiles:"
echo "    [1] Minimal  (8GB RAM, no GPU)  — Small models, CPU inference"
echo "    [2] Standard (16GB RAM, 8GB GPU) — Balanced performance"
echo "    [3] Full     (32GB+ RAM, 24GB+ GPU) — Maximum capability"
echo ""
read -p "  Select profile [1/2/3] (default: 1): " PROFILE
PROFILE=${PROFILE:-1}

pull_model() {
    local model="$1"
    local description="$2"
    log_info "Pulling $model — $description"
    if ollama pull "$model"; then
        log_ok "$model downloaded"
    else
        log_warn "Failed to pull $model, skipping..."
    fi
}

# --- Minimal Profile: ~8GB total download ---
log_info "Installing core models..."

# Embeddings (required for all profiles)
pull_model "nomic-embed-text" "Embeddings for semantic memory (274MB)"

# Minimal coding model
pull_model "qwen2.5-coder:7b" "Coding agent (4.7GB)"

# Minimal general model
pull_model "llama3.2:3b" "Lightweight general tasks (2GB)"

if [ "$PROFILE" -ge 2 ]; then
    echo ""
    log_info "Installing standard models..."

    # Better coding model
    pull_model "qwen2.5-coder:14b" "Primary coding agent (9GB)"

    # General reasoning
    pull_model "qwen2.5:14b" "Architect agent reasoning (9GB)"

    # DeepSeek for QA
    pull_model "deepseek-coder:6.7b" "QA agent code analysis (3.8GB)"
fi

if [ "$PROFILE" -ge 3 ]; then
    echo ""
    log_info "Installing full models..."

    # High-capability reasoning
    pull_model "llama3.3:70b" "Master Manager reasoning (40GB)"

    # NVIDIA Nemotron for agentic tasks
    pull_model "nemotron:mini" "Agentic task optimization"

    # Research model
    pull_model "llama3.3:8b" "Researcher agent (4.7GB)"
fi

# --- List installed models ---
echo ""
echo "========================================"
echo "  Installed Models"
echo "========================================"
ollama list
echo ""
log_ok "Model installation complete!"
echo ""
echo "  Note: Models are stored in ~/.ollama/models/"
echo "  Total disk usage: $(du -sh ~/.ollama/models/ 2>/dev/null | cut -f1 || echo 'unknown')"
echo ""
