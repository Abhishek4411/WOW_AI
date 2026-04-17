# WOW AI — Autonomous Multi-Agent Orchestration Platform

An autonomous AI platform where a single **Master Manager** agent decomposes any software task and delegates it to a dynamically spawned army of specialist sub-agents. Agents communicate peer-to-peer, create more agents when needed, and operate 24/7 with minimal human intervention.

Built on **OpenClaw v2026.3.13+** for agent execution and **NVIDIA NemoClaw** for enterprise-grade sandboxing and security.

**GitHub**: [github.com/Abhishek4411/WOW_AI](https://github.com/Abhishek4411/WOW_AI)

---

## Architecture

```
  You (Telegram)
        │
        ▼
┌─────────────────┐
│  MASTER MANAGER  │  ← openai/gpt-4.1-mini (orchestrator)
│  (Orchestrator)  │
└──┬──┬──┬──┬──┬──┘
   │  │  │  │  │  (sessions_spawn, runtime: subagent)
   ▼  ▼  ▼  ▼  ▼
┌──────┐┌─────┐┌──────┐┌────┐┌──────────┐┌───────────┐
│ARCHI-││CODER││DEVOPS││ QA ││RESEARCHER││TOOL-MAKER │
│TECT  ││     ││      ││    ││          ││           │
└──────┘└─────┘└──────┘└────┘└──────────┘└───────────┘
       ALL sub-agents → openai/gpt-4.1-mini
```

**A2A delegation**: Master Manager → `sessions_spawn` (runtime: `subagent`) → specialist agents. Works end-to-end via Telegram bot `@ohboy441clawbot`.

**Model**: OpenAI gpt-4.1-mini exclusively for all agents. gpt-4.1-nano for heartbeat/compaction. No Gemini, no Groq.

**Governance**: All LLM calls route through the Traccia proxy (`localhost:8001`) for real-time monitoring at [traccia.ai/dashboard](https://traccia.ai/dashboard).

**Output convention**: All agent-built projects are saved to `try_out_demos/{project-name}/`.

---

## Quick Start

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker + Compose | Latest | [docker.com](https://docs.docker.com/get-docker/) |
| Node.js | v22+ | [nodejs.org](https://nodejs.org/) |
| Git | Latest | [git-scm.com](https://git-scm.com/) |
| Ollama | Latest | [ollama.com](https://ollama.com/) |
| OpenClaw | v2026.3.13+ | `npm install -g openclaw` |

### 1. Clone and Configure

```bash
git clone https://github.com/Abhishek4411/WOW_AI.git wow_ai && cd wow_ai
cp .env.example .env
# Edit .env — add your keys:
#   OPENAI_API_KEY     → https://platform.openai.com/api-keys  (all agents use this)
#   BRAVE_API_KEY      → https://brave.com/search/api/  (free tier — for web_search)
#   TRACCIA_API_KEY    → https://traccia.ai/dashboard  (free — real-time agent monitoring)
#   TELEGRAM_BOT_TOKEN → Create via @BotFather on Telegram
```

### 2. One-Time Agent Setup

```bash
npm install -g openclaw

# Pull AI models for local embedding (~1GB)
ollama pull nomic-embed-text

# Register all 7 agents (ALL use gpt-4.1-mini)
openclaw agents add --id master-manager --name master-manager --model "openai/gpt-4.1-mini"
openclaw agents add --id architect --name architect --model "openai/gpt-4.1-mini"
openclaw agents add --id coder --name coder --model "openai/gpt-4.1-mini"
openclaw agents add --id devops --name devops --model "openai/gpt-4.1-mini"
openclaw agents add --id qa --name qa --model "openai/gpt-4.1-mini"
openclaw agents add --id researcher --name researcher --model "openai/gpt-4.1-mini"
openclaw agents add --id tool-maker --name tool-maker --model "openai/gpt-4.1-mini"

# Configure Telegram channel
openclaw channels add --channel telegram --token YOUR_TELEGRAM_BOT_TOKEN

# Enable ACPX plugin for sub-agent spawning (required)
openclaw plugins enable acpx

# Copy agent identity files to OpenClaw managed dirs
mkdir -p ~/.openclaw/workspace-master-manager
cp openclaw/SOUL.md ~/.openclaw/workspace-master-manager/SOUL.md
cp openclaw/AGENTS.md ~/.openclaw/workspace-master-manager/AGENTS.md

for agent in architect coder devops qa researcher tool-maker; do
  mkdir -p ~/.openclaw/agents/$agent/agent
  cp agents/$agent/SOUL.md ~/.openclaw/agents/$agent/agent/SOUL.md
done
mkdir -p ~/.openclaw/agents/master-manager/agent
cp openclaw/SOUL.md ~/.openclaw/agents/master-manager/agent/SOUL.md
```

### 3. Start Everything

```bash
./scripts/start.sh
```

This starts PostgreSQL (Docker), checks Redis/Memurai, starts the Traccia governance proxy (`:8001`), validates config, and launches the OpenClaw gateway with Telegram polling.

### 4. Talk to Your Agent

Open Telegram and DM your bot:
> "Build me a full-stack e-commerce website with product catalog, shopping cart, and checkout"

The Master Manager decomposes the task, delegates to specialist sub-agents (architect → coder → qa), and delivers the finished project to `try_out_demos/{project-name}/` — fully autonomously, no questions asked.

---

## Project Structure

```
wow_ai/
├── BLUEPRINT.md                    # Full architecture blueprint (10 phases)
├── README.md                       # This file
├── PROJECT_NOTES.md                # Continuation notes for AI/IDE handoff
├── docker-compose.yml              # Local dev stack (PostgreSQL)
├── .env.example                    # Environment variables template
├── .gitignore                      # Git ignore rules
│
├── openclaw/                       # OpenClaw agent configuration
│   ├── openclaw.json               # Reference gateway config
│   ├── SOUL.md                     # Master Manager identity & rules
│   ├── USER.md                     # Admin profile, DND, HITL rules
│   ├── AGENTS.md                   # Sub-agent communication protocol
│   ├── HEARTBEAT.md                # 24/7 autonomous operation loop
│   └── config/
│       └── mcporter.json           # MCP server configurations
│
├── agents/                         # Specialist agent profiles
│   ├── architect/SOUL.md           # System design specialist
│   ├── coder/SOUL.md               # Code generation specialist
│   ├── devops/SOUL.md              # Kubernetes/infra specialist
│   ├── qa/SOUL.md                  # Testing & security specialist
│   ├── researcher/SOUL.md          # Web research specialist
│   └── tool-maker/SOUL.md          # Custom MCP server builder
│
├── try_out_demos/                  # Agent-built demo projects (output convention)
│   ├── snakes_game/                # Snakes & Ladders with Pygame + .exe (game pipeline)
│   ├── chilika_lagoon_research/    # 7-chapter .docx research paper (research pipeline)
│   ├── market_analysis/            # Stock market analysis report (data pipeline)
│   ├── tictactoe/                  # Tic-Tac-Toe .exe (first A2A proof-of-concept)
│   └── website/                    # E-commerce website (web pipeline)
│
├── nemoclaw/                       # NVIDIA NemoClaw security config
│   ├── nemoclaw.config.yml         # Sandbox, Privacy Router, audit
│   └── policies/
│       ├── network-egress.yml      # Per-agent network allowlists
│       ├── agent-permissions.yml   # Capability restrictions
│       └── hitl-rules.yml          # Human approval triggers
│
├── memory/                         # Database initialization
│   └── init.sql                    # PostgreSQL + pgvector schema (7 tables)
│
├── kubernetes/                     # K8s production deployment
│   ├── namespace.yml
│   ├── master-agent-deployment.yml
│   ├── postgres-statefulset.yml
│   ├── redis-deployment.yml
│   ├── ollama-deployment.yml
│   ├── network-policies.yml
│   └── gpu-time-slicing-config.yml
│
├── governance/                     # Traccia governance proxy
│   ├── proxy.py                    # FastAPI OpenAI-compatible proxy (:8001)
│   ├── requirements.txt            # Python deps (traccia, fastapi, uvicorn, httpx)
│   └── __init__.py
│
└── scripts/                        # Setup & utility scripts
    ├── setup.sh                    # One-click full setup
    ├── install-models.sh           # Download Ollama models
    ├── install-prerequisites.sh    # Install Node, Docker, Ollama
    ├── validate.sh                 # 54-check validation suite
    ├── sync-token.sh               # Auto-heal gateway token mismatches
    ├── start-traccia-proxy.sh      # Start governance proxy (auto-called by start.sh)
    └── start.sh                    # Start the orchestrator (PostgreSQL + Traccia + gateway)
```

---

## Technology Stack

| Component          | Technology            | Purpose                         | Cost    |
|--------------------|-----------------------|---------------------------------|---------|
| Agent Runtime      | OpenClaw v2026.3.13+  | Agent execution, channels, MCP  | Free    |
| Sub-agent Spawning | ACPX Plugin           | sessions_spawn, subagent runtime| Free    |
| Security           | NVIDIA NemoClaw       | Sandbox, policies, audit        | Free    |
| Primary Inference  | OpenAI gpt-4.1-mini   | All 7 agents (only model used)  | ~$0.20/1M tokens |
| Governance         | Traccia proxy         | Real-time traces, cost, policies| Free tier |
| Web Search         | Brave Search MCP      | web_search for all agents       | Free (2000 req/mo) |
| DB Access          | Postgres MCP          | Agents can query WOW AI database| Free    |
| Local Inference    | Ollama                | Embeddings (nomic-embed-text)   | Free    |
| Memory             | PostgreSQL + pgvector | Vectorized semantic memory      | Free    |
| Cache              | Redis / Memurai       | Task queues, ephemeral state    | Free    |
| Orchestration      | Kubernetes (K3s)      | Agent pod management            | Free    |
| Tool Protocol      | MCP                   | Universal tool access           | Free    |
| Communication      | Telegram              | Human-agent interface           | Free    |

---

## Agent Model Assignments

| Agent         | Model                    | Role                                    |
|---------------|--------------------------|-----------------------------------------|
| Master Manager| `openai/gpt-4.1-mini`   | Orchestrator — decomposes & delegates   |
| Architect     | `openai/gpt-4.1-mini`   | System design, project structure        |
| Coder         | `openai/gpt-4.1-mini`   | Code generation, file creation          |
| DevOps        | `openai/gpt-4.1-mini`   | Infrastructure, Docker, deployment      |
| QA            | `openai/gpt-4.1-mini`   | Code review, testing, validation        |
| Researcher    | `openai/gpt-4.1-mini`   | Web research, documentation lookup      |
| Tool Maker    | `openai/gpt-4.1-mini`   | Build custom MCP servers on demand      |

**No fallbacks** — OpenAI is the only provider. Removing Gemini/Groq avoids the Gemini 503 web_search failures and keeps governance simple.

> **Cost estimate**: gpt-4.1-mini at $0.20/$0.80 per 1M tokens. A typical project build (architect + coder + qa) costs ~$0.05–0.15. A $10 OpenAI credit covers 65–200 complete project builds.

---

## Real-Time Governance (Traccia)

Every LLM call from every agent is intercepted by `governance/proxy.py` — a FastAPI server on `:8001` that acts as a local OpenAI-compatible endpoint.

```
Telegram → Master Manager → sessions_spawn → Coder / QA / Researcher / ...
                                   │
                         Each agent LLM call
                                   │
                                   ▼
                    localhost:8001 (governance proxy)
                        ├── Records trace to Traccia
                        ├── Checks policies (token limits, costs, allowlist)
                        └── Forwards to api.openai.com → response back
```

**What you see on [traccia.ai/dashboard](https://traccia.ai/dashboard)**:

| Tab | What Shows |
|-----|-----------|
| Traces | Every agent call — agent name, model, tokens in/out, cost, latency, status |
| Agents | All 7 agents with cumulative cost, error rate, avg latency |
| Detected Patterns | Policy violations (e.g. agent exceeded 30K tokens, session over $0.50) |
| Overview | Total spend, active agents, requests/min — live |

**Policies enforced automatically**:
- Hard block: single call > 30,000 tokens
- Soft warn: session cost > $0.50
- Hard block: unknown agent name (not in approved list)

**The proxy starts automatically** with `./scripts/start.sh` when `TRACCIA_API_KEY` is set.
Manual start: `bash scripts/start-traccia-proxy.sh`

---

## Cost Optimization

Token-saving strategies applied to minimize spend without sacrificing quality:

| Strategy | Setting | Savings |
|----------|---------|---------|
| **Heartbeat on nano** | `heartbeat.model: "openai/gpt-4.1-nano"` | ~50% cheaper per heartbeat vs mini |
| **Hourly heartbeat** | `heartbeat.every: "60m"` | Half the calls vs default 30min |
| **Light context heartbeat** | `heartbeat.lightContext: true` | Only loads HEARTBEAT.md, not full agent context (~75% fewer input tokens) |
| **Active hours only** | `heartbeat.activeHours: 08:00–24:00 IST` | No burns while sleeping (8 hours saved/day) |
| **Compaction on nano** | `compaction.model: "openai/gpt-4.1-nano"` | Summarization is simple — nano handles it at half the cost |
| **History cap** | `compaction.maxHistoryShare: 0.4` | Caps conversation history at 40% of context window |
| **Memory flush** | `compaction.memoryFlush.enabled: true` | Auto-saves important notes before compaction (prevents re-asking) |

**Result**: Background ops cost ~$0.03–0.05/month instead of ~$0.60–1.00/month (~95% reduction). Project builds unchanged.

---

## Key Features

- **Fully autonomous pipeline**: architect → coder → qa → fix → deliver, no human input between steps
- **Agents creating agents**: Master spawns specialists via `sessions_spawn` (runtime: `subagent`)
- **24/7 autonomous operation**: Heartbeat loop with health checks, auto-recovery, self-healing
- **Do Not Disturb**: Set DND for hours or days — agents work autonomously, queue updates
- **Human-in-the-Loop**: Only bothers you for production deploys, security, or critical failures
- **Semantic memory**: PostgreSQL + pgvector prevents context exhaustion
- **Zero-trust security**: NemoClaw sandboxes every agent with seccomp, Landlock, network namespaces
- **Output delivery**: All projects saved to `try_out_demos/{project-name}/`

---

## Hardware Requirements

| Tier          | CPU    | RAM   | GPU                   | Use Case         |
|---------------|--------|-------|-----------------------|------------------|
| Minimum       | 4 core | 8 GB  | None (cloud inference)| Development      |
| Recommended   | 8 core | 16 GB | GTX 1650+ (4GB)       | Production       |
| Cloud Free    | 4 ARM  | 24 GB | None                  | Oracle Cloud     |

> **8GB RAM note**: Ollama OOMs when OpenClaw passes 16K context minimum. All agents fall back to OpenAI cloud inference automatically (no Ollama required for agent LLMs — only for embeddings).

---

## Known Issues & Workarounds (OpenClaw v2026.3.13+)

| Problem | Cause | Workaround |
|---------|-------|------------|
| ACP WebSocket timeout (3s) | Windows bug #50380 | Use `runtime: "subagent"` instead of `"acp"` |
| Sub-agents ignore SOUL.md | Bug #24852 | Embed all instructions in the `task` parameter |
| ACPX exits with code 3 | .cmd wrapper crash on Windows | Set `command: "node"`, `strictWindowsCmdWrapper: false` |
| "No permission to spawn sub-agents" | Missing config | Add `subagents.allowAgents` to master-manager in config |
| Agents spawn in parallel → file not found | gpt-4.1-mini ignores "after X completes" | SOUL.md enforces hard sequential rule with file verification between steps |
| Sub-agents can't see each other's files | Isolated workspaces per agent | Use absolute paths to shared `try_out_demos/{project}/` directory |
| `400 Policy violation: estimated N tokens exceeds hard limit` | Traccia proxy `max_tokens_per_call` was 30K — too low for master-manager's SOUL.md (~34K chars) + history | **Fixed**: limit raised to 500K in `governance/proxy.py`. Normal agent calls will never hit it; only genuine runaway loops will. |
| `web_search` fails with 503 | Gemini API was overloaded; Gemini removed entirely | **Fixed**: removed Gemini/Groq. Get a free Brave API key at brave.com/search/api — add to `.env` and `~/.openclaw/openclaw.json` mcpServers.brave-search.env.BRAVE_API_KEY |
| ResearchGate blocks web_fetch (403) | Bot IP blocked by Cloudflare | Skip ResearchGate; use MDPI, IEEE, Springer, Google Scholar instead |
| .docx not generated (only .md files) | Coder not spawned or spawned too early | Pipeline enforces: researcher → verify → architect → verify → coder (python-docx) → verify → QA |
| Master-manager asks "shall I proceed?" | gpt-4.1-mini ignores autonomy rules | SOUL.md now has FORBIDDEN PHRASES list — explicit ban on 7 common question patterns |
| .docx has repeated text / for-loop content | gpt-4.1-mini output limit (~8K tokens) | Chapter-by-chapter strategy: spawn coder once per chapter (500+ words each), then compile into .docx |
| `start.sh` exits after "Stopping gateway" | MSYS2 (Git Bash) converts `/c` arg to `C:/` path; `cmd.exe /c` never gets the flag → starts interactive mode → blocks script | **Fixed in start.sh**: all `cmd.exe /c` calls replaced with `powershell.exe` equivalents |
| `pip install` permission error (Windows) | Global site-packages is write-protected | **Fixed in pipelines**: all Python agent tasks now create a `venv` first: `python -m venv venv && source venv/Scripts/activate` |

---

## Troubleshooting

| Problem                                | Solution                                              |
|----------------------------------------|-------------------------------------------------------|
| Sub-agents not spawning                | Ensure `gateway.tools.allow` includes `"sessions_spawn"`. Add `subagents.allowAgents` to master-manager config. |
| Poor output quality from sub-agents    | Verify all agents use `openai/gpt-4.1-mini`, not nano |
| Master-manager asks questions mid-task | SOUL.md autonomy rules not loaded. Re-sync `~/.openclaw/workspace-master-manager/SOUL.md` |
| Gateway "No API key found"             | Add `OPENAI_API_KEY` to `~/.openclaw/gateway.cmd` (gateway doesn't inherit shell env) |
| Gateway "token mismatch" (dashboard)   | **Automatic** — `start.sh` runs `sync-token.sh` on every startup and auto-opens the tokenized dashboard URL in your browser. If it still fails: press F5 once on the dashboard tab (token is embedded in URL). |
| `start.sh` closes/exits after gateway stop step | MSYS2 bug: `cmd.exe /c` → `/c` converted to `C:/` → cmd starts interactive → blocks + breaks script. **Fixed**: replaced with `powershell.exe -Command "Stop-ScheduledTask ..."`. |
| Ollama OOM / timeout on 8GB RAM        | Normal — OpenClaw enforces 16K min context. Cloud fallback handles it automatically. |
| Files saved in wrong location          | Sub-agents ignore SOUL.md. Ensure the `task` parameter includes the full output path. |
| OpenClaw command not found             | Run `npm install -g openclaw` |
| How to upgrade OpenClaw safely         | `npm install -g openclaw@latest && openclaw doctor --fix && bash scripts/start.sh`. `start.sh` now warns you if an update is available on every run. |

---

## License

This project scaffolding is open source. Individual components have their own licenses:
- OpenClaw: MIT License
- NemoClaw: Apache 2.0
- Ollama: MIT License
- PostgreSQL: PostgreSQL License
