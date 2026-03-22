# WOW AI — Autonomous Multi-Agent Orchestration Platform

An autonomous AI platform where a single **Master Manager** agent decomposes any software task and delegates it to a dynamically spawned army of specialist sub-agents. Agents communicate peer-to-peer, create more agents when needed, and operate 24/7 with minimal human intervention.

Built on **OpenClaw v2026.3.13** for agent execution and **NVIDIA NemoClaw** for enterprise-grade sandboxing and security.

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

**Model resilience**: OpenAI (primary, gpt-4.1-mini) → Gemini 2.5 Flash (free fallback) → Groq Llama 3.3 70B (free fallback).

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
# Edit .env — add your API keys:
#   OPENAI_API_KEY     → https://platform.openai.com/api-keys (primary, ~$0.20/1M tokens)
#   GEMINI_API_KEY     → https://aistudio.google.com (FREE — fallback)
#   GROQ_API_KEY       → https://console.groq.com (FREE — fallback)
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

This starts PostgreSQL (Docker), checks Redis/Memurai, validates config, and launches the OpenClaw gateway with Telegram polling.

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
├── try_out_demos/                  # Agent-built demo projects
│   ├── tictactoe/                  # Tic-Tac-Toe .exe (built autonomously)
│   └── website/                    # E-commerce website (built autonomously)
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
└── scripts/                        # Setup & utility scripts
    ├── setup.sh                    # One-click full setup
    ├── install-models.sh           # Download Ollama models
    ├── install-prerequisites.sh    # Install Node, Docker, Ollama
    ├── validate.sh                 # 54-check validation suite
    └── start.sh                    # Start the orchestrator
```

---

## Technology Stack

| Component          | Technology            | Purpose                         | Cost    |
|--------------------|-----------------------|---------------------------------|---------|
| Agent Runtime      | OpenClaw v2026.3.13   | Agent execution, channels, MCP  | Free    |
| Sub-agent Spawning | ACPX Plugin           | sessions_spawn, subagent runtime| Free    |
| Security           | NVIDIA NemoClaw       | Sandbox, policies, audit        | Free    |
| Primary Inference  | OpenAI gpt-4.1-mini   | All agents (quality + budget)   | $0.20/1M tokens |
| Fallback 1         | Google Gemini 2.5 Flash| Free cloud fallback            | Free    |
| Fallback 2         | Groq Llama 3.3 70B    | Free cloud fallback             | Free    |
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

**Fallback chain for all agents**: `openai/gpt-4.1-mini` → `google/gemini-2.5-flash` → `groq/llama-3.3-70b-versatile`

> **Cost estimate**: gpt-4.1-mini at $0.20/$0.80 per 1M tokens. A typical project build (architect + coder + qa) costs ~$0.05–0.15. A $10 OpenAI credit covers 65–200 complete project builds.

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

> **8GB RAM note**: Ollama OOMs when OpenClaw passes 16K context minimum. The system gracefully falls back to OpenAI/Gemini/Groq automatically.

---

## Known Issues & Workarounds (OpenClaw v2026.3.13)

| Problem | Cause | Workaround |
|---------|-------|------------|
| ACP WebSocket timeout (3s) | Windows bug #50380 | Use `runtime: "subagent"` instead of `"acp"` |
| Sub-agents ignore SOUL.md | Bug #24852 | Embed all instructions in the `task` parameter |
| ACPX exits with code 3 | .cmd wrapper crash on Windows | Set `command: "node"`, `strictWindowsCmdWrapper: false` |
| "No permission to spawn sub-agents" | Missing config | Add `subagents.allowAgents` to master-manager in config |

---

## Troubleshooting

| Problem                                | Solution                                              |
|----------------------------------------|-------------------------------------------------------|
| Sub-agents not spawning                | Ensure `gateway.tools.allow` includes `"sessions_spawn"`. Add `subagents.allowAgents` to master-manager config. |
| Poor output quality from sub-agents    | Verify all agents use `openai/gpt-4.1-mini`, not nano |
| Master-manager asks questions mid-task | SOUL.md autonomy rules not loaded. Re-sync `~/.openclaw/workspace-master-manager/SOUL.md` |
| Gateway "No API key found"             | Add `OPENAI_API_KEY` to `~/.openclaw/gateway.cmd` (gateway doesn't inherit shell env) |
| Gateway "token mismatch"               | Ensure `.env` `OPENCLAW_GATEWAY_TOKEN` matches `gateway.auth.token` in `~/.openclaw/openclaw.json` |
| Ollama OOM / timeout on 8GB RAM        | Normal — OpenClaw enforces 16K min context. Cloud fallback handles it automatically. |
| Files saved in wrong location          | Sub-agents ignore SOUL.md. Ensure the `task` parameter includes the full output path. |
| OpenClaw command not found             | Run `npm install -g openclaw` |

---

## License

This project scaffolding is open source. Individual components have their own licenses:
- OpenClaw: MIT License
- NemoClaw: Apache 2.0
- Ollama: MIT License
- PostgreSQL: PostgreSQL License
