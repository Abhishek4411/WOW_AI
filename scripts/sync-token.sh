#!/usr/bin/env bash
# =============================================================================
# WOW AI — Gateway Token Auto-Healer
# =============================================================================
# Fully automatic. Detects and fixes ALL token problems without user input.
#
# Problems fixed:
#  1. Placeholder token in runtime config (__OPENCLAW_GATEWAY_TOKEN__ etc)
#  2. Token mismatch between .env and runtime JSON config
#  3. Missing token in either location
#  4. Stale browser device tokens (device_token_mismatch error)
#  5. Broken gateway config (via openclaw doctor --fix)
#
# Called automatically by start.sh on every startup.
# =============================================================================

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

log_info()  { echo -e "${BLUE}[TOKEN]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[TOKEN]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[TOKEN]${NC} $1"; }
log_error() { echo -e "${RED}[TOKEN]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"

# ─── is_placeholder: returns 0 (true) if token is fake/empty/template ─────────
is_placeholder() {
    local t="${1:-}"
    [[ -z "$t" ]] || [[ "$t" == "__"* ]] || [[ "$t" == *"__" ]] || \
    [[ "$t" == "null" ]] || [[ "$t" == "undefined" ]] || \
    [[ "$t" == "your-"* ]] || [[ "$t" == "change-me"* ]] || \
    [[ ${#t} -lt 16 ]]
}

# ─── Generate a real 64-char hex token ─────────────────────────────────────────
new_token() {
    node -e "process.stdout.write(require('crypto').randomBytes(32).toString('hex'))"
}

# ─── Read token directly from JSON (not via `openclaw config get` which ────────
# reads env vars first and can return placeholder values from the shell env)
read_json_token() {
    [ ! -f "$OPENCLAW_CONFIG" ] && echo "" && return
    node -e "
      try {
        const c = JSON.parse(require('fs').readFileSync('$OPENCLAW_CONFIG','utf8'));
        process.stdout.write(c?.gateway?.auth?.token || '');
      } catch(e) { process.stdout.write(''); }
    " 2>/dev/null || echo ""
}

# ─── Write token to both gateway.auth.token AND gateway.remote.token ──────────
set_runtime_token() {
    local t="$1"
    openclaw config set gateway.auth.token   "$t" 2>&1 | grep -v "^Config overwrite" | grep -v "^$" || true
    openclaw config set gateway.remote.token "$t" 2>&1 | grep -v "^Config overwrite" | grep -v "^$" || true
}

# ─── Write OPENCLAW_GATEWAY_TOKEN to .env ──────────────────────────────────────
set_env_token() {
    local t="$1"
    if grep -q "^OPENCLAW_GATEWAY_TOKEN=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^OPENCLAW_GATEWAY_TOKEN=.*|OPENCLAW_GATEWAY_TOKEN=$t|" "$ENV_FILE" 2>/dev/null || \
        sed -i '' "s|^OPENCLAW_GATEWAY_TOKEN=.*|OPENCLAW_GATEWAY_TOKEN=$t|" "$ENV_FILE" 2>/dev/null || true
    else
        echo "OPENCLAW_GATEWAY_TOKEN=$t" >> "$ENV_FILE"
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
log_info "Starting token health check..."

# ─── Pre-check: ensure openclaw CLI and node exist ────────────────────────────
if ! command -v openclaw &>/dev/null; then log_error "openclaw not found"; exit 1; fi
if ! command -v node     &>/dev/null; then log_error "node not found";     exit 1; fi

# ─── Ensure .env exists ───────────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    [ -f "$PROJECT_ROOT/.env.example" ] && cp "$PROJECT_ROOT/.env.example" "$ENV_FILE" || touch "$ENV_FILE"
fi

# ─── Ensure runtime config exists ─────────────────────────────────────────────
if [ ! -f "$OPENCLAW_CONFIG" ]; then
    log_warn "Runtime config missing — running openclaw gateway install..."
    openclaw gateway install 2>/dev/null || true
fi

# ─── Read current values from JSON (bypasses env var precedence trap) ─────────
JSON_TOKEN=$(read_json_token)
ENV_TOKEN=$(grep "^OPENCLAW_GATEWAY_TOKEN=" "$ENV_FILE" 2>/dev/null \
            | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d '[:space:]' || echo "")

JSON_PH=$(is_placeholder "$JSON_TOKEN" && echo yes || echo no)
ENV_PH=$(is_placeholder  "$ENV_TOKEN"  && echo yes || echo no)

FINAL_TOKEN=""
CHANGED=no

if   [ "$JSON_PH" = "no"  ] && [ "$ENV_PH" = "no"  ] && [ "$JSON_TOKEN" = "$ENV_TOKEN" ]; then
    # ✅ Perfect — both real, both match
    FINAL_TOKEN="$JSON_TOKEN"
    log_ok "Tokens healthy: ${FINAL_TOKEN:0:8}... (no changes needed)"

elif [ "$JSON_PH" = "no"  ] && [ "$ENV_PH" = "no"  ] && [ "$JSON_TOKEN" != "$ENV_TOKEN" ]; then
    # Both real but different — runtime JSON wins (it's what the gateway actually uses)
    FINAL_TOKEN="$JSON_TOKEN"
    set_env_token "$FINAL_TOKEN"
    log_warn "Mismatch fixed: .env updated to match runtime config (${FINAL_TOKEN:0:8}...)"
    CHANGED=yes

elif [ "$JSON_PH" = "yes" ] && [ "$ENV_PH" = "no"  ]; then
    # Runtime config has placeholder (never properly initialized), .env has real token
    # DO NOT copy placeholder into .env — sync the other way: runtime ← .env
    FINAL_TOKEN="$ENV_TOKEN"
    set_runtime_token "$FINAL_TOKEN"
    log_warn "Runtime config had placeholder — set runtime ← .env token (${FINAL_TOKEN:0:8}...)"
    CHANGED=yes

elif [ "$JSON_PH" = "no"  ] && [ "$ENV_PH" = "yes" ]; then
    # .env has placeholder/empty, runtime has real token — sync .env ← runtime
    FINAL_TOKEN="$JSON_TOKEN"
    set_env_token "$FINAL_TOKEN"
    log_warn ".env had placeholder — set .env ← runtime token (${FINAL_TOKEN:0:8}...)"
    CHANGED=yes

else
    # Both are placeholders/missing — generate a fresh token and set everywhere
    log_warn "No valid token found anywhere — generating new token..."
    FINAL_TOKEN=$(new_token)
    set_runtime_token "$FINAL_TOKEN"
    set_env_token     "$FINAL_TOKEN"
    log_ok "New token generated and set: ${FINAL_TOKEN:0:8}..."
    CHANGED=yes
fi

# ─── If we changed anything, run openclaw doctor --fix to heal config ─────────
if [ "$CHANGED" = "yes" ]; then
    log_info "Running openclaw doctor --fix to heal any related config issues..."
    openclaw doctor --fix 2>&1 | grep -v "^$" | grep -v "Config overwrite" | head -10 || true
fi

# ─── Reissue device tokens so browser can re-authenticate cleanly ─────────────
# (Clears stale device_token_mismatch state in the gateway)
openclaw device reissue 2>/dev/null && log_ok "Device tokens reissued" || \
openclaw device rotate  2>/dev/null && log_ok "Device tokens rotated"  || \
true  # Not all versions support this command — the tokenized URL handles it anyway

log_ok "Token check done. Active: ${FINAL_TOKEN:0:8}..."
exit 0
