# PROJECT NOTES — WOW AI Orchestrator

> **Purpose**: This file is the handoff document. Any AI assistant, IDE copilot, or
> developer reading this file should understand exactly where the project stands,
> what has been done, what remains, and how to continue without re-reading every file.
>
> **Rule**: Every significant action taken on this project MUST be logged here.

---

## Project Overview

**WOW AI** is an autonomous multi-agent orchestration platform. A single Master Manager
agent receives user requests (via Telegram), decomposes them into tasks, and delegates
to specialist sub-agents (architect, coder, devops, qa, researcher, tool-maker) via
`sessions_spawn` with `runtime: "subagent"`. All execution is sandboxed via NVIDIA NemoClaw.
**ALL agents use `openai/gpt-4.1-mini`** as primary, with Gemini/Groq as free fallbacks.
GitHub: https://github.com/Abhishek4411/WOW_AI

---

## Current Status

### Phase: FRESH RESTART — CLEAN SLATE, ALL SYSTEMS OPERATIONAL

**Date**: 2026-03-21 (Session 7 — Full Reset + Fresh Restart)

### Gateway State: READY (port 3000, Telegram polling active, ACPX runtime registered)

**FRESH RESTART (Session 7)**: Complete reset performed — all runtime state cleared while preserving code. PostgreSQL volume destroyed & recreated (7 tables, 0 rows), Redis FLUSHALL'd, all 12 OpenClaw agent sessions/memory/workspaces wiped, Telegram update queue flushed, device pairings reset, temp logs cleared. Validation: 54 PASS | 0 FAIL | 0 WARN.

**A2A DELEGATION** (Session 8 fix): Master-manager delegates via `sessions_spawn` with `runtime: "subagent"` (NOT `"acp"` — WebSocket handshake bug on Windows v2026.3.13). Pipeline: User → Telegram → master-manager (gpt-4.1-mini) → sessions_spawn(subagent) → sub-agent (gpt-4.1-mini) → file output. Sub-agents don't read SOUL.md (bug #24852), so all instructions must be in the task text.

**Model assignments** (Session 8 upgrade — ALL agents on gpt-4.1-mini):
- **ALL agents → `openai/gpt-4.1-mini`** ($0.20/$0.80 per 1M tokens)
- master-manager, architect, coder, qa, researcher, devops, tool-maker — all use mini
- Reason: nano produced poor quality output; mini is still cheap enough for $10 budget
- Fallbacks: `google/gemini-2.5-flash` → `groq/llama-3.3-70b-versatile`
- Estimated cost per project build: ~$0.05-0.15 ($10 credit lasts ~65-200 projects)
- **NOTE**: `gpt-4.1` ($2.00/$8.00) is registered in config for future use on complex projects

**Output convention**: All agent-built projects go in `wow_ai/try_out_demos/{project-name}/`.

**To start**: Run `./scripts/start.sh`
**OpenAI API key is set in**:
1. `.env` → `OPENAI_API_KEY=sk-proj-...`
2. `~/.openclaw/gateway.cmd` → `set "OPENAI_API_KEY=sk-proj-..."`

**Web Dashboard access**:
- Run `openclaw dashboard --no-open` to get a fresh tokenized URL
- Or use gateway token from `~/.openclaw/openclaw.json` → `gateway.auth.token`
- After any reset, browser localStorage has stale device tokens — use incognito or the tokenized URL
- If "too many failed auth attempts" appears, restart the gateway to clear in-memory rate limit

**Post-reset pairing**:
- Telegram pairing must be re-approved after reset: `openclaw pairing approve telegram <CODE>`
- The bot will prompt the pairing code in Telegram when a user first messages

### Validation Results (Session 2 — FINAL)

```
54 PASS | 0 FAIL | 0 WARN — ALL CRITICAL CHECKS PASSED
```

| Check                                  | Result  | Details                                          |
|----------------------------------------|---------|--------------------------------------------------|
| Node.js v22.22.1                       | PASS    | >= 22.12 required                                |
| npm 10.9.4                             | PASS    |                                                  |
| Git 2.53.0                             | PASS    |                                                  |
| Docker 29.2.1                          | PASS    | Docker Compose available                         |
| Ollama 0.18.1 (native)                 | PASS    |                                                  |
| OpenClaw v2026.3.13                    | PASS    |                                                  |
| JSON configs (2 project files)         | PASS    | openclaw.json, mcporter.json valid               |
| OpenClaw home config                   | PASS    | ~/.openclaw/openclaw.json validated               |
| YAML configs (12 files)                | PASS    | All K8s, Docker, NemoClaw YAML valid             |
| SQL schema                             | PASS    | 7 tables, 2 functions                            |
| Agent profiles (6 specialists)         | PASS    | architect, coder, devops, qa, researcher, tool-maker |
| OpenClaw identity files (4)            | PASS    | SOUL.md, USER.md, AGENTS.md, HEARTBEAT.md       |
| OpenClaw agents registered             | PASS    | 8 agents (main + master-manager + 6 specialists) |
| .env file                              | PASS    | All keys set with real values                    |
| .env.example security                  | PASS    | No real API keys (safe to commit)                |
| Docker engine running                  | PASS    |                                                  |
| PostgreSQL container (healthy)         | PASS    | pgvector/pgvector:pg16 via Docker                |
| Memurai (Redis) service                | PASS    | Native Windows service on port 6379              |
| Ollama API responding                  | PASS    | Native on port 11434                             |
| Ollama models installed                | PASS    | qwen2.5-coder:7b, llama3.2:3b, nomic-embed-text |
| PostgreSQL connectivity                | PASS    | Accepting connections                            |
| PostgreSQL schema                      | PASS    | 7 tables initialized                            |
| pgvector extension                     | PASS    | v0.8.2 loaded                                   |
| Groq API key                           | PASS    | HTTP 200                                         |
| Gemini API key                         | PASS    | HTTP 200                                         |
| Telegram bot                           | PASS    | @ohboy441clawbot alive                           |
| Git repository                         | PASS    | Initialized on master branch                    |
| **OpenClaw Gateway**                   | PASS    | Started, Telegram polling, heartbeat active      |

### Service Architecture (Working)

| Service     | How It Runs              | Port  | Notes                                |
|-------------|--------------------------|-------|--------------------------------------|
| PostgreSQL  | Docker (pgvector:pg16)   | 5432  | With pgvector, uuid-ossp             |
| Redis       | Native Memurai (Windows) | 6379  | Windows Redis-compatible service     |
| Ollama      | Native binary            | 11434 | 3 models installed (7GB total)       |
| OpenClaw    | Native npm global        | 3000  | Gateway + Telegram polling           |

### What Has Been Completed

| # | Task                                    | Status    | Files Created/Modified                    |
|---|----------------------------------------|-----------|-------------------------------------------|
| 1 | Full architecture blueprint             | DONE      | `BLUEPRINT.md`                            |
| 2 | README with quick start guide           | DONE      | `README.md`                               |
| 3 | Environment configuration template      | DONE      | `.env.example`                            |
| 4 | OpenClaw gateway config (v2026.3.13)    | DONE      | `openclaw/openclaw.json` (reference)      |
| 5 | OpenClaw home config (runtime)          | DONE      | `~/.openclaw/openclaw.json`               |
| 6 | Master Manager identity (SOUL.md)       | DONE      | `openclaw/SOUL.md`                        |
| 7 | Admin profile with DND/HITL rules       | DONE      | `openclaw/USER.md`                        |
| 8 | Sub-agent communication protocol        | DONE      | `openclaw/AGENTS.md`                      |
| 9 | 24/7 heartbeat loop definition          | DONE      | `openclaw/HEARTBEAT.md`                   |
|10 | MCP server configs (7 servers)          | DONE      | `openclaw/config/mcporter.json`           |
|11 | Architect agent profile                 | DONE      | `agents/architect/SOUL.md`                |
|12 | Coder agent profile                     | DONE      | `agents/coder/SOUL.md`                    |
|13 | DevOps agent profile                    | DONE      | `agents/devops/SOUL.md`                   |
|14 | QA agent profile                        | DONE      | `agents/qa/SOUL.md`                       |
|15 | Researcher agent profile                | DONE      | `agents/researcher/SOUL.md`               |
|16 | Tool Maker agent profile                | DONE      | `agents/tool-maker/SOUL.md`               |
|17 | NemoClaw main config                    | DONE      | `nemoclaw/nemoclaw.config.yml`            |
|18 | Network egress policies (per-agent)     | DONE      | `nemoclaw/policies/network-egress.yml`    |
|19 | Agent permission restrictions           | DONE      | `nemoclaw/policies/agent-permissions.yml` |
|20 | HITL approval rules                     | DONE      | `nemoclaw/policies/hitl-rules.yml`        |
|21 | Docker Compose (Postgres only now)      | DONE      | `docker-compose.yml`                      |
|22 | PostgreSQL + pgvector schema (7 tables) | DONE      | `memory/init.sql`                         |
|23 | K8s namespace                           | DONE      | `kubernetes/namespace.yml`                |
|24 | K8s master agent deployment             | DONE      | `kubernetes/master-agent-deployment.yml`  |
|25 | K8s PostgreSQL StatefulSet              | DONE      | `kubernetes/postgres-statefulset.yml`     |
|26 | K8s Redis deployment                    | DONE      | `kubernetes/redis-deployment.yml`         |
|27 | K8s Ollama deployment                   | DONE      | `kubernetes/ollama-deployment.yml`        |
|28 | K8s network policies                    | DONE      | `kubernetes/network-policies.yml`         |
|29 | K8s GPU time-slicing config             | DONE      | `kubernetes/gpu-time-slicing-config.yml`  |
|30 | Setup script (one-click install)        | DONE      | `scripts/setup.sh`                        |
|31 | Model installer (3 hardware profiles)   | DONE      | `scripts/install-models.sh`               |
|32 | Start script (updated for native)       | DONE      | `scripts/start.sh`                        |
|33 | Validation script (54 checks)           | DONE      | `scripts/validate.sh`                     |
|34 | Git ignore rules                        | DONE      | `.gitignore`                              |
|35 | This project notes file                 | DONE      | `PROJECT_NOTES.md`                        |
|36 | Installed WSL2 + VM Platform features   | DONE      | Windows features enabled                  |
|37 | Docker Desktop v4.65.0 working          | DONE      | Engine running, pulls working             |
|38 | PostgreSQL Docker container running      | DONE      | Healthy, schema initialized               |
|39 | Ollama native with 3 models             | DONE      | qwen2.5-coder:7b, llama3.2:3b, nomic-embed-text |
|40 | OpenClaw config validated + agents registered | DONE | 8 agents in ~/.openclaw/openclaw.json    |
|41 | OpenClaw gateway started                | DONE      | Telegram polling, heartbeat active         |
|42 | Telegram bot created                    | DONE      | @ohboy441clawbot, token in .env            |
|43 | All API keys validated                  | DONE      | Groq HTTP 200, Gemini HTTP 200            |
|44 | Secure credentials generated            | DONE      | Postgres pw, Redis pw, gateway token       |
|45 | Fixed model format (provider/model)     | DONE      | `groq/llama-3.3-70b-versatile` not `groq:...` |
|46 | Added model fallbacks                   | DONE      | gemini → ollama → openai → groq           |
|47 | Fixed gateway auth token                | DONE      | `gateway.remote.token` matches `gateway.auth.token` |
|48 | Configured ACP default agent            | DONE      | `acp.defaultAgent: "coder"` for sub-agent spawning |
|49 | Added OLLAMA_API_KEY to .env            | DONE      | Dummy value "ollama" for OpenClaw provider discovery |
|50 | Master Manager agent test               | DONE      | Responded "Yes, I'm working." via Gemini fallback |
|51 | Potato Shop website built by agent      | DONE      | 8 files in `potato-shop/` built autonomously |
|52 | Gateway stopped for fresh start         | DONE      | All node processes killed, service uninstalled |
|53 | **Session 4: Switched primary model to Gemini** | DONE | Groq 12K TPM cannot handle 28K system prompt |
|54 | Fixed gateway token mismatch            | DONE      | .env OPENCLAW_GATEWAY_TOKEN must match config's gateway.auth.token |
|55 | Added API keys to gateway.cmd           | DONE      | Gateway service needs GROQ/GEMINI/OLLAMA_API_KEY env vars |
|56 | Patched OpenClaw Ollama context (131K→8K) | DONE    | Modified auth-profiles-*.js to cap num_ctx via OPENCLAW_OLLAMA_NUM_CTX |
|57 | Discovered Groq 28K TPM issue           | DONE      | Master-manager system prompt = 28K tokens > Groq's 12K TPM limit |
|58 | Discovered Ollama 131K context default  | DONE      | OpenClaw passes model's full context_length to Ollama, causing OOM |
|59 | GPU detected (GTX 1650 4GB VRAM)        | DONE      | Ollama uses GPU for model weights offloading |
|60 | Updated reference openclaw.json         | DONE      | Gemini primary, Groq+Ollama fallbacks |
|61 | Updated .env.example with OPENCLAW_OLLAMA_NUM_CTX | DONE | Documents context cap for 8GB RAM systems |
|62 | **Session 5: Added OpenAI as last-resort fallback** | DONE | gpt-4.1-nano (cheapest), gpt-4.1-mini in `models.providers.openai` |
|63 | Tested Ollama 4K variants (blocked by OpenClaw 16K min) | DONE | Reverted to original models with contextWindow: 16384 |
|64 | Restructured fallback chain             | DONE      | Gemini → Ollama 4K → OpenAI nano → Groq (optimal order) |
|65 | Added OPENAI_API_KEY to .env + gateway.cmd | DONE   | Placeholder — user must paste real key |
|66 | **OpenAI API key pasted + verified working** | DONE   | gpt-4.1-nano responded via fallback chain, cost $0.001 per call |
|67 | Changed OpenAI API type to openai-completions | DONE   | `openai-responses` returned empty; `openai-completions` works |
|68 | Updated reference openclaw.json with OpenAI | DONE  | Fallback: Ollama → OpenAI mini → Groq |
|69 | **Switched OpenAI fallback to gpt-4.1-mini** | DONE | gpt-4.1-nano can't handle 28K master-manager prompt (returns empty). gpt-4.1-mini works perfectly ($0.40/1M input, still ultra-cheap) |
|70 | **Master Manager responded via gpt-4.1-mini** | DONE | "I am the WOW AI Master Manager" — confirmed identity and agent list |
|71 | **Interview demo: Finance Dashboard built** | DONE | Master-manager autonomously created `demo-finance-dashboard.html` — dark glassmorphism, Chart.js, 4 widgets, responsive |
|72 | **NexaFlow Command Center built** | DONE | Enterprise-grade CEO dashboard with 6 KPIs, 4 charts, live feed, AI insights — saved to `demos/nexaflow-dashboard/` |
|73 | **Delivery issue: agent outputs code as text** | KNOWN | gpt-4.1-mini sometimes outputs HTML as Telegram text instead of writing files. Workaround: manually save output. Better prompting with explicit "write to file" instruction helps. |
|66 | Updated .env.example with OpenAI section | DONE     | Documents pricing, strategy, key setup |
|74 | **Session 6: ACPX plugin enabled** | DONE | `openclaw plugins enable acpx` — registers ACP runtime backend in gateway |
|75 | **ACPX command set to `node` (bypass .cmd bug)** | DONE | Windows .cmd wrapper causes ACPX to fail silently. Setting command to `"node"` bypasses the bug. |
|76 | `strictWindowsCmdWrapper` set to false | DONE | Required for ACPX on Windows |
|77 | Custom SOUL.md deployed to workspace | DONE | Copied `openclaw/SOUL.md` (4443 bytes, delegation instructions) to `~/.openclaw/workspace-master-manager/SOUL.md` |
|78 | ACPX plugin config (timeoutSeconds: 300) | DONE | `plugins.entries.acpx.config` with permissionMode: approve-all |
|79 | Agent IDs mapped in `~/.acpx/config.json` | DONE | All 7 agents (openclaw, coder, architect, qa, researcher, devops, tool-maker) mapped to `acp-wrapper.mjs` |
|80 | `acp-wrapper.mjs` created | DONE | Filters non-JSON stdout from `openclaw acp` (fixes ACPX JSON-RPC parser crash) |
|81 | `gateway.tools.allow` set | DONE | `["sessions_spawn", "sessions_send"]` — removes these from HTTP API deny list |
|82 | Chat Completions HTTP endpoint enabled | DONE | `gateway.http.endpoints.chatCompletions.enabled: true` |
|83 | Model split: master=gpt-4.1-mini, sub=gpt-4.1-nano | DONE | Later upgraded — nano produced poor quality |
|84 | **A2A test: Tic-Tac-Toe .exe built by coder** | DONE | Master-manager delegated via `sessions_spawn` → coder agent built tictactoe.exe (32 MB) autonomously |
|85 | `try_out_demos/` folder convention added | DONE | All agent-built projects go in `wow_ai/try_out_demos/{project-name}/` |
|86 | **Switched runtime: acp → subagent** | DONE | ACP WebSocket handshake times out on Windows (bug #50380, 3s timeout). `subagent` runs in-process, no WebSocket needed. |
|87 | Added `subagents.allowAgents` to master-manager | DONE | Required for `sessions_spawn` permission — without this, master-manager can't spawn any agents |
|88 | SOUL.md full rewrite — full autonomy mode | DONE | Added "NEVER ASK, JUST DO" rule, auto-chaining pipeline (architect→coder→qa), ONE start + ONE end message only |
|89 | **ALL agents upgraded to gpt-4.1-mini** | DONE | Session 8: nano produced poor quality code. All 7 agents now use mini ($0.20/$0.80 /1M). Nano only for truly trivial classification. |
|90 | E-commerce website built by agents | DONE | `try_out_demos/website/` — full frontend + backend built autonomously via agent pipeline |
|91 | Docs updated (README, BLUEPRINT, PROJECT_NOTES) | DONE | All docs reflect: mini for all agents, subagent runtime, current pipeline, GitHub URL |
|92 | **Pushed to GitHub** | DONE | Public repo: https://github.com/Abhishek4411/WOW_AI — 53 files, single contributor (Abhishek4411) |

---

## Interview Demo Prompts

### TIER 1: Enterprise "Command Center" Demo (THE INTERVIEW KILLER)

**Copy-paste this to your Telegram bot (@ohboy441clawbot):**

```
Build me an enterprise AI Operations Command Center as a single index.html file.

This is a CEO-level executive dashboard for a Series B startup called "NexaFlow AI" that monitors their entire AI SaaS platform in real-time.

REQUIREMENTS:

1. HEADER: Company logo text "NexaFlow AI" with a live clock showing IST timezone, a pulsing green "SYSTEMS OPERATIONAL" status badge, and a dark navy/purple gradient background.

2. KPI CARDS ROW (animated counters that count up on load):
   - Monthly Recurring Revenue: $2.4M (↑ 18% MoM)
   - Active Enterprise Clients: 847 (↑ 12%)
   - API Calls Today: 14.2M (real-time incrementing counter)
   - AI Model Accuracy: 97.3% (circular gauge)
   - Infrastructure Cost: $184K (↓ 8% - show in green)
   - Uptime: 99.97% (with a tiny sparkline)

3. MAIN CHARTS (use Chart.js CDN):
   - Revenue Growth: Area chart showing 12 months of MRR from $800K to $2.4M with gradient fill
   - Client Acquisition Funnel: Horizontal funnel chart (Leads 12K → Demos 3.2K → Trials 1.8K → Paid 847 → Enterprise 234)
   - API Usage Heatmap: 7x24 grid showing API call volume by day-of-week and hour (color intensity)
   - Revenue by Segment: Donut chart (Enterprise 58%, Mid-Market 27%, SMB 15%)

4. LIVE ACTIVITY FEED (right sidebar):
   - Auto-scrolling feed of fake real-time events like:
     "Accenture upgraded to Enterprise plan - $48K ARR"
     "Model v3.7 deployed to production - latency: 42ms"
     "Alert: API p99 latency spike in ap-south-1 (resolved)"
     "New SOC2 compliance audit passed"
     "Wipro signed 3-year contract - $720K TCV"
   - Each entry has a timestamp, colored icon (green=revenue, blue=deploy, yellow=alert, purple=compliance)
   - New events appear every 3 seconds with slide-in animation

5. BOTTOM SECTION - AI INSIGHTS PANEL:
   - A glassmorphism card titled "AI Strategic Insights (Auto-Generated)"
   - 3 rotating insight cards that cycle every 8 seconds:
     "Churn prediction: 3 enterprise accounts showing disengagement signals. Recommended action: trigger CSM outreach."
     "Revenue forecast: On track to hit $3.1M MRR by Q3 based on current pipeline velocity. Confidence: 89%."
     "Cost optimization: Switching ap-south-1 inference to spot instances could save $23K/month with <0.1% availability impact."

6. DESIGN:
   - Dark theme with navy (#0a0e27) background
   - Cards with glassmorphism (frosted glass, subtle borders)
   - Accent colors: electric blue (#00d4ff), purple (#7c3aed), green (#10b981), amber (#f59e0b)
   - Font: Inter from Google Fonts
   - Smooth fade-in animations staggered by 200ms per element
   - Fully responsive (looks good on mobile too)
   - CSS grid layout, no external frameworks except Chart.js and Inter font

7. INTERACTIVITY:
   - KPI counters animate from 0 to final value over 2 seconds on page load
   - API calls counter increments by random(50-200) every second
   - Hovering any chart shows detailed tooltips
   - Activity feed auto-scrolls but pauses on mouse hover
   - Clicking any KPI card gently pulses it

Deliver as a single self-contained index.html file. All CSS and JS inline. Only external dependencies: Chart.js CDN and Google Fonts Inter. Use realistic data that tells a coherent business story. This must look like a real $50M startup's internal dashboard, not a student project.
```

**Why this DESTROYS in interviews:**
- **Enterprise complexity**: 6 KPI cards + 4 charts + live feed + AI insights = production-grade dashboard
- **Real-time simulation**: Incrementing counters, auto-scrolling feed, rotating insights — it feels ALIVE
- **Business acumen**: MRR, churn prediction, unit economics — shows you understand SaaS metrics
- **Technical depth**: CSS grid, glassmorphism, Chart.js, animation orchestration, responsive design
- **AI-generated AI insights**: Meta-level flex — an AI agent generating fake AI insights for a fake AI company
- **Single prompt, zero intervention**: The entire thing built autonomously by your multi-agent system
- **Immediately demonstrable**: Open in any browser, works on phone too

**Estimated cost**: ~$0.01-0.02 (one gpt-4.1-mini call)

---

### TIER 0: Tic-Tac-Toe Game Build (MULTI-AGENT PROOF — Best for showing A2A)

**UPDATE (Session 6)**: A2A now works with gpt-4.1-mini too! The issue was the ACPX plugin not being configured, not the model. Both Gemini and gpt-4.1-mini can spawn sub-agents via `sessions_spawn`.

**Copy-paste to @ohboy441clawbot on Telegram:**

```
I need you to build a complete futuristic Tic-Tac-Toe game as a production-ready project. Delegate each part to the right specialist agent. Do NOT do this yourself — spawn sub-agents for each task.

PROJECT NAME: nexatactoe
DELIVER ALL FILES inside a "nexatactoe" folder.

TASK DECOMPOSITION — spawn these sub-agents:

1. ARCHITECT (spawn agent: architect):
   Design the project structure for a futuristic Tic-Tac-Toe game built with Python + Pygame. Output a DESIGN.md file with:
   - File structure (main.py, game_logic.py, ui.py, ai_engine.py, assets/, README.md)
   - Class diagram for GameBoard, AIPlayer, UIRenderer
   - AI difficulty levels: Easy (random), Medium (minimax depth 3), Hard (full minimax with alpha-beta pruning)

2. CODER (spawn agent: coder):
   After architect is done, build the full game with these files:
   - main.py — Entry point, game loop, window setup (800x600)
   - game_logic.py — GameBoard class with win detection, draw detection, move validation
   - ai_engine.py — AIPlayer with 3 difficulty levels using minimax + alpha-beta pruning
   - ui.py — UIRenderer with Pygame: neon grid lines, glowing X and O, particle effects on win, animated background gradient
   - requirements.txt — pygame dependency
   - build.bat — One-click script: pip install -r requirements.txt && python main.py
   Design: Dark theme (#0a0e27 background), neon cyan (#00d4ff) for X, neon purple (#7c3aed) for O, glowing grid lines, smooth animations, sound effects on move/win using pygame.mixer
   Features: Player vs AI mode, difficulty selector (Easy/Medium/Hard), score tracker, restart button, win celebration with particle explosion animation

3. QA (spawn agent: qa):
   After coder is done, review all Python files for:
   - Syntax errors and import issues
   - Game logic correctness (all 8 win conditions, draw detection)
   - AI minimax correctness (never loses on Hard)
   - Write a TEST_RESULTS.md with test cases and pass/fail status

4. RESEARCHER (spawn agent: researcher):
   Find the best practices for Pygame game distribution in 2026. Write a DISTRIBUTION.md covering:
   - How to create a Windows .exe using PyInstaller
   - How to create an installer using NSIS or Inno Setup
   - Exact PyInstaller command for single-file .exe with icon

Save every file to disk inside the "nexatactoe" folder. Do NOT output code as text — use your file writing tools. Create a README.md with setup instructions, screenshots description, and build commands.
```

**Why this prompt works for interviews:**
- **Forces 4 sub-agent spawns** (architect → coder → QA → researcher) — shows real A2A orchestration
- **Sequential dependency**: Coder waits for architect, QA waits for coder — shows task planning
- **Produces a real, runnable game** — not just an HTML page
- **AI algorithm showcase**: Minimax with alpha-beta pruning — shows technical depth
- **Distribution guide**: Shows production thinking (packaging as .exe)
- **Enterprise patterns**: Design doc, test results, distribution plan — not just code

**After the agent builds it, run:**
```bash
cd ~/.openclaw/workspace-master-manager/nexatactoe
pip install -r requirements.txt
python main.py
```

**To build .exe (after demo):**
```bash
pip install pyinstaller
pyinstaller --onefile --windowed --name NexaTacToe main.py
```

---

### TIER 2: Quick Smoke Test (30 seconds, ~$0.005)

```
Create a beautiful landing page for an AI startup called "WOW AI" with animated hero section, feature cards, and a contact form. Dark theme, modern design.
```

### TIER 3: Multi-Agent Deep Demo (If interviewer wants to see agent collaboration)

```
I need a complete project proposal document for building an AI-powered resume screening system:

1. RESEARCHER: Find the latest trends in AI recruitment tech (2024-2026)
2. ARCHITECT: Design the system architecture (microservices, ML pipeline, database schema)
3. CODER: Create a working prototype — a web form that accepts resume text and scores it against a job description using cosine similarity
4. QA: Write test cases for the scoring algorithm
5. TOOL-MAKER: Create a reusable MCP tool for resume parsing

Package everything into a single project folder with a README.
```

### What Remains (Next Phases)

| Phase | Task                                    | Effort    | Depends On           |
|-------|-----------------------------------------|-----------|----------------------|
| 2     | Master Manager functional testing       | DONE      | Responds via Telegram, delegates tasks |
| 3     | Sub-agent spawning and A2A testing      | DONE      | ACPX plugin working, sessions_spawn verified |
| 4     | MCP server integration testing          | 2-3 days  | Phase 3              |
| 5     | PostgreSQL memory backend integration   | 1-2 days  | Phase 4              |
| 6     | Heartbeat loop and auto-recovery        | 2-3 days  | Phase 5              |
| 7     | NemoClaw sandbox integration            | 2-3 days  | Phase 6 + NemoClaw GA |
| 8     | Kubernetes production deployment        | 3-5 days  | K8s cluster ready    |
| 9     | Next.js web GUI dashboard               | 5-7 days  | Phase 8              |
| 10    | Self-evolving agent loop (tool-maker)   | 3-5 days  | Phase 9              |

---

## How to Continue This Project

### For an AI Assistant / Copilot

1. **Read this file first** — it tells you where things stand
2. **Read `BLUEPRINT.md`** — it has the full architecture and 10-phase plan
3. **Check the "What Remains" table above** — Phase 2 is next
4. **After completing any task**, update the tables in this file
5. **Key config files to understand**:
   - `~/.openclaw/openclaw.json` — **runtime config** (managed by openclaw CLI)
   - `openclaw/openclaw.json` — reference config (version-controlled)
   - `openclaw/SOUL.md` — Master Manager behavior rules
   - `docker-compose.yml` — PostgreSQL container
   - `memory/init.sql` — database schema
6. **To validate**: run `./scripts/validate.sh` (expects 54 PASS, 0 FAIL)

### For a Developer

1. Ensure Docker Desktop is running
2. Run `ollama serve` if Ollama isn't started
3. Run `./scripts/start.sh` — starts PostgreSQL, checks Memurai + Ollama, validates config, launches gateway
4. To test: `openclaw agent --agent master-manager --message "Hello" --timeout 120`
5. Or message `@ohboy441clawbot` on Telegram
6. If all models fail, check:
   - Gemini daily quota: resets at midnight PT (~12:30 PM IST)
   - Groq: will NEVER work for master-manager (28K prompt > 12K TPM) — only works for sub-agents
   - Ollama OOM: use `-4k` model variants (`llama3.2:3b-4k`, `qwen2.5-coder:7b-4k`) with built-in 4096 context
   - OpenAI: ensure `OPENAI_API_KEY` is set in BOTH `.env` AND `~/.openclaw/gateway.cmd`
   - Gateway token: `OPENCLAW_GATEWAY_TOKEN` in `.env` must match `gateway.auth.token` in `~/.openclaw/openclaw.json`

### Critical Constraints

- **OpenClaw v2026.3.13** — config schema uses `agents.list` as ARRAY (not object), `model.primary` (not string)
- **NEVER copy `openclaw/openclaw.json` → `~/.openclaw/openclaw.json`** — the runtime config is managed by the CLI. Overwriting it breaks Telegram credentials and schema validation.
- **No `_comment`, `_workspace`, `_description` fields in openclaw.json** — OpenClaw rejects these. Fixed in Session 3.
- **No `adminId` field in Telegram channel config** — not a valid key in v2026.3.13. Admin control via DM pairing (`dmPolicy: "pairing"`).
- **Use `openclaw channels add --channel telegram --token TOKEN`** to set bot token — NOT `openclaw config set channels.telegram.botToken`
- **SOUL.md files live at `~/.openclaw/agents/{name}/agent/SOUL.md`** — not read from `./agents/*/SOUL.md` directly. Copy them after every `openclaw agents add`.
- **NemoClaw is ALPHA** (March 2026) — track GitHub for breaking changes
- **Gemini is PRIMARY model** — Groq free tier 12K TPM cannot handle master-manager's 28K token system prompt
- **Free API limits**: Gemini 15 req/min + 1M tokens/day; Groq 12K TPM + 30 req/min
- **OpenAI budget**: $10 credit (~3,300+ calls at gpt-4.1-nano pricing). Only used as last-resort fallback. Single API key across all agents.
- **Ollama on 8GB RAM**: Won't work through OpenClaw (16K minimum context → OOM/timeout). Works fine via direct API with 2K context. On 8GB RAM, Gemini+OpenAI are the working providers.
- **API keys in gateway.cmd** — the gateway Windows service doesn't inherit shell env vars; add GROQ/GEMINI/OLLAMA_API_KEY manually to `~/.openclaw/gateway.cmd`
- **Agent timeout: 3600s** (1 hour) — prevents stuck agents
- **PostgreSQL memory is REQUIRED** — without it, agents hit infinite context compaction loops
- **Redis/Memurai**: Memurai is a Windows Redis-compatible service (pre-installed, port 6379)
- **WSL2 features enabled** but system reboot needed for Docker to use WSL2 natively (currently uses Hyper-V)

---

## Decision Log

| Date       | Decision                                      | Reason                                         |
|------------|-----------------------------------------------|-------------------------------------------------|
| 2026-03-20 | Use OpenClaw over CrewAI/AutoGen              | Native channels (Telegram/WhatsApp), MCP, sub-agents, 247K stars |
| 2026-03-20 | Use NemoClaw over manual Docker sandboxing    | Kernel-level isolation, policy engine, Privacy Router |
| 2026-03-20 | PostgreSQL+pgvector over SQLite/Markdown      | Prevents context exhaustion, enables semantic search |
| 2026-03-20 | Ollama as primary, Groq/Gemini as fallback    | Zero cost local inference; cloud only when needed |
| 2026-03-20 | Qwen 2.5 Coder 7B as default coding model    | Best balance of quality vs VRAM for minimal profile |
| 2026-03-20 | Docker for PostgreSQL only, native for rest   | Memurai already installed, Ollama faster native, avoids WSL2 reboot |
| 2026-03-20 | OpenClaw agents via CLI (not config file)     | v2026.3.13 manages agents through `openclaw agents add`, not manual JSON |
| 2026-03-20 | Gateway service installed as Windows login item | Auto-starts on login via `openclaw gateway install` |
| 2026-03-20 | Use `openclaw channels add` for Telegram, not config file | `adminId` is not a valid config key; DM pairing handles admin auth |
| 2026-03-20 | Copy SOUL.md to `~/.openclaw/agents/{name}/agent/` after setup | OpenClaw reads agent identity from its managed dirs, not the project dir |
| 2026-03-20 | Removed `_comment`/`_workspace`/`_description` from reference config | OpenClaw v2026.3.13 strict schema rejects any unrecognized keys |
| 2026-03-20 | Model format: `provider/model` (slash), not `provider:model` (colon) | Colon format falls back to `anthropic/` provider which needs paid API key |
| 2026-03-20 | Groq as primary model with Gemini + Ollama fallbacks | Free tier: Groq ~30req/min, auto-fallback to Gemini when rate-limited |
| 2026-03-20 | Set `acp.defaultAgent: coder` for sub-agent spawning | Without this, master-manager can't delegate tasks to sub-agents |
| 2026-03-20 | `OLLAMA_API_KEY=ollama` required in .env | OpenClaw needs any value to discover local Ollama models as a provider |
| 2026-03-21 | **Gemini as primary model (not Groq)** | Master-manager system prompt is ~28K tokens; Groq free tier TPM limit is 12K. Groq will NEVER work as primary for master-manager. Groq works fine as fallback for sub-agents (smaller prompts). |
| 2026-03-21 | Gateway.cmd needs API key env vars | The gateway runs as a Windows Scheduled Task and doesn't inherit shell env vars. API keys must be explicitly set in `~/.openclaw/gateway.cmd`. |
| 2026-03-21 | Explicit Ollama provider config with contextWindow | OpenClaw auto-discovers models with their full context (131K for llama3.2:3b → 13.6 GiB needed). Fix: use `-4k` model variants with built-in 4096 context. Official config approach, no source patches. |
| 2026-03-21 | .env OPENCLAW_GATEWAY_TOKEN must match config | The `.env` file's `OPENCLAW_GATEWAY_TOKEN` can override the config file's `gateway.auth.token`. They must be identical or CLI→Gateway WebSocket auth fails. |
| 2026-03-21 | **OpenAI as last-resort paid fallback ($10 budget)** | Free providers (Gemini, Groq) have rate limits; Ollama OOM on 8GB. Single API key shared by all agents (most economical). Uses cheapest models: `gpt-4.1-nano` ($0.10/1M input) for simple tasks, `gpt-4.1-mini` ($0.40/1M input) for complex reasoning. |
| 2026-03-21 | **Ollama non-functional on 8GB RAM with OpenClaw** | OpenClaw enforces minimum 16000 context window. With 16K context, Ollama models timeout/OOM on 8GB RAM. Direct Ollama API works fine (2K context), but OpenClaw's minimum makes it unusable. On 8GB, rely on Gemini+OpenAI. |
| 2026-03-21 | **Fallback order: Gemini → Ollama → OpenAI → Groq** | Gemini is free+capable (primary). Ollama 4K is free+local (fast fallback). OpenAI is paid but reliable (when free options exhaust). Groq last because 12K TPM blocks master-manager. |
| 2026-03-21 | **OpenAI API type: openai-completions (not openai-responses)** | The Responses API returned empty replies. Switching to Chat Completions API (`openai-completions`) fixed it. |
| 2026-03-21 | **OpenAI verified: $0.001 per call** | Test call used 12,458 input tokens for $0.001. Budget of $10 allows ~10,000 fallback calls. Extremely economical. |
| 2026-03-21 | **gpt-4.1-mini over gpt-4.1-nano for global fallback** | gpt-4.1-nano (cheapest) returns empty replies for master-manager's 28K system prompt. gpt-4.1-mini ($0.40/1M input, 4x more but still ultra-cheap) handles it perfectly. ~$0.004/call for master-manager. Budget of $10 = ~2,500 master-manager calls. |
| 2026-03-21 | **Interview demo autonomously built** | Master-manager created a full finance dashboard (glassmorphism, Chart.js, 4 widgets) from a single prompt via gpt-4.1-mini fallback. Proves multi-agent orchestration works end-to-end. |
| 2026-03-21 | **Agent file delivery: text vs file write** | gpt-4.1-mini tends to output code as chat text rather than using OpenClaw's file-write tool. Add "Save to disk as index.html in a new folder called X" to prompts for reliable file delivery. The potato-shop demo (built by Gemini) wrote files correctly — model capability matters. |
| 2026-03-21 | ~~A2A communication: Gemini YES, gpt-4.1-mini NO~~ **CORRECTED** | Both Gemini and gpt-4.1-mini work for A2A. The issue was ACPX plugin not configured, not the model. After enabling ACPX plugin (command: "node", strictWindowsCmdWrapper: false), gpt-4.1-mini successfully delegates via sessions_spawn. |
| 2026-03-21 | **ACPX plugin: command="node" not .cmd wrapper** | Windows .cmd wrapper bug causes ACPX to fail silently. Node.js can't execute .cmd files natively without shell. Direct `"node"` command with CLI path as argument bypasses this. |
| 2026-03-21 | **Model split: master=gpt-4.1-mini, subs=gpt-4.1-nano** | Master needs reasoning capability for task decomposition and orchestration. Sub-agents handle simpler implementation tasks at lower cost. |
| 2026-03-21 | **try_out_demos/ folder convention** | All agent-built demos/projects saved in `wow_ai/try_out_demos/{project-name}/`. Prevents workspace clutter. Instruction embedded in both master-manager and coder SOUL.md files. |
| 2026-03-21 | **gateway.tools.allow for HTTP API** | `sessions_spawn` and `sessions_send` are on the gateway's HTTP `/tools/invoke` deny list by default. Added to `gateway.tools.allow` to enable direct HTTP tool invocation. |
| 2026-03-21 | **Full reset procedure documented** (Session 7) | Stop gateway → `docker compose down -v` → clear `~/.openclaw/{memory,telegram,workspace*,agents/*/sessions,subagents,logs,canvas,cron,credentials,identity}` → Redis FLUSHALL → recreate PostgreSQL → clear Telegram updates → re-pair Telegram → restart gateway → validate (54 checks). All code/config preserved. |
| 2026-03-21 | **Dashboard access after reset** (Session 7) | Use `openclaw dashboard --no-open` to get tokenized URL. Browser's old localStorage device tokens become invalid after reset, causing `device_token_mismatch`. Incognito or tokenized URL fixes it. |
| 2026-03-21 | **ACP spawn: no thread, no model-as-agentId, mode=run** (Session 8) | `sessions_spawn` from Telegram MUST use `"mode": "run"` (not `"session"`), agentId must be a role name (not a model like `openai/gpt-4.1-mini`), and NEVER include `"thread": true`. Added explicit WRONG/CORRECT examples to SOUL.md to prevent LLM hallucinating wrong parameters. |
| 2026-03-21 | **SOUL.md sync protocol** (Session 8) | Project source (`agents/*/SOUL.md` and `openclaw/SOUL.md`) is the source of truth. Must be copied to `~/.openclaw/agents/*/agent/SOUL.md` and `~/.openclaw/workspace-master-manager/SOUL.md` after any edit. Stale deployed copies cause agents to use wrong instructions. |

---

## Known Issues

| Issue                                    | Severity | Workaround                               |
|------------------------------------------|----------|------------------------------------------|
| NemoClaw alpha may have breaking changes | Medium   | Pin to specific commit/version            |
| Ollama 70B models need 48GB+ VRAM        | Low      | Use 7B models locally, 70B via Groq     |
| WSL2 features enabled but no reboot yet  | Low      | Docker works via Hyper-V; reboot when convenient |
| Windows: bash scripts need Git Bash      | Medium   | Git Bash is installed (via Git for Windows) |
| OpenClaw model warning                   | Low      | "ollama:qwen2.5-coder:7b" → auto-mapped to anthropic provider |
| GitHub token is placeholder              | Low      | Replace with real PAT when GitHub MCP needed |
| Copying openclaw.json overwrites runtime | FIXED    | Session 3: reference file cleaned; never copy it manually |
| `_workspace`/`_description`/`_comment` keys | FIXED | Session 3: removed invalid keys from openclaw/openclaw.json |
| Gateway RPC probe timeout on status      | Low      | Gateway is running; probe is warm-up lag (30s). Use `gateway status` after 30s |
| SOUL.md not loaded from ./agents/ dirs   | FIXED    | Session 3: copied to ~/.openclaw/agents/{name}/agent/SOUL.md |
| `adminId` not valid in Telegram config   | FIXED    | Session 3: removed. Admin access via DM pairing (dmPolicy: pairing) |
| Groq cannot handle master-manager prompt | HIGH     | System prompt is 28K tokens > Groq 12K TPM. Use Gemini as primary for master-manager. Groq works fine for sub-agents. |
| OpenClaw Ollama on 8GB RAM               | HIGH    | OpenClaw minimum context is 16000 tokens. With 16K context, Ollama models timeout/OOM on 8GB RAM. Needs 16GB+ RAM. Use Gemini+OpenAI on 8GB systems. |
| Gateway doesn't inherit shell env vars  | FIXED    | Session 4: Added GROQ_API_KEY, GEMINI_API_KEY, OLLAMA_API_KEY, OPENCLAW_OLLAMA_NUM_CTX to `~/.openclaw/gateway.cmd` |
| Gateway token mismatch                  | FIXED    | Session 4: Synced `gateway.auth.token` and `gateway.remote.token` in config to match `.env`'s `OPENCLAW_GATEWAY_TOKEN` |
| Gemini daily quota exhaustion            | Medium   | Free tier has 1M tokens/day. System prompt is ~28K tokens per call. ~35 calls/day before quota exhaustion. For heavy use, consider paid tier or multiple API keys. |
| System has only 8GB RAM                  | Medium   | Running Docker+PostgreSQL+Ollama+OpenClaw leaves only ~3GB free. Ollama models need context capping. Consider 16GB+ RAM for production. |
| CLI falls back to embedded mode          | Medium   | `openclaw agent` CLI cannot connect to gateway via WebSocket (3-second handshake timeout, ACPX needs 5+ seconds to initialize). Use Telegram or HTTP API instead. A2A works perfectly via Telegram (in-process, no WebSocket). |
| ACPX on Windows needs `command: "node"`  | FIXED    | Session 6: Windows .cmd wrapper bug. Set `plugins.entries.acpx.config.command` to `"node"` and `strictWindowsCmdWrapper` to false. |
| tictactoe.exe built in wrong location    | Low      | Coder agent builds files in `~/.openclaw/workspace-master-manager/`. Moved to `wow_ai/try_out_demos/tictactoe/`. SOUL.md updated with correct output path. |
| Web dashboard "device_token_mismatch" after reset | FIXED | Session 7: Browser caches device tokens in localStorage. After a reset, old tokens are invalid. Fix: use `openclaw dashboard --no-open` for tokenized URL, or incognito window. If rate-limited, restart gateway. |
| Telegram pairing required after reset    | FIXED    | Session 7: Device pairings cleared during reset. Run `openclaw pairing approve telegram <CODE>` when prompted. |
| ACP spawn fails from Telegram: "Thread bindings do not support ACP thread spawn" | FIXED | Session 8: `"thread": true` in SOUL.md spawn examples is incompatible with Telegram route bindings. Removed from all examples. Also fixed: model used model name as agentId and wrong mode. Added explicit guardrails to SOUL.md. |
| Sub-agent SOUL.md files out of sync      | FIXED    | Session 8: Deployed SOUL.md files in `~/.openclaw/agents/*/agent/` had stale paths (`/sandbox/src/`). Synced all 6 from project source `agents/*/SOUL.md`. |
| Master-manager builds files in workspace instead of try_out_demos | FIXED | Session 8: Coder SOUL.md now explicitly instructs output to `try_out_demos/{project-name}/`. Output directory convention added to master-manager SOUL.md spawn instructions. |
| ACP WebSocket handshake timeout (v2026.3.13 Windows) | HIGH | Known bug: `openclaw acp` bridge can't connect to gateway — 3-second handshake timeout kills the connection. GitHub #50380, #48167. No config workaround exists. **Fix**: Use `runtime: "subagent"` instead of `runtime: "acp"`. Subagent runs in-process. |
| Sub-agents ignore SOUL.md (OpenClaw bug #24852) | HIGH | Spawned sub-agents only load AGENTS.md and TOOLS.md, NOT SOUL.md. Workaround: embed all instructions in the `task` parameter text of `sessions_spawn`. |

---

## File Dependency Map

```
.env (credentials — DO NOT COMMIT)
     │
     ▼
docker-compose.yml ──→ memory/init.sql (PostgreSQL init)
     │
     ▼
scripts/start.sh ──→ openclaw gateway (reads ~/.openclaw/openclaw.json)
                          │
                          ├──→ openclaw/SOUL.md (Master identity)
                          ├──→ openclaw/USER.md (Admin profile)
                          ├──→ openclaw/AGENTS.md (A2A protocol)
                          ├──→ openclaw/HEARTBEAT.md (24/7 loop)
                          ├──→ openclaw/config/mcporter.json (MCP servers)
                          │
                          └──→ agents/*/SOUL.md (specialist profiles)

nemoclaw/nemoclaw.config.yml ──→ nemoclaw/policies/*.yml (security)

kubernetes/*.yml (production deployment - Phase 8)
```

### Runtime Config Location
```
~/.openclaw/openclaw.json     ← ACTUAL runtime config (managed by CLI)
openclaw/openclaw.json        ← Reference config (version-controlled)
```

---

## Changelog

### 2026-03-21 — Session 8: ACP Spawn Fix + SOUL.md Sync + UPSC App Recovery

**Fixed critical bug: master-manager could not spawn sub-agents from Telegram.**

**Root cause**: Three bugs in `sessions_spawn` calls from master-manager:
1. `"thread": true` — Telegram route bindings don't support thread-mode ACP spawning → error: "Thread bindings do not support ACP thread spawn for telegram."
2. `"agentId": "openai/gpt-4.1-mini"` — model name used instead of agent role name (should be `"coder"`, `"architect"`, etc.)
3. `"mode": "session"` — wrong mode (should be `"run"`)

**Fixes applied (iterative — 3 rounds of debugging):**

**Round 1 — Parameter fixes:**
- Removed `"thread": true` from all spawn examples in `openclaw/SOUL.md`
- Added explicit **CRITICAL PARAMETER RULES** section with WRONG vs CORRECT examples
- Synced ALL 7 SOUL.md files to deployed agent directories

**Round 2 — ACP config fix (still failed: "acpx exited with code 3"):**
- Added missing `acp.enabled: true`, `acp.dispatch.enabled: true`, `acp.backend: "acpx"`, `acp.allowedAgents` to `~/.openclaw/openclaw.json`
- The spawn parameters were now correct, but ACPX timed out after 300s

**Round 3 — WebSocket handshake timeout (ROOT CAUSE):**
- `openclaw acp` bridge connects back to gateway via WebSocket, but gateway has a 3-second handshake timeout
- This is a **known v2026.3.13 Windows bug** (GitHub issues #50380, #48167, #45560)
- The ACP bridge spends time loading plugins before completing handshake → times out → exit code 3
- **Fix**: Switched from `runtime: "acp"` to `runtime: "subagent"` in SOUL.md. Subagent mode runs in-process without WebSocket roundtrip.
- `gateway.ws` config key doesn't exist — no config workaround for the handshake timeout
- No newer OpenClaw version available (2026.3.13 is latest)

**Additional discovery — OpenClaw bug #24852:**
- Sub-agents spawned via `sessions_spawn` **ignore SOUL.md** — they only load AGENTS.md and TOOLS.md
- Workaround: All critical instructions (output path, requirements) MUST be embedded in the `task` parameter text
- Updated SOUL.md to instruct master-manager to include full instructions in every spawn task

- Restarted gateway, cleared all sessions

**Round 4 — Subagent permissions + autonomy:**
- Added `subagents.allowAgents` to master-manager agent config → fixed "no permission to spawn" error
- Rewrote SOUL.md with explicit **AUTONOMY RULE** — master-manager now runs full pipeline (architect → coder → qa → fix → report) without asking user for confirmation between steps
- Added "NEVER ASK, JUST DO" directive, "ONE message at start, ONE message at end" communication rules
- Sub-agents DON'T read SOUL.md (bug #24852), so all instructions embedded in task text
- Switched from `runtime: "acp"` to `runtime: "subagent"` everywhere (WebSocket handshake bug)
- Config validated, gateway restarted, sessions cleared

**UPSC app recovery:**
- Verified master-manager built a React SPA in workspace (`~/.openclaw/workspace-master-manager/app/`)
- Original `App.js` was corrupted (3 versions appended, not replaced — model wrote over itself)
- Agent's copy to `try_out_demos/upsc-preparatory/` was incomplete (missing `public/`, `src/index.js`, `app-server/`, `package.json`)
- Assembled complete working project with all missing files in `try_out_demos/upsc-preparatory/`

**Files modified:**
- `openclaw/SOUL.md` — removed `thread: true`, added parameter guardrails
- `~/.openclaw/agents/master-manager/agent/SOUL.md` — synced
- `~/.openclaw/workspace-master-manager/SOUL.md` — synced
- `~/.openclaw/agents/{architect,coder,devops,qa,researcher,tool-maker}/agent/SOUL.md` — all synced from project source
- `try_out_demos/upsc-preparatory/` — completed with all missing files

### 2026-03-21 — Session 7: Full Reset + Fresh Restart

**Complete clean-slate reset performed while preserving all code.**

**What was reset:**
- PostgreSQL: old Docker container + volume destroyed, fresh container spun up. `init.sql` re-ran automatically — 7 tables, 0 rows, pgvector v0.8.2 + uuid-ossp loaded
- Redis/Memurai: `FLUSHALL` — all cached state cleared
- All 12 OpenClaw agents: sessions, state, history, context, SQLite memory files wiped (main, master-manager, architect, coder, devops, qa, researcher, tool-maker, acp-coder, planner, router, supervisor)
- All 11 agent workspaces cleared
- Telegram: update offsets cleared, pending updates flushed
- Device pairings reset (requires re-approval: `openclaw pairing approve telegram <CODE>`)
- Subagents, canvas, logs, cron, credentials cache, identity cache, exec-approvals all cleared
- Leftover Docker volume `wow_ai_20_axiom_pgdata` + container `axiom-postgres` removed

**What was preserved:**
- All code, configs, SOUL.md files, agent profiles, scripts, BLUEPRINT.md, README.md
- `.env` with all real API keys (Groq, Gemini, OpenAI, Telegram)
- `~/.openclaw/gateway.cmd` with injected API keys
- `~/.openclaw/openclaw.json` runtime config
- `~/.openclaw/agents/*/agent/` agent definition directories
- `~/.acpx/config.json` agent mappings
- `~/.openclaw/acp-wrapper.mjs`

**Post-reset verification: 54 PASS | 0 FAIL | 0 WARN**

**Post-reset issue: web dashboard "device_token_mismatch"**
- Cause: browser cached old device tokens from before reset. Rapid reconnection attempts triggered in-memory rate limit ("too many failed authentication attempts")
- Fix: (1) close browser tab, (2) restart gateway to clear rate limit, (3) open fresh tokenized URL via `openclaw dashboard --no-open` or use incognito window
- Documented in "Web Dashboard access" section above for future reference

**Post-reset issue: Telegram pairing required**
- After clearing device pairings, first Telegram message returns pairing code
- Fix: `openclaw pairing approve telegram <CODE>` — approves user's Telegram ID
- Documented in "Post-reset pairing" section above

---

### 2026-03-21 — Session 6: A2A Delegation Working End-to-End

**MILESTONE: Agent-to-Agent delegation via ACPX plugin + sessions_spawn**

**The key fix** (discovered with Gemini's help): Windows .cmd execution bug. ACPX tries to spawn agents using a `.cmd` wrapper file, but Node.js can't execute `.cmd` files natively without a shell environment. Setting `plugins.entries.acpx.config.command` to `"node"` (direct Node binary) instead of the `.cmd` path bypasses this entirely.

**Complete fix chain (all required for A2A to work)**:
1. `openclaw plugins enable acpx` — registers ACPX runtime backend in gateway
2. `plugins.entries.acpx.config.command: "node"` — bypasses .cmd wrapper bug
3. `plugins.entries.acpx.config.strictWindowsCmdWrapper: false` — disables .cmd validation
4. `plugins.entries.acpx.config.timeoutSeconds: 300` — 5-minute timeout for sub-agent tasks
5. `plugins.entries.acpx.config.permissionMode: "approve-all"` — auto-approve tool calls
6. Custom SOUL.md copied to `~/.openclaw/workspace-master-manager/SOUL.md` (4443 bytes with delegation instructions)
7. All agent IDs mapped in `~/.acpx/config.json` to `acp-wrapper.mjs` wrapper
8. `acp-wrapper.mjs` created at `~/.openclaw/` to filter non-JSON stdout from `openclaw acp`
9. `gateway.tools.allow: ["sessions_spawn", "sessions_send"]` — removes from HTTP API deny list
10. Model split: master-manager → `openai/gpt-4.1-mini`, all sub-agents → `openai/gpt-4.1-nano`

**Successful A2A test**: User sent Tic-Tac-Toe prompt via Telegram → master-manager (gpt-4.1-mini) → `sessions_spawn(agentId: "coder")` → coder agent (gpt-4.1-nano) → wrote tictactoe.py with CustomTkinter → compiled with PyInstaller → produced tictactoe.exe (32 MB)

**Key architecture insight**: Telegram path bypasses the WebSocket handshake timeout that blocks CLI. When a Telegram message arrives, the master-manager runs INSIDE the gateway process — `sessions_spawn` uses in-process ACPX runtime directly (no WebSocket needed). The CLI path (`openclaw agent`) still falls back to embedded mode.

**Output convention added**: All agent-built projects now go in `wow_ai/try_out_demos/{project-name}/` — instruction embedded in both master-manager and coder SOUL.md files.

---

### 2026-03-21 — Session 5: OpenAI Integration + Multi-Provider Resilience

**Added OpenAI as last-resort paid fallback**
- Added `models.providers.openai` to `~/.openclaw/openclaw.json` with `baseUrl`, `api: "openai-responses"`, and two models
- **gpt-4.1-nano** ($0.10/1M input, $0.40/1M output) — cheapest OpenAI model, 200K TPM, good for all agent tasks
- **gpt-4.1-mini** ($0.40/1M input, $1.60/1M output) — for complex reasoning if nano isn't sufficient
- **Single API key** shared across all agents (most economical — Tier 1 rate limits are generous at 200K TPM)
- Budget: $10 credit. At gpt-4.1-nano pricing, that's ~100M input tokens or ~25M output tokens — plenty for development

**Ollama 4K variants blocked by OpenClaw minimum**
- Tested `-4k` model variants (4096 context) → OpenClaw rejects: "Model context window too small. Minimum is 16000."
- Reverted to original models with `contextWindow: 16384` in provider config
- On 8GB RAM, even 16K context causes timeout/OOM — Ollama is effectively non-functional for OpenClaw on this hardware
- **Ollama only works as fallback on systems with 16GB+ RAM**
- Direct `curl` to Ollama API with `num_ctx: 2048` works in 5 seconds — proves the model itself is fine, just OpenClaw's 16K minimum is the blocker

**Restructured fallback chain (optimized)**
1. `google/gemini-2.5-flash` — Primary (free, 1M tokens/day, handles 28K master-manager prompt)
2. `ollama/llama3.2:3b` — First fallback (free, local — works on 16GB+ RAM only)
3. `ollama/qwen2.5-coder:7b` — Second fallback (free, local — works on 16GB+ RAM only)
4. `openai/gpt-4.1-nano` — Third fallback (paid, reliable, cheapest OpenAI model)
5. `groq/llama-3.3-70b-versatile` — Last resort (free but 12K TPM limit blocks master-manager)

**On 8GB RAM systems**: Effectively Gemini (primary) → OpenAI (fallback) → Groq (last resort). Ollama will timeout.

**Model routing summary (updated)**:
| Agent | Primary Model | Fallbacks | Strategy |
|-------|--------------|-----------|----------|
| master-manager | `google/gemini-2.5-flash` | ollama → openai/gpt-4.1-nano → groq | Gemini handles 28K prompt; OpenAI catches Gemini quota exhaustion |
| Sub-agents (6) | `ollama/qwen2.5-coder:7b` | Uses defaults fallback chain | Local if RAM allows, else OpenAI |
| Global default | `google/gemini-2.5-flash` | Same as master-manager | Covers all edge cases |

**OpenAI cost estimate for demo usage**:
- Each master-manager call: ~28K input + ~2K output = ~$0.003 per call
- 100 calls of complex orchestration: ~$0.30
- $10 budget supports ~3,300+ calls — more than enough for development and demos

### 2026-03-21 — Session 4: Infrastructure Hardened + Model Strategy Corrected

**Critical discovery: Groq free tier cannot handle master-manager**
- The master-manager's system prompt (SOUL.md + AGENTS.md + HEARTBEAT.md + OpenClaw built-in tools) totals ~28,253 tokens
- Groq free tier has a 12,000 TPM (tokens per minute) hard limit — even a single request exceeds this
- This is NOT a rate limit (won't reset by waiting) — the prompt is permanently too large for Groq free tier
- **Solution**: Switched master-manager primary model to `google/gemini-2.5-flash` (1M tokens/day, 32K per request)
- Groq remains in fallback chain for sub-agents (architect, coder, etc.) which have smaller prompts (~3K tokens)

**Gateway token mismatch resolved**
- The `.env` file had `OPENCLAW_GATEWAY_TOKEN=df5b91cd...` which was different from the config's `gateway.auth.token=1208a4a6...`
- The gateway process uses the `.env` value (if loaded by the shell), but the CLI reads the config file value
- **Fix**: Synced both `gateway.auth.token` and `gateway.remote.token` to match the `.env` value
- This fix is essential — without it, CLI falls back to "embedded" mode (slower, no gateway features)

**Gateway service needs API keys in gateway.cmd**
- The gateway runs as a Windows Scheduled Task via `~/.openclaw/gateway.cmd`
- This process does NOT inherit shell environment variables (no `.env` loading)
- **Fix**: Added `GROQ_API_KEY`, `GEMINI_API_KEY`, `OLLAMA_API_KEY`, and `OPENCLAW_OLLAMA_NUM_CTX` to `gateway.cmd`
- Without this, the gateway can't authenticate with any provider and all model requests fail with "No API key found"

**OpenClaw Ollama context window OOM fixed (config-based, no source patching)**
- OpenClaw v2026.3.13 reads each Ollama model's `context_length` from metadata (e.g., 131072 for llama3.2:3b)
- It then passes this as `num_ctx` to Ollama's API, which allocates a KV cache for the full context
- A 3B model with 131K context needs 13.6 GiB of system memory — impossible on 8GB RAM
- **Fix**: Added explicit `models.providers.ollama` section to `~/.openclaw/openclaw.json` with `contextWindow: 16384` per model
  - OpenClaw enforces a minimum context of 16000 tokens, so 16384 is the lowest usable value
  - This is the official config approach — no source code patching needed, survives `npm update -g openclaw`
  - Added via: editing `~/.openclaw/openclaw.json` → `models.providers.ollama.models[]` with `contextWindow` field
- **Note**: On 8GB RAM, local Ollama models are slow (~3min+ response time) and primarily serve as last-resort fallbacks. Gemini handles all primary inference.

**GPU detected and available**
- NVIDIA GeForce GTX 1650 (4GB VRAM), CUDA 12.7, Driver 566.03
- Ollama automatically uses GPU for model weight offloading
- With 4K context: 7B model weights fit in 4GB VRAM, KV cache in system RAM

**Model routing summary (final)**:
| Agent | Primary Model | Why | Fallbacks |
|-------|--------------|-----|-----------|
| master-manager | `google/gemini-2.5-flash` | System prompt 28K tokens > Groq 12K TPM | groq/llama-3.3-70b-versatile → ollama/qwen2.5-coder:7b → ollama/llama3.2:3b |
| Sub-agents (6) | `ollama/qwen2.5-coder:7b` | Local, unlimited, ~3K token prompts | Uses defaults fallback chain |
| Global default | `google/gemini-2.5-flash` | Best free tier for large prompts | groq → ollama/qwen2.5-coder:7b → ollama/llama3.2:3b |

### 2026-03-20 — Session 3: Config Fixed + Clean Shutdown

- **Root cause identified**: Copying `openclaw/openclaw.json` → `~/.openclaw/openclaw.json` overwrote runtime credentials (botToken wiped) and failed schema validation due to `_comment`, `_workspace`, `_description` fields not being valid OpenClaw v2026.3.13 keys
- **Fixed reference config** (`openclaw/openclaw.json`): removed all `_comment`, `_workspace`, `_description` annotation fields; file now validates cleanly with `openclaw doctor`
- **Restored Telegram channel** via `openclaw channels add --channel telegram --token TOKEN` (proper CLI method)
- **Removed `adminId`** from config — not a valid key. Admin access uses DM pairing protocol
- **Fixed SOUL.md loading**: created `~/.openclaw/agents/{name}/agent/` dirs and copied SOUL.md files for all 6 specialist agents; master-manager also has AGENTS.md + HEARTBEAT.md
- **Updated start.sh**: added `openclaw config validate` check before gateway start; removed any reference to copying openclaw.json
- **Gateway verified running** then cleanly stopped and service uninstalled — ready for fresh start
- **State**: All configs valid, Telegram configured, SOUL.md files deployed. Run `./scripts/start.sh` to go live.

**Model format fix**:
- OpenClaw v2026.3.13 uses `provider/model` format (slash separator), NOT `provider:model` (colon)
- Correct: `groq/llama-3.3-70b-versatile`, `ollama/qwen2.5-coder:7b`, `google/gemini-2.5-flash`
- Wrong: `groq:llama-3.3-70b-versatile`, `ollama:qwen2.5-coder:7b`
- Added fallback chain: Groq → Gemini → Ollama (auto-failover)

**Gateway auth fix**:
- Set `gateway.remote.token` to match `gateway.auth.token` so CLI → Gateway WebSocket auth works
- Before this fix, CLI fell back to "embedded" mode (direct API calls instead of routing through gateway)

**ACP (Agent Control Protocol) fix**:
- Set `acp.defaultAgent: "coder"` to enable master-manager to spawn sub-agents

**Ollama provider fix**:
- Added `OLLAMA_API_KEY=ollama` to `.env` (any value works — Ollama is local, doesn't need real auth)
- Without this, OpenClaw can't discover Ollama models

**Agent test results**:
- Sent "Hello, are you working?" → got "Yes, I'm working." (Groq rate-limited, auto-fell back to Gemini 2.5 Flash)
- Sent "Build me a potato-selling website" → agent autonomously created 8 files: index.html, products.html, cart.html, checkout.html, about.html, contact.html, style.css, app.js
- Output in `potato-shop/` directory (copied from `~/.openclaw/workspace-master-manager/potato-shop/`)
- Website has: hero banner, 6 potato varieties with prices, shopping cart with localStorage, checkout page, contact form, responsive CSS

### 2026-03-20 — Session 2: Infrastructure Validated + Gateway Running
- Enabled WSL2 and Virtual Machine Platform Windows features (admin elevated)
- Restarted Docker Desktop — engine came up on Hyper-V backend
- Updated docker-compose.yml: removed Redis/Ollama containers (using native services)
- Updated .env with secure passwords (Postgres, Redis, gateway token)
- Telegram bot created via BotFather: @ohboy441clawbot, token stored in .env
- Pulled 3 Ollama models: qwen2.5-coder:7b (4.7GB), llama3.2:3b (2GB), nomic-embed-text (274MB)
- Started PostgreSQL Docker container — healthy, schema initialized (7 tables, pgvector v0.8.2)
- Verified Memurai (Redis) running natively on port 6379
- Fixed OpenClaw config schema: migrated from old format to v2026.3.13 schema
  - agents.list must be ARRAY (not object)
  - model must be {primary: "..."} (not string)
  - Removed deprecated keys: gateway.token, gateway.cors, memory.postgres, inference
  - Telegram uses botToken/adminId/dmPolicy/groupPolicy (not token/allowedUsers)
- Registered 8 agents via `openclaw agents add` CLI
- Started OpenClaw gateway — Telegram polling active, heartbeat running
- Updated validate.sh: 54 checks covering all services, configs, connectivity, APIs
- Ran full validation: **54 PASS, 0 FAIL, 0 WARN**
- Updated start.sh for native service architecture
- Updated openclaw/openclaw.json as reference config

### 2026-03-20 — Session 1: Initial Scaffolding
- Created complete project structure (37 files)
- Wrote full BLUEPRINT.md with 10-phase implementation plan
- Configured OpenClaw gateway with 6 agent profiles and model routing
- Configured NemoClaw security policies (network, permissions, HITL)
- Created Docker Compose stack and PostgreSQL schema
- Created Kubernetes manifests for production deployment
- Created setup, model install, start, validation, and prerequisites scripts
- Upgraded Node.js to 22.22.1, installed OpenClaw v2026.3.13
- Installed Docker Desktop v4.65.0 and Ollama v0.18.1
