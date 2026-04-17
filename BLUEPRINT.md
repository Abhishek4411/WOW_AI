# WOW AI — Autonomous Multi-Agent Orchestration Platform
## Complete End-to-End Blueprint

---

## 1. SYSTEM DESIGN

### Master Orchestrator Definition

```
You are the MASTER MANAGER — a super-intelligent orchestrator operating within the
OpenClaw execution framework, secured by the NVIDIA NemoClaw governance stack.

PRIME DIRECTIVE:
Decompose any user request (building web apps, APIs, mobile apps, infrastructure,
data pipelines, or any software system) into discrete tasks. Dynamically spawn an
army of specialized sub-agents via OpenClaw's sub-agent system to execute them.

EXECUTION RULES:
1. You NEVER write code directly. You delegate to specialist agents.
2. Sub-agents communicate peer-to-peer via A2A (Agent-to-Agent) protocol.
3. Sub-agents may spawn their own sub-agents (max depth: 3) to solve sub-problems.
4. Use Ollama (local) for embeddings. Use OpenAI gpt-4.1-mini for all reasoning.
5. All LLM calls route through the Traccia governance proxy on localhost:8001.
6. Use MCP servers for all external tool access (K8s, GitHub, databases, browsers).
7. Persist all memory to PostgreSQL + pgvector. Never rely on context window alone.
8. Operate continuously 24/7 via HEARTBEAT.md loop.
9. Communicate with human admin ONLY via Telegram.
10. Enforce Do Not Disturb (DND) — queue non-urgent updates during DND windows.
11. Trigger Human-in-the-Loop (HITL) ONLY for: critical failures, security
    authorizations, production deployments, or financial decisions.
12. All agent execution is sandboxed via NemoClaw OpenShell. No host access.

AVAILABLE SPECIALIST AGENTS:
- architect: System design, database schemas, API contracts
- coder: Code generation, implementation, debugging
- devops: Kubernetes deployment, CI/CD, infrastructure
- qa: Testing, code review, security audits
- researcher: Web browsing, documentation lookup, API discovery
- tool-maker: Build custom MCP servers, tools, integrations on demand
```

---

## 2. TECHNOLOGY STACK

| Layer              | Technology                          | Role                                    | License/Cost    |
|--------------------|-------------------------------------|-----------------------------------------|-----------------|
| Agent Execution    | OpenClaw v2026.3.13                 | Agent runtime, gateway, channels        | MIT (Free)      |
| Sub-agent Spawning | ACPX Plugin                         | sessions_spawn, subagent runtime        | MIT (Free)      |
| Security/Sandbox   | NVIDIA NemoClaw (alpha preview)     | OpenShell sandbox, policy enforcement   | Apache 2.0 (Free)|
| Local Inference    | Ollama                              | Embeddings (nomic-embed-text)           | MIT (Free)      |
| Primary Inference  | OpenAI gpt-4.1-mini                 | All 7 agents — best quality/cost ratio  | $0.20/$0.80 /1M |
| Background Ops     | OpenAI gpt-4.1-nano                 | Heartbeat + compaction (cost savings)   | $0.10/$0.40 /1M |
| Governance         | Traccia + `governance/proxy.py`     | Real-time LLM monitoring & policy       | Free (traccia.ai)|
| Web Search         | Brave Search MCP + web_fetch        | Research tool for agents                | Free tier       |
| Tool Protocol      | Model Context Protocol (MCP)        | Universal tool access standard          | Open standard   |
| Persistent Memory  | PostgreSQL + pgvector               | Vectorized long-term agent memory       | PostgreSQL License|
| Communication      | Telegram Bot API                    | Primary human-agent interface           | Free            |
| Database           | PostgreSQL                          | Application data persistence            | Free            |
| Cache              | Redis (Memurai on Windows)          | Ephemeral state, task queues            | BSD (Free)      |
| Container Runtime  | Docker / containerd                 | Agent container execution               | Apache 2.0 (Free)|
| GUI (planned)      | Next.js + Tailwind CSS              | Web dashboard for monitoring agents     | MIT (Free)      |
| Version Control    | Git + GitHub                        | Code storage, PR management             | Free            |

---

## 3. ARCHITECTURE OVERVIEW

```
┌─────────────────────────────────────────────────────────────────┐
│                     HUMAN ADMIN INTERFACE                        │
│                   Telegram (@ohboy441clawbot)                    │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OPENCLAW GATEWAY (port 3000)                  │
│  ┌──────────────────┐  ┌────────────────┐  ┌─────────────────┐  │
│  │ Telegram Channel  │  │ Session Manager│  │ ACPX Plugin     │  │
│  │ (dmPolicy:pairing)│  │ (Memory Router)│  │ (subagent spawn)│  │
│  └──────────────────┘  └────────────────┘  └─────────────────┘  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              NEMOCLAW GOVERNANCE LAYER                           │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐  │
│  │ OpenShell    │ │ Policy       │ │ Network Egress          │  │
│  │ Sandbox      │ │ Engine       │ │ Policies (per-agent     │  │
│  │ (seccomp,    │ │ (YAML-based  │ │ allowlists — default    │  │
│  │  Landlock,   │ │  permissions)│ │ DENY ALL)              │  │
│  │  namespaces) │ │              │ │                        │  │
│  └──────────────┘ └──────────────┘ └────────────────────────┘  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│           TRACCIA GOVERNANCE PROXY (port 8001)                   │
│  governance/proxy.py — FastAPI OpenAI-compatible endpoint        │
│                                                                  │
│  Every OpenClaw LLM call → intercepted here → forwarded to      │
│  api.openai.com. Structured LLM spans recorded to traccia.ai    │
│  dashboard: agent names, token counts, cost, latency, policies. │
│                                                                  │
│  Policy enforcement:                                             │
│  • max_tokens_per_call: 500,000 (hard block)                    │
│  • max_session_cost_usd: $2.00 (soft warn)                      │
│  • agent_allowlist: all 7 named agents (hard block on unknown)  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MASTER MANAGER AGENT                          │
│              openai/gpt-4.1-mini — orchestrator                 │
│                                                                  │
│  Responsibilities:                                               │
│  • Task decomposition & delegation (NEVER writes code itself)    │
│  • Spawns sub-agents via sessions_spawn (runtime: subagent)      │
│  • Autonomous pipeline: architect → coder → qa → fix → deliver  │
│  • HITL escalation & DND enforcement                             │
│  • 24/7 heartbeat monitoring                                     │
└──────┬──────────┬──────────┬──────────┬──────────┬──────────────┘
       │          │          │          │          │
       ▼          ▼          ▼          ▼          ▼
┌──────────┐┌──────────┐┌──────────┐┌──────────┐┌──────────────┐
│ARCHITECT ││ CODER    ││ DEVOPS   ││   QA     ││ RESEARCHER   │
│ Agent    ││ Agent    ││ Agent    ││ Agent    ││ Agent        │
│          ││          ││          ││          ││              │
│gpt-4.1  ││gpt-4.1   ││gpt-4.1   ││gpt-4.1   ││gpt-4.1-mini │
│mini     ││mini      ││mini      ││mini      ││              │
└──────────┘└────┬─────┘└──────────┘└──────────┘└──────────────┘
                 │
                 ▼ (spawns if needed)
          ┌──────────────┐
          │ TOOL-MAKER   │
          │ Agent        │
          │ gpt-4.1-mini │
          │ (builds MCP  │
          │  servers on  │
          │  demand)     │
          └──────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    MCP SERVER LAYER                              │
│  ┌───────────┐ ┌───────────┐ ┌──────────┐ ┌────────────────┐  │
│  │Brave      │ │ Fetch     │ │PostgreSQL│ │ Kubernetes     │  │
│  │Search MCP │ │ MCP Server│ │MCP Server│ │ MCP Server     │  │
│  └───────────┘ └───────────┘ └──────────┘ └────────────────┘  │
│  ┌───────────┐ ┌───────────┐ ┌──────────┐ ┌────────────────┐  │
│  │ GitHub    │ │ Docker    │ │ Redis    │ │ Custom (built  │  │
│  │ MCP Server│ │ MCP Server│ │MCP Server│ │ by Tool-Maker) │  │
│  └───────────┘ └───────────┘ └──────────┘ └────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                    │
│  ┌────────────────────┐ ┌─────────────────┐ ┌───────────────┐  │
│  │ PostgreSQL         │ │ pgvector        │ │ Redis         │  │
│  │ (App data,         │ │ (Agent memory,  │ │ (Task queues, │  │
│  │  agent state,      │ │  embeddings,    │ │  ephemeral    │  │
│  │  audit logs)       │ │  semantic       │ │  state, pub/  │  │
│  │                    │ │  search)        │ │  sub)         │  │
│  └────────────────────┘ └─────────────────┘ └───────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER (Phase 8)                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Namespace: wow-ai-agents                                │    │
│  │ • Master Manager Pod (always running)                   │    │
│  │ • Specialist Agent Pods (ephemeral, auto-scaled)        │    │
│  │ • PostgreSQL StatefulSet                                │    │
│  │ • Redis Deployment                                      │    │
│  │ • Ollama Inference Pod (GPU-attached)                   │    │
│  │ • MCP Server Pods                                       │    │
│  │ • Next.js GUI Deployment                                │    │
│  │ • Network Policies (strict egress/ingress)              │    │
│  └─────────────────────────────────────────────────────────┘    │
│  GPU Time-Slicing: nvidia.com/gpu.replicas=4                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. DETAILED IMPLEMENTATION PHASES

### Phase 1: Foundation (Week 1-2)
**Goal**: Set up local dev environment, install OpenClaw + NemoClaw, verify inference

1. Install Docker, K3s (lightweight Kubernetes), Ollama
2. Install OpenClaw: `npm install -g openclaw`
3. Install NemoClaw: `curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash`
4. Download local models via Ollama:
   - `ollama pull nomic-embed-text` (embeddings for memory)
5. Configure OpenClaw gateway (`openclaw.json`)
6. Set up PostgreSQL + pgvector via Docker Compose
7. Verify basic agent can execute shell commands in sandbox

### Phase 2: Master Manager Agent (Week 2-3)
**Goal**: Create the central orchestrator with task decomposition

1. Write SOUL.md for Master Manager identity and rules (keep under 20,000 chars — OpenClaw hard limit)
2. Write AGENTS.md with sub-agent delegation instructions
3. Configure model: OpenAI gpt-4.1-mini for all agents
4. Start Traccia governance proxy before OpenClaw gateway
5. Test: Give Master a simple task → verify it creates a plan and delegates autonomously

### Phase 3: Specialist Agent Army (Week 3-4)
**Goal**: Create and test each specialist agent profile

1. Create agent profiles in `agents/` directory:
   - `architect/SOUL.md` — system design specialist
   - `coder/SOUL.md` — code generation specialist
   - `devops/SOUL.md` — infrastructure specialist
   - `qa/SOUL.md` — testing & security specialist
   - `researcher/SOUL.md` — web research specialist
2. Register agents: `openclaw agents add --id <name> --name <name> --model "openai/gpt-4.1-mini"`
3. Configure sub-agent spawning in Master's config:
   - `maxSpawnDepth: 3`
   - `maxConcurrent: 5`
   - `maxChildrenPerAgent: 3`
4. Test A2A communication between Master → Coder → QA

### Phase 4: MCP Server Integration (Week 4-5)
**Goal**: Connect agents to external tools via MCP

1. Configure MCP servers in `openclaw.json` under `plugins.entries.acpx.config.mcpServers`:
   - Brave Search MCP (`@modelcontextprotocol/server-brave-search`)
   - Fetch MCP (`@modelcontextprotocol/server-fetch`)
   - PostgreSQL MCP (`@modelcontextprotocol/server-postgres`)
   - Kubernetes MCP (cluster management)
   - GitHub MCP (repo management, PRs)
2. Test each MCP server independently
3. Grant specific MCP access per agent via NemoClaw policies

### Phase 5: Traccia Governance Integration (Complete)
**Goal**: Real-time monitoring of all agent LLM calls

1. `governance/proxy.py` — FastAPI server on :8001, OpenAI-compatible endpoint
2. `governance/requirements.txt` — traccia, fastapi, uvicorn, httpx, python-dotenv
3. `scripts/start-traccia-proxy.sh` — auto-install venv, start proxy, health-check
4. `scripts/start.sh` — starts proxy before OpenClaw gateway
5. OpenClaw's `openai.baseUrl` set to `http://localhost:8001/v1` in `~/.openclaw/openclaw.json`
6. Dashboard at [traccia.ai/dashboard](https://traccia.ai/dashboard) shows:
   - Per-agent token counts and USD cost
   - Latency per call
   - Policy violations (unknown agents, token overflows)
   - Full call timeline: master-manager → researcher → coder → qa

### Phase 6: Persistent Memory System (Week 5-6)
**Goal**: Replace Markdown memory with PostgreSQL + pgvector

1. Deploy PostgreSQL with pgvector extension
2. Create memory schema (embeddings table, agent_state, audit_log)
3. Configure OpenClaw memory backend: `memory.backend = "postgres"`
4. Implement semantic memory search for cross-agent knowledge sharing
5. Test: Agent recalls decisions made by other agents days prior

### Phase 7: Communication & HITL (Week 6-7)
**Goal**: Telegram integration with DND protocol

1. Create Telegram bot via @BotFather
2. Add bot token to `openclaw.json` channels config
3. Bind Master Manager to Telegram: `openclaw agents bind --agent master --bind telegram`
4. Implement DND logic in USER.md
5. Implement HITL approval flow

### Phase 8: 24/7 Continuous Operation (Week 7-8)
**Goal**: Implement heartbeat loop and self-healing

1. Write HEARTBEAT.md with scheduled routines
2. Set up system cron for heartbeat trigger
3. Implement auto-recovery: detect crashed agents, parse logs, respawn
4. Heartbeat uses gpt-4.1-nano (cost-optimized)

### Phase 9: Kubernetes Production Deployment (Week 8-10)
**Goal**: Move from Docker Compose to full K8s deployment

1. Create K8s namespace: `wow-ai-agents`
2. Deploy all components as K8s resources
3. Apply network policies (strict egress/ingress per agent)
4. Configure GPU time-slicing if GPU available

### Phase 10: Web GUI Dashboard (Week 10-12)
**Goal**: Build monitoring and interaction interface

1. Scaffold Next.js app with Tailwind CSS
2. Pages: `/dashboard`, `/agents`, `/tasks`, `/chat`, `/settings`, `/preview`
3. Connect to PostgreSQL for real-time data
4. WebSocket for live agent status updates

### Phase 11: Self-Evolving Loop (Week 12+)
**Goal**: Agents that create new agents and tools on demand

1. Implement Tool-Maker agent profile
2. When specialist lacks a tool → spawn Tool-Maker → build custom MCP server
3. Implement agent template system: Master can create new SOUL.md files dynamically
4. Implement learning loop: extract patterns → store as pgvector embeddings

---

## 5. MODEL ROUTING STRATEGY

**Current deployment**: ALL agents use `openai/gpt-4.1-mini`. No fallbacks.

| Agent / Task         | Model                    | Notes                            | Cost            |
|----------------------|--------------------------|----------------------------------|-----------------|
| master-manager       | openai/gpt-4.1-mini     | Orchestrator                     | $0.20/$0.80 /1M |
| architect            | openai/gpt-4.1-mini     | System design                    | $0.20/$0.80 /1M |
| coder                | openai/gpt-4.1-mini     | Code generation                  | $0.20/$0.80 /1M |
| devops               | openai/gpt-4.1-mini     | Infrastructure                   | $0.20/$0.80 /1M |
| qa                   | openai/gpt-4.1-mini     | Testing & review                 | $0.20/$0.80 /1M |
| researcher           | openai/gpt-4.1-mini     | Web research                     | $0.20/$0.80 /1M |
| tool-maker           | openai/gpt-4.1-mini     | MCP server builder               | $0.20/$0.80 /1M |
| Heartbeat/Compaction | openai/gpt-4.1-nano     | Background ops (cost-optimized)  | $0.10/$0.40 /1M |
| Embeddings           | nomic-embed-text (Ollama)| Semantic memory                  | Free (local)    |

**Why gpt-4.1-mini for everything**: Past experience with gpt-4.1-nano produced poor quality output for complex tasks (code generation, system design, research). gpt-4.1-mini provides significantly better quality at $0.20/$0.80 per 1M tokens.

**Why no fallbacks**: Gemini/Groq fallbacks were removed because `web_search` was powered by Gemini's Google Search grounding — removing the key broke search silently. All search is now handled via `web_fetch` + DuckDuckGo HTML strategy which requires no API key.

### Cost Optimization

| Strategy | Setting | Savings |
|---|---|---|
| Heartbeat on nano | `heartbeat.model: "openai/gpt-4.1-nano"` | ~50% cheaper per heartbeat vs mini |
| Hourly heartbeat | `heartbeat.every: "60m"` | Half the calls vs default 30min |
| Light context heartbeat | `heartbeat.lightContext: true` | ~75% fewer input tokens per heartbeat |
| Active hours only | `heartbeat.activeHours: 08:00–24:00 IST` | No burns while sleeping |
| Compaction on nano | `compaction.model: "openai/gpt-4.1-nano"` | Simple summarization — nano handles it |
| History cap | `compaction.maxHistoryShare: 0.4` | Caps history at 40% of context window |

**Result**: Background ops ~$0.03–0.05/month. Project builds ~$0.05–0.15 each.

---

## 6. SECURITY MODEL

### NemoClaw Policy Layers

1. **Sandbox Isolation** (OpenShell)
   - seccomp filters restrict system calls
   - Landlock enforces unprivileged access control
   - Dedicated network namespaces per agent
   - Agents can only write to `/sandbox` and `/tmp`

2. **Network Policies** (`nemoclaw/policies/network-egress.yml`)
   - Default: deny all egress/ingress
   - Per-agent allowlists: only explicitly listed hosts are reachable
   - Researcher has broad HTTP/S access but `noFilesystemWrite: true`, `noDatabaseAccess: true`
   - All agents can reach: `api.openai.com`, `api.traccia.ai`, `host.docker.internal:11434`

3. **Traccia Governance Proxy** (`governance/proxy.py`)
   - All LLM calls intercepted before reaching OpenAI
   - Policy hard-blocks: unknown agents, token overflow
   - Every call logged to traccia.ai with agent name, tokens, cost

4. **Credential Vaulting**
   - API keys in `.env` (never committed to git)
   - Proxy reads `OPENAI_API_KEY` from environment at runtime
   - Sub-agents NEVER see actual credentials

5. **HITL Security Gates**
   - Production deployments require human approval
   - Financial operations require human approval
   - New external API integrations require human approval

---

## 7. API KEYS NEEDED

| Service        | Get Key At                              | Required?          | Notes                         |
|----------------|----------------------------------------|--------------------|-------------------------------|
| OpenAI         | platform.openai.com/api-keys           | **Required**       | All 7 agents use this         |
| Traccia        | traccia.ai/dashboard → Settings        | **Required**       | Real-time governance dashboard|
| Telegram Bot   | t.me/BotFather                         | **Required**       | Human-agent interface         |
| Brave Search   | brave.com/search/api                   | Recommended        | Free tier — enables web_search|
| GitHub         | github.com/settings/tokens             | Optional           | For GitHub MCP server         |
| Ollama         | ollama.com (local install)             | Required (local)   | Unlimited (local)             |

---

## 8. HARDWARE REQUIREMENTS

### Minimum (Development)
- CPU: 8 cores
- RAM: 16 GB (32 GB recommended)
- Storage: 100 GB SSD
- GPU: Optional (OpenAI cloud inference — no local GPU needed for core functionality)
- Network: Stable internet (all LLM calls go to api.openai.com via proxy)

### Recommended (Production)
- CPU: 16+ cores
- RAM: 64 GB
- Storage: 500 GB NVMe SSD
- GPU: NVIDIA RTX 3090/4090 (24GB VRAM) — for local Ollama models
- Network: Stable internet for OpenAI API

### Cloud Alternative (Free Tier)
- Oracle Cloud: 4 ARM cores, 24GB RAM (Always Free)
- Google Cloud: $300 credit for 90 days
- K3s instead of full Kubernetes for resource efficiency

---

## 9. PROJECT DIRECTORY STRUCTURE

```
wow_ai/
├── BLUEPRINT.md                          # This document
├── README.md                             # Quick-start guide
├── docker-compose.yml                    # Local development stack
├── .env.example                          # Environment variables template
│
├── openclaw/                             # OpenClaw configuration
│   ├── openclaw.json                     # Reference gateway config (commit-safe)
│   ├── SOUL.md                           # Master Manager identity (≤20,000 chars)
│   ├── USER.md                           # Admin profile + DND rules
│   ├── AGENTS.md                         # Sub-agent delegation rules
│   └── HEARTBEAT.md                      # 24/7 continuous operation loop
│
├── agents/                               # Specialist agent profiles
│   ├── architect/SOUL.md
│   ├── coder/SOUL.md
│   ├── devops/SOUL.md
│   ├── qa/SOUL.md
│   ├── researcher/SOUL.md                # Includes web_fetch DuckDuckGo strategy
│   └── tool-maker/SOUL.md
│
├── governance/                           # Traccia governance proxy
│   ├── proxy.py                          # FastAPI OpenAI-compatible proxy on :8001
│   ├── requirements.txt                  # traccia, fastapi, uvicorn, httpx
│   └── __init__.py
│
├── nemoclaw/                             # NemoClaw security config
│   ├── nemoclaw.config.yml               # Main NemoClaw configuration
│   └── policies/
│       ├── network-egress.yml            # Network allowlists per agent (default: DENY)
│       ├── agent-permissions.yml         # Agent capability restrictions
│       └── hitl-rules.yml                # Human-in-the-loop triggers
│
├── memory/                               # Database initialization
│   └── init.sql                          # PostgreSQL + pgvector schema
│
├── kubernetes/                           # K8s deployment manifests (Phase 9)
│   ├── namespace.yml
│   ├── master-agent-deployment.yml
│   ├── postgres-statefulset.yml
│   └── network-policies.yml
│
├── gui/                                  # Next.js web dashboard (Phase 10)
│
└── scripts/                              # Setup and utility scripts
    ├── start.sh                          # Start full stack (proxy + docker + openclaw)
    ├── start-traccia-proxy.sh            # Start governance proxy on :8001
    └── install-models.sh                 # Download Ollama models
```

---

## 10. CRITICAL WARNINGS AND LIMITATIONS

1. **NemoClaw is in ALPHA** (released March 16, 2026). Expect breaking changes.
   Not production-ready. Track: https://github.com/NVIDIA/NemoClaw

2. **OpenClaw SOUL.md has a 20,000-character hard limit.** Content beyond 20K is silently
   truncated without any error. If Spawning Rules, Communication Rules, or Self-Sufficiency
   sections fall beyond 20K, the master-manager will ask questions instead of delegating
   autonomously. Always verify `wc -c openclaw/SOUL.md` stays under 20,000.

3. **GPU memory is the bottleneck** for local Ollama inference. For consumer hardware (24GB),
   use 14B models. Core functionality (all 7 agents) uses OpenAI cloud — no GPU needed.

4. **Infinite agent spawning is dangerous**. Always enforce:
   - `maxSpawnDepth: 3` (not infinite)
   - `maxConcurrent: 5` (per agent)
   - `runTimeoutSeconds: 3600` (1 hour max per sub-agent)

5. **Context window exhaustion** is the #1 killer of long-running agents. The
   PostgreSQL + pgvector memory system is CRITICAL. Without it, agents enter
   infinite compaction loops and burn API credits.

6. **For-loop content generation** is the #2 killer. LLMs with ~8K output token limits
   will generate 3 sentences and loop them under every heading when asked to produce
   a long document in a single call.
   **Solution**: Spawn coder ONCE PER CHAPTER (500+ words each), then compile.

7. **Sub-agents ignore SOUL.md** (OpenClaw bug #24852). Sub-agents spawned via
   `sessions_spawn` only load AGENTS.md and TOOLS.md. All instructions (output path,
   quality rules, self-sufficiency) MUST be embedded in the `task` parameter.

8. **Gateway token mismatch** is automatically fixed by `scripts/start.sh`.
   Reads `~/.openclaw/openclaw.json` directly via Node.js to get the true token.

9. **Traccia proxy must start before OpenClaw gateway.** OpenClaw reads `baseUrl` at
   startup. If the proxy is not running when gateway starts, all LLM calls fail.
   `start.sh` handles this ordering automatically.

10. **Security is non-negotiable**. Never run agents without NemoClaw sandbox.
    A rogue agent with host access can destroy your system.

---

## 11. OPERATIONAL STRATEGIES (Learned from Production)

These strategies were discovered through real usage and are critical for reliable operation.

### 11.1 Forbidden Phrases Rule
The master-manager naturally generates phrases like "Let me know if you want me to proceed"
between pipeline steps. This pauses the entire pipeline. To eliminate this:
- 7 banned question patterns are listed in SOUL.md's FORBIDDEN PHRASES section
- Zero intermediate messages: SOUL.md enforces ONE start message + ONE final report
- Rationale: gpt-4.1-mini learned from conversational data where confirmation is polite.
  The FORBIDDEN PHRASES override is a hard workaround for this training bias.

### 11.2 Chapter-by-Chapter Writing Strategy
**Problem**: LLMs have ~8K output token limits. Asking a single coder to write a 15-page
research document results in 3 sentences looped under every heading — "for-loop laziness."

**Solution**: Spawn the coder ONCE PER CHAPTER. Each call writes one chapter to
`chapters/chapter_N.md` with minimum 500 words. A final compile coder reads all chapter
files and assembles the `.docx` via `python-docx`.

### 11.3 Sequential Spawning with File Verification
**Problem**: gpt-4.1-mini sometimes spawns researcher + coder simultaneously. The coder
fails because `RESEARCH_DATA.md` doesn't exist yet — a race condition.

**Hard rule**: Spawn ONE agent → WAIT for completion → VERIFY output file exists →
THEN spawn the next. File verification is the synchronization barrier.

### 11.4 Shared Workspace Convention
Each sub-agent runs in its own isolated workspace. Files written by researcher are invisible
to coder unless both use the same absolute path.

**Convention**: ALL agents read/write to:
`C:\Users\Dancy Naik\Documents\VS_Code_Test\wow_ai\try_out_demos\{project-name}\`

Every spawn task MUST include this path and `mkdir -p` to create it.

### 11.5 Self-Sufficiency Rules
Sub-agents MUST never ask the user for anything. Always embed in spawn task:
- "Install missing packages yourself (`pip install`, `npm install`)"
- "If you need information, use `web_fetch` on DuckDuckGo: `web_fetch('https://html.duckduckgo.com/html/?q=YOUR+QUERY')`"
- "Debug errors yourself, retry up to 3 times"
- "NEVER ask the user questions. NEVER say 'please provide'."

### 11.6 Web Search Without API Key
`web_search` requires a Brave API key. When unavailable, use `web_fetch` directly:
```
DuckDuckGo: web_fetch("https://html.duckduckgo.com/html/?q=YOUR+SEARCH+QUERY")
Wikipedia:  web_fetch("https://en.wikipedia.org/wiki/Topic")
GitHub:     web_fetch("https://github.com/search?q=topic&type=repositories")
```
This strategy is embedded in SOUL.md and researcher/SOUL.md.

### 11.7 Quality Gates Between Every Pipeline Step
Between each pipeline step, master-manager MUST verify the previous agent's output:
- File EXISTS at the expected absolute path
- File size is above minimum threshold (RESEARCH_DATA.md > 2000 words, .docx > 50KB)
- No placeholder text present

If verification fails → respawn (max 3 retries) → after 3 failures → HITL.

### 11.8 Market Analysis / Data Tasks: Code-First Approach
Complex financial reasoning exceeds gpt-4.1-mini's capabilities. For market analysis:
- **DO NOT** ask the agent to reason about markets
- **DO** ask the agent to write Python code using `yfinance`, `pandas`, `matplotlib`
- The code fetches real data and generates reports — no reasoning needed
