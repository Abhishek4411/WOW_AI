# WOW AI — Autonomous Multi-Agent Orchestration Platform

An autonomous AI platform where a single **Master Manager** agent decomposes any software task and delegates it to a dynamically spawned army of specialist sub-agents. Agents communicate peer-to-peer, create more agents when needed, and operate 24/7 with minimal human intervention.

Built on **OpenClaw** (MIT License) for agent execution and **NVIDIA NemoClaw** (Apache 2.0) for enterprise-grade sandboxing and security.

---

## Architecture

```
  You (Telegram / WhatsApp / Web GUI)
              │
              ▼
     ┌─────────────────┐
     │  MASTER MANAGER  │  ← OpenAI gpt-4.1-mini (orchestrator)
     │  (Orchestrator)  │
     └──┬──┬──┬──┬──┬──┘
        │  │  │  │  │  (sessions_spawn via ACPX)
        ▼  ▼  ▼  ▼  ▼
  ┌─────┐┌─────┐┌──────┐┌────┐┌──────────┐
  │ARCHI││CODER││DEVOPS││ QA ││RESEARCHER│  ← OpenAI gpt-4.1-nano
  └─────┘└──┬──┘└──────┘└────┘└──────────┘
            │
            ▼ (spawns if needed)
      ┌───────────┐
      │TOOL-MAKER │  ← Builds custom MCP servers on demand
      └───────────┘
```

**A2A delegation**: Master Manager → `sessions_spawn` → ACPX runtime → sub-agents. Works end-to-end via Telegram.
**Model resilience**: OpenAI (primary) → Gemini (free fallback) → Groq (free fallback).

---

## Quick Start

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker + Compose | Latest | [docker.com](https://docs.docker.com/get-docker/) |
| Node.js | v22+ | [nodejs.org](https://nodejs.org/) |
| Git | Latest | [git-scm.com](https://git-scm.com/) |
| Ollama | Latest | [ollama.com](https://ollama.com/) |

### 1. Clone, Configure, and Install

```bash
git clone <your-repo-url> wow_ai && cd wow_ai
cp .env.example .env
# Edit .env — add your API keys:
#   GEMINI_API_KEY     → https://aistudio.google.com (FREE — primary)
#   GROQ_API_KEY       → https://console.groq.com (FREE — fallback)
#   OPENAI_API_KEY     → https://platform.openai.com/api-keys (PAID — last resort, ~$0.10/1M tokens)
#   TELEGRAM_BOT_TOKEN → Create via @BotFather on Telegram

npm install -g openclaw
```

### 2. One-Time Agent Setup

```bash
chmod +x scripts/*.sh

# Pull AI models (~7GB total)
ollama pull qwen2.5-coder:7b && ollama pull llama3.2:3b && ollama pull nomic-embed-text

# Register agents (model format: provider/model)
# Master-manager uses Gemini (system prompt is ~28K tokens, exceeds Groq's 12K TPM limit)
openclaw agents add --id master-manager --name master-manager --model "google/gemini-2.5-flash"
openclaw agents add --id architect --name architect --model "ollama/qwen2.5-coder:7b"
openclaw agents add --id coder --name coder --model "ollama/qwen2.5-coder:7b"
openclaw agents add --id devops --name devops --model "ollama/qwen2.5-coder:7b"
openclaw agents add --id qa --name qa --model "ollama/qwen2.5-coder:7b"
openclaw agents add --id researcher --name researcher --model "ollama/qwen2.5-coder:7b"
openclaw agents add --id tool-maker --name tool-maker --model "ollama/qwen2.5-coder:7b"

# Set default model and fallbacks (gemini → groq → ollama)
openclaw models set "google/gemini-2.5-flash"
openclaw models fallbacks add "groq/llama-3.3-70b-versatile"
openclaw models fallbacks add "ollama/qwen2.5-coder:7b"
openclaw models fallbacks add "ollama/llama3.2:3b"

# Configure Telegram
openclaw channels add --channel telegram --token YOUR_TELEGRAM_BOT_TOKEN

# Configure ACP for sub-agent spawning
openclaw config set acp.defaultAgent coder

# Copy agent identity files to OpenClaw managed dirs
for agent in architect coder devops qa researcher tool-maker; do
  mkdir -p ~/.openclaw/agents/$agent/agent
  cp agents/$agent/SOUL.md ~/.openclaw/agents/$agent/agent/SOUL.md
done
# Master-manager gets the full set
mkdir -p ~/.openclaw/agents/master-manager/agent
cp openclaw/SOUL.md ~/.openclaw/agents/master-manager/agent/SOUL.md
cp openclaw/AGENTS.md ~/.openclaw/agents/master-manager/agent/AGENTS.md
cp openclaw/HEARTBEAT.md ~/.openclaw/agents/master-manager/agent/HEARTBEAT.md
```

### 3. Start Everything

```bash
./scripts/start.sh
```

This starts PostgreSQL (Docker), checks Redis/Memurai and Ollama (native), validates config, and launches the OpenClaw gateway with Telegram polling.

### 4. Talk to Your Agent

Open Telegram and DM your bot. Send any task:
> "Build me a full-stack e-commerce website with product catalog, shopping cart, and checkout"

The Master Manager decomposes the task, uses free models (Gemini/Groq/Ollama), and builds it autonomously.

> **Model format**: OpenClaw uses `provider/model` (slash, not colon). Example: `google/gemini-2.5-flash`, `groq/llama-3.3-70b-versatile`, `ollama/qwen2.5-coder:7b`.

> **IMPORTANT**: Never copy `openclaw/openclaw.json` to `~/.openclaw/openclaw.json`. The runtime config is managed by the CLI.

> **A2A Delegation**: The master-manager delegates tasks to sub-agents via ACPX plugin + `sessions_spawn`. This requires: `openclaw plugins enable acpx`, `plugins.entries.acpx.config.command: "node"`, `strictWindowsCmdWrapper: false`. All agent-built projects are saved to `try_out_demos/{project-name}/`.

> **Hardware note (8GB RAM)**: On 8GB RAM systems, Ollama will timeout through OpenClaw (minimum 16K context → OOM). The fallback chain handles this gracefully: Gemini (free) → Ollama (attempts, times out) → **OpenAI gpt-4.1-nano** ($0.001/call, catches failures) → Groq. Your $10 OpenAI budget covers ~10,000 fallback calls.

---

## Project Structure

```
wow_ai/
├── BLUEPRINT.md                    # Full architecture blueprint (10 phases)
├── README.md                       # This file
├── PROJECT_NOTES.md                # Continuation notes for AI/IDE handoff
├── docker-compose.yml              # Local dev stack
├── .env.example                    # Environment variables template
├── .gitignore                      # Git ignore rules
│
├── openclaw/                       # OpenClaw agent configuration
│   ├── openclaw.json               # Gateway config (channels, agents, memory)
│   ├── SOUL.md                     # Master Manager identity & rules
│   ├── USER.md                     # Admin profile, DND, HITL rules
│   ├── AGENTS.md                   # Sub-agent communication protocol
│   ├── HEARTBEAT.md                # 24/7 autonomous operation loop
│   └── config/
│       └── mcporter.json           # MCP server configurations (7 servers)
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
│   └── tictactoe/                 # Tic-Tac-Toe game (.exe + source)
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
    └── start.sh                    # Start the orchestrator
```

---

## Technology Stack

| Component          | Technology            | Purpose                         | Cost    |
|--------------------|-----------------------|---------------------------------|---------|
| Agent Runtime      | OpenClaw              | Agent execution, channels, MCP  | Free    |
| Security           | NVIDIA NemoClaw       | Sandbox, policies, audit        | Free    |
| Local Inference    | Ollama                | Local LLM, no rate limits       | Free    |
| Cloud Inference    | Groq API              | Fast cloud fallback             | Free    |
| Cloud Inference    | Google Gemini API     | Complex reasoning               | Free    |
| Paid Fallback      | OpenAI API            | Last-resort when free exhausted | ~$0.10/1M tokens |
| Memory             | PostgreSQL + pgvector | Vectorized semantic memory      | Free    |
| Cache              | Redis                 | Task queues, ephemeral state    | Free    |
| Orchestration      | Kubernetes (K3s)      | Agent pod management            | Free    |
| Tool Protocol      | MCP                   | Universal tool access           | Free    |
| Communication      | Telegram / WhatsApp   | Human-agent interface           | Free    |

---

## Agent Model Routing

| Agent         | Default Model                    | Fallbacks                                      | Provider  |
|---------------|----------------------------------|-------------------------------------------------|-----------|
| Master Manager| `openai/gpt-4.1-mini`           | gemini-2.5-flash → groq                        | OpenAI    |
| Architect     | `openai/gpt-4.1-nano`           | gemini-2.5-flash → groq                        | OpenAI    |
| Coder         | `openai/gpt-4.1-nano`           | gemini-2.5-flash → groq                        | OpenAI    |
| DevOps        | `openai/gpt-4.1-nano`           | gemini-2.5-flash → groq                        | OpenAI    |
| QA            | `openai/gpt-4.1-nano`           | gemini-2.5-flash → groq                        | OpenAI    |
| Researcher    | `openai/gpt-4.1-nano`           | gemini-2.5-flash → groq                        | OpenAI    |
| Tool Maker    | `openai/gpt-4.1-nano`           | gemini-2.5-flash → groq                        | OpenAI    |

> **Why OpenAI?** Reliable A2A delegation via `sessions_spawn`. Master-manager uses gpt-4.1-mini ($0.40/1M input) for orchestration reasoning. Sub-agents use gpt-4.1-nano ($0.10/1M input) for implementation. $10 budget covers ~2,500+ master-manager calls. Gemini and Groq serve as free fallbacks.

---

## Key Features

- **Agents creating agents**: Master spawns specialists who can spawn sub-agents (max depth 3)
- **24/7 autonomous operation**: Heartbeat loop with health checks, auto-recovery, self-healing
- **Do Not Disturb**: Set DND for hours or days — agents work autonomously, queue updates
- **Human-in-the-Loop**: Only bothers you for production deploys, security, or critical failures
- **Semantic memory**: PostgreSQL + pgvector prevents context exhaustion for infinite-length tasks
- **Zero-trust security**: NemoClaw sandboxes every agent with seccomp, Landlock, network namespaces
- **Free infrastructure**: Everything runs on free APIs and local models

---

## Hardware Requirements

| Tier          | CPU    | RAM   | GPU                   | Use Case         |
|---------------|--------|-------|-----------------------|------------------|
| Minimum       | 8 core | 16 GB | None (CPU inference)  | Development      |
| Recommended   | 16 core| 64 GB | RTX 3090/4090 (24GB)  | Production       |
| Cloud Free    | 4 ARM  | 24 GB | None                  | Oracle Cloud     |

---

## Troubleshooting

| Problem                                | Solution                                              |
|----------------------------------------|-------------------------------------------------------|
| Docker Compose won't start             | Ensure Docker Desktop is running                      |
| PostgreSQL connection refused           | Wait 10s after `docker compose up`, check with `docker compose ps` |
| Ollama model pull fails                 | Check disk space (models are 2-40GB each)            |
| Groq API 429 / "Request too large"      | Master-manager prompt (28K tokens) exceeds Groq 12K TPM. Use Gemini as primary. |
| Gemini "quota exceeded"                 | Daily quota (1M tokens/day) exhausted. Resets at midnight PT. |
| Ollama OOM / timeout on 8GB RAM         | OpenClaw enforces minimum 16K context which causes OOM/timeout on 8GB RAM. Ollama serves as a fallback attempt but will timeout — OpenAI gpt-4.1-nano catches it at $0.001/call. |
| Gateway "token mismatch"                | Ensure `.env` `OPENCLAW_GATEWAY_TOKEN` matches `gateway.auth.token` in `~/.openclaw/openclaw.json` |
| Gateway "No API key found"              | Add `GROQ_API_KEY`, `GEMINI_API_KEY`, `OLLAMA_API_KEY` to `~/.openclaw/gateway.cmd` |
| OpenClaw command not found              | Run `npm install -g openclaw`                        |
| NemoClaw OOM kill                       | Need 8GB+ RAM; add 8GB swap as workaround            |
| Agent stuck in infinite loop            | Check `maxSpawnDepth` and `runTimeoutSeconds` in config |
| All models fail simultaneously          | Check OpenAI API key is set in `.env` AND `~/.openclaw/gateway.cmd`. OpenAI ($10 budget) catches all free-tier exhaustions. |
| ACPX not registered / sub-agents fail   | Run `openclaw plugins enable acpx`, set `plugins.entries.acpx.config.command` to `"node"` (not .cmd), set `strictWindowsCmdWrapper: false`, restart gateway |
| Sub-agents not spawning                 | Ensure `gateway.tools.allow` includes `sessions_spawn`. Check `~/.acpx/config.json` maps all agent IDs. |
| CLI falls back to embedded mode         | Known Windows issue: WebSocket handshake timeout (3s). Use Telegram for A2A delegation instead — it runs in-process. |
| "ACP runtime backend not configured"    | ACPX plugin not loaded. Run `openclaw plugins enable acpx` and restart gateway. Check logs for `acpx runtime backend ready`. |

---

## License

This project scaffolding is open source. Individual components have their own licenses:
- OpenClaw: MIT License
- NemoClaw: Apache 2.0
- Ollama: MIT License
- PostgreSQL: PostgreSQL License
