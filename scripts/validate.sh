#!/usr/bin/env bash
# =============================================================================
# WOW AI — Automated Validation Script
# =============================================================================
# Validates the entire project: prerequisites, configs, services, connectivity.
# Run: chmod +x scripts/validate.sh && ./scripts/validate.sh
#
# SETUP LAYOUT (2026-03-20):
#   PostgreSQL: Docker container (pgvector/pgvector:pg16)
#   Redis:      Native Memurai service on Windows (port 6379)
#   Ollama:     Native local service (port 11434)
#   OpenClaw:   Native npm global install + gateway service
# =============================================================================

set -uo pipefail
# Note: deliberately no -e since validation checks may return non-zero

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() { echo -e "  ${GREEN}PASS${NC} $1"; ((PASS++)); }
check_fail() { echo -e "  ${RED}FAIL${NC} $1"; ((FAIL++)); }
check_warn() { echo -e "  ${YELLOW}WARN${NC} $1"; ((WARN++)); }

echo ""
echo "========================================"
echo "  WOW AI — Full Validation Suite"
echo "  $(date)"
echo "========================================"

# ==========================================
# 1. PREREQUISITES
# ==========================================
echo ""
echo -e "${BLUE}[1/8] Checking Prerequisites${NC}"

# Node.js
if command -v node &>/dev/null; then
    NODE_VER=$(node --version)
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1 | tr -d 'v')
    NODE_MINOR=$(echo "$NODE_VER" | cut -d. -f2)
    if [ "$NODE_MAJOR" -ge 22 ] && [ "$NODE_MINOR" -ge 12 ]; then
        check_pass "Node.js $NODE_VER (>= 22.12 required)"
    else
        check_fail "Node.js $NODE_VER (>= 22.12 required)"
    fi
else
    check_fail "Node.js not installed"
fi

# npm
command -v npm &>/dev/null && check_pass "npm $(npm --version)" || check_fail "npm not installed"

# Git
command -v git &>/dev/null && check_pass "Git $(git --version | cut -d' ' -f3)" || check_fail "Git not installed"

# Docker
if command -v docker &>/dev/null; then
    check_pass "Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
    docker compose version &>/dev/null && check_pass "Docker Compose available" || check_fail "Docker Compose not available"
else
    check_fail "Docker not installed"
fi

# Ollama (native)
if command -v ollama &>/dev/null; then
    check_pass "Ollama installed (native)"
else
    check_warn "Ollama not installed"
fi

# OpenClaw
if command -v openclaw &>/dev/null; then
    OPENCLAW_VER=$(openclaw --version 2>/dev/null || echo "unknown")
    check_pass "OpenClaw $OPENCLAW_VER"
else
    check_fail "OpenClaw not installed (npm install -g openclaw@latest)"
fi

# ==========================================
# 2. CONFIGURATION FILES
# ==========================================
echo ""
echo -e "${BLUE}[2/8] Validating Configuration Files${NC}"

# JSON validation
for f in openclaw/openclaw.json openclaw/config/mcporter.json; do
    if [ -f "$f" ]; then
        node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" 2>/dev/null \
            && check_pass "$f — valid JSON" \
            || check_fail "$f — invalid JSON"
    else
        check_fail "$f — file missing"
    fi
done

# OpenClaw home config
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
if [ -f "$OPENCLAW_CONFIG" ]; then
    openclaw config validate 2>/dev/null \
        && check_pass "OpenClaw config valid ($(openclaw config file 2>/dev/null))" \
        || check_fail "OpenClaw config invalid (run: openclaw doctor --fix)"
else
    check_fail "OpenClaw home config missing ($OPENCLAW_CONFIG)"
fi

# YAML validation (requires js-yaml)
if node -e "require('./node_modules/js-yaml')" 2>/dev/null; then
    for f in docker-compose.yml nemoclaw/nemoclaw.config.yml \
             nemoclaw/policies/network-egress.yml \
             nemoclaw/policies/agent-permissions.yml \
             nemoclaw/policies/hitl-rules.yml \
             kubernetes/namespace.yml \
             kubernetes/master-agent-deployment.yml \
             kubernetes/postgres-statefulset.yml \
             kubernetes/redis-deployment.yml \
             kubernetes/ollama-deployment.yml \
             kubernetes/network-policies.yml \
             kubernetes/gpu-time-slicing-config.yml; do
        if [ -f "$f" ]; then
            node -e "require('./node_modules/js-yaml').loadAll(require('fs').readFileSync('$f','utf8'), ()=>{})" 2>/dev/null \
                && check_pass "$f — valid YAML" \
                || check_fail "$f — invalid YAML"
        else
            check_fail "$f — file missing"
        fi
    done
else
    check_warn "js-yaml not installed, skipping YAML validation"
fi

# SQL validation
if [ -f "memory/init.sql" ]; then
    SQL_TABLES=$(grep -c "CREATE TABLE" memory/init.sql)
    SQL_FUNCS=$(grep -c "CREATE.*FUNCTION" memory/init.sql)
    check_pass "memory/init.sql — $SQL_TABLES tables, $SQL_FUNCS functions"
else
    check_fail "memory/init.sql — file missing"
fi

# ==========================================
# 3. AGENT PROFILES
# ==========================================
echo ""
echo -e "${BLUE}[3/8] Validating Agent Profiles${NC}"

for agent in architect coder devops qa researcher tool-maker; do
    if [ -f "agents/$agent/SOUL.md" ]; then
        SIZE=$(wc -c < "agents/$agent/SOUL.md")
        if [ "$SIZE" -gt 100 ]; then
            check_pass "agents/$agent/SOUL.md — ${SIZE} bytes"
        else
            check_warn "agents/$agent/SOUL.md — suspiciously small (${SIZE} bytes)"
        fi
    else
        check_fail "agents/$agent/SOUL.md — missing"
    fi
done

# OpenClaw identity files
for f in openclaw/SOUL.md openclaw/USER.md openclaw/AGENTS.md openclaw/HEARTBEAT.md; do
    [ -f "$f" ] && check_pass "$f — exists" || check_fail "$f — missing"
done

# Registered agents in OpenClaw
AGENT_COUNT=$(openclaw agents list 2>/dev/null | grep -c "^- " || echo "0")
if [ "$AGENT_COUNT" -ge 7 ]; then
    check_pass "OpenClaw agents registered: $AGENT_COUNT"
else
    check_warn "OpenClaw agents registered: $AGENT_COUNT (expected >= 7)"
fi

# ==========================================
# 4. ENVIRONMENT
# ==========================================
echo ""
echo -e "${BLUE}[4/8] Validating Environment${NC}"

if [ -f ".env" ]; then
    check_pass ".env file exists"

    # Check for placeholder values
    source .env 2>/dev/null
    [ "${GROQ_API_KEY:-}" != "gsk_your_groq_api_key_here" ] && [ -n "${GROQ_API_KEY:-}" ] \
        && check_pass "GROQ_API_KEY is set" \
        || check_warn "GROQ_API_KEY is placeholder or empty"

    [ "${GEMINI_API_KEY:-}" != "your_gemini_api_key_here" ] && [ -n "${GEMINI_API_KEY:-}" ] \
        && check_pass "GEMINI_API_KEY is set" \
        || check_warn "GEMINI_API_KEY is placeholder or empty"

    [ "${TELEGRAM_BOT_TOKEN:-}" != "your_telegram_bot_token_here" ] && [ -n "${TELEGRAM_BOT_TOKEN:-}" ] \
        && check_pass "TELEGRAM_BOT_TOKEN is set" \
        || check_warn "TELEGRAM_BOT_TOKEN not configured yet"

    [ "${OPENCLAW_GATEWAY_TOKEN:-}" != "generate_a_secure_random_token_here" ] && [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ] \
        && check_pass "OPENCLAW_GATEWAY_TOKEN is set" \
        || check_warn "OPENCLAW_GATEWAY_TOKEN is placeholder"
else
    check_fail ".env file missing (cp .env.example .env)"
fi

[ -f ".env.example" ] && check_pass ".env.example exists" || check_fail ".env.example missing"

# Check .env.example doesn't contain real keys
if [ -f ".env.example" ]; then
    # Check for real Groq keys (64+ chars after gsk_) vs placeholders
    if grep -qP "gsk_[A-Za-z0-9]{40,}" .env.example 2>/dev/null; then
        check_fail ".env.example contains real API keys! Remove them immediately."
    else
        check_pass ".env.example has no real API keys (safe to commit)"
    fi
fi

# ==========================================
# 5. DOCKER SERVICES (PostgreSQL only)
# ==========================================
echo ""
echo -e "${BLUE}[5/8] Checking Docker Services${NC}"

if command -v docker &>/dev/null && docker info &>/dev/null; then
    check_pass "Docker engine is running"
    if docker compose ps 2>/dev/null | grep -q "wow-ai-postgres"; then
        PG_STATUS=$(docker compose ps --format '{{.Status}}' 2>/dev/null | head -1)
        check_pass "PostgreSQL container: $PG_STATUS"
    else
        check_warn "PostgreSQL container not running (run: docker compose up -d postgres)"
    fi
else
    check_warn "Docker not running — cannot check PostgreSQL container"
fi

# ==========================================
# 6. NATIVE SERVICES (Redis/Memurai + Ollama)
# ==========================================
echo ""
echo -e "${BLUE}[6/8] Checking Native Services${NC}"

# Redis/Memurai
if powershell.exe -Command "(Get-Service -Name 'Memurai' -ErrorAction SilentlyContinue).Status" 2>/dev/null | grep -qi "running"; then
    check_pass "Memurai (Redis) service: Running"
elif powershell.exe -Command "(New-Object System.Net.Sockets.TcpClient).Connect('127.0.0.1', 6379)" 2>/dev/null; then
    check_pass "Redis port 6379 is open"
else
    check_warn "Redis/Memurai not detected on port 6379"
fi

# Ollama
if curl -sf http://localhost:11434/api/tags &>/dev/null; then
    check_pass "Ollama API is responding (native)"
    MODELS=$(curl -sf http://localhost:11434/api/tags | node -e "
        let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
            try { console.log(JSON.parse(d).models.map(m=>m.name).join(', ')||'none'); }
            catch(e) { console.log('parse error'); }
        })
    " 2>/dev/null)
    echo "       Models: $MODELS"
    # Check required models
    echo "$MODELS" | grep -q "nomic-embed-text" && check_pass "Embedding model: nomic-embed-text" || check_warn "Missing: nomic-embed-text (run: ollama pull nomic-embed-text)"
    echo "$MODELS" | grep -q "qwen2.5-coder" && check_pass "Coding model: qwen2.5-coder" || check_warn "Missing: qwen2.5-coder (run: ollama pull qwen2.5-coder:7b)"
else
    check_warn "Ollama not responding on localhost:11434 (run: ollama serve)"
fi

# ==========================================
# 7. CONNECTIVITY TESTS
# ==========================================
echo ""
echo -e "${BLUE}[7/8] Testing Connectivity${NC}"

# PostgreSQL
if command -v docker &>/dev/null && docker compose ps 2>/dev/null | grep -q "wow-ai-postgres"; then
    docker compose exec -T postgres pg_isready -U wow_ai_admin -d wow_ai 2>/dev/null \
        && check_pass "PostgreSQL is accepting connections" \
        || check_fail "PostgreSQL is not accepting connections"

    # Verify schema
    TABLE_COUNT=$(docker compose exec -T postgres psql -U wow_ai_admin -d wow_ai -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'" 2>/dev/null | tr -d ' ')
    if [ "$TABLE_COUNT" -ge 7 ]; then
        check_pass "PostgreSQL schema: $TABLE_COUNT tables initialized"
    else
        check_warn "PostgreSQL schema: only $TABLE_COUNT tables (expected 7)"
    fi

    # Verify pgvector
    docker compose exec -T postgres psql -U wow_ai_admin -d wow_ai -t -c "SELECT extname FROM pg_extension WHERE extname='vector'" 2>/dev/null | grep -q "vector" \
        && check_pass "pgvector extension loaded" \
        || check_warn "pgvector extension not found"
else
    check_warn "PostgreSQL not running — skipping connectivity test"
fi

# Groq API
source .env 2>/dev/null
if [ -n "${GROQ_API_KEY:-}" ] && [ "${GROQ_API_KEY:-}" != "gsk_your_groq_api_key_here" ]; then
    HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        "https://api.groq.com/openai/v1/models" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        check_pass "Groq API key is valid (HTTP 200)"
    else
        check_warn "Groq API returned HTTP $HTTP_CODE"
    fi
else
    check_warn "Groq API key not set — skipping"
fi

# Gemini API
if [ -n "${GEMINI_API_KEY:-}" ] && [ "${GEMINI_API_KEY:-}" != "your_gemini_api_key_here" ]; then
    HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
        "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        check_pass "Gemini API key is valid (HTTP 200)"
    else
        check_warn "Gemini API returned HTTP $HTTP_CODE"
    fi
else
    check_warn "Gemini API key not set — skipping"
fi

# Telegram Bot
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ "${TELEGRAM_BOT_TOKEN:-}" != "your_telegram_bot_token_here" ]; then
    BOT_INFO=$(curl -sf "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe" 2>/dev/null)
    if echo "$BOT_INFO" | grep -q '"ok":true'; then
        BOT_USER=$(echo "$BOT_INFO" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).result.username))" 2>/dev/null)
        check_pass "Telegram bot alive: @$BOT_USER"
    else
        check_warn "Telegram bot token invalid"
    fi
else
    check_warn "Telegram bot token not set — skipping"
fi

# ==========================================
# 8. GIT STATUS
# ==========================================
echo ""
echo -e "${BLUE}[8/8] Git Status${NC}"

if [ -d ".git" ]; then
    check_pass "Git repository initialized"
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    UNSTAGED=$(git status --porcelain 2>/dev/null | wc -l)
    echo "       Branch: $BRANCH, Uncommitted files: $UNSTAGED"
else
    check_warn "Not a git repository"
fi

# ==========================================
# SUMMARY
# ==========================================
echo ""
echo "========================================"
echo "  Validation Summary"
echo "========================================"
echo -e "  ${GREEN}PASS: $PASS${NC}"
echo -e "  ${RED}FAIL: $FAIL${NC}"
echo -e "  ${YELLOW}WARN: $WARN${NC}"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "  ${GREEN}All critical checks passed!${NC}"
    exit 0
else
    echo -e "  ${RED}$FAIL critical check(s) failed. Fix before running.${NC}"
    exit 1
fi
