# WOW AI — Autonomous Multi-Agent Orchestration Platform
## Complete End-to-End Blueprint

---

## 1. RECTIFIED SYSTEM PROMPT

The original request has been analyzed, debugged, and refined into a formal Architectural
Request Definition. All ambiguities, typos, and contradictions have been resolved.

### Optimized Master Orchestrator Prompt

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
4. Use free local models (Ollama) for routine tasks, cloud APIs (Groq/Gemini) for
   complex reasoning. Route via NemoClaw Privacy Router.
5. Operate within Kubernetes. Each agent runs in an isolated pod.
6. Use MCP servers for all external tool access (K8s, GitHub, databases, browsers).
7. Persist all memory to PostgreSQL + pgvector. Never rely on context window alone.
8. Operate continuously 24/7 via HEARTBEAT.md loop.
9. Communicate with human admin ONLY via Telegram/WhatsApp.
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

## 2. TECHNOLOGY STACK (Verified, All Free/Open-Source)

| Layer              | Technology                          | Role                                    | License/Cost    |
|--------------------|-------------------------------------|-----------------------------------------|-----------------|
| Agent Execution    | OpenClaw v0.x (247K GitHub stars)   | Agent runtime, gateway, channels        | MIT (Free)      |
| Security/Sandbox   | NVIDIA NemoClaw (alpha preview)     | OpenShell sandbox, policy enforcement   | Apache 2.0 (Free)|
| Local Inference    | Ollama                              | Free local LLM inference, no rate limits| MIT (Free)      |
| Cloud Inference    | Groq API (free tier)                | Ultra-fast cloud inference fallback     | Free tier       |
| Cloud Inference    | Google Gemini API (free tier)       | Complex reasoning tasks                 | Free tier       |
| Cloud Inference    | NVIDIA Nemotron (via Ollama)        | Agentic-optimized local model           | Open weights    |
| Orchestration      | Kubernetes (K3s for local)          | Container orchestration for agent pods  | Apache 2.0 (Free)|
| Tool Protocol      | Model Context Protocol (MCP)        | Universal tool access standard          | Open standard   |
| Persistent Memory  | PostgreSQL + pgvector               | Vectorized long-term agent memory       | PostgreSQL License|
| Communication      | Telegram Bot API                    | Primary human-agent interface           | Free            |
| Communication      | WhatsApp (via OpenClaw channel)     | Secondary human-agent interface         | Free            |
| Database           | PostgreSQL                          | Application data persistence            | Free            |
| Cache              | Redis                               | Ephemeral state, task queues            | BSD (Free)      |
| Container Runtime  | Docker / containerd                 | Agent container execution               | Apache 2.0 (Free)|
| GUI                | Next.js + Tailwind CSS              | Web dashboard for monitoring agents     | MIT (Free)      |
| Version Control    | Git + GitHub                        | Code storage, PR management             | Free            |

---

## 3. ARCHITECTURE OVERVIEW

```
┌─────────────────────────────────────────────────────────────────┐
│                     HUMAN ADMIN INTERFACE                        │
│              Telegram │ WhatsApp │ Web GUI (Next.js)             │
└─────────────┬───────────────────────────────────┬───────────────┘
              │                                   │
              ▼                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OPENCLAW GATEWAY                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────────┐  │
│  │ Telegram  │ │ WhatsApp │ │ Web Chat │ │ Session Manager   │  │
│  │ Channel   │ │ Channel  │ │ Channel  │ │ (Memory Router)   │  │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────────┘  │
└─────────────┬───────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│              NEMOCLAW GOVERNANCE LAYER                           │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐  │
│  │ OpenShell    │ │ Policy       │ │ Privacy Router         │  │
│  │ Sandbox      │ │ Engine       │ │ (Model Selection +     │  │
│  │ (seccomp,    │ │ (YAML-based  │ │  API Key Vaulting)     │  │
│  │  Landlock,   │ │  permissions)│ │                        │  │
│  │  namespaces) │ │              │ │ Ollama ←→ Groq ←→     │  │
│  └──────────────┘ └──────────────┘ │ Gemini ←→ Nemotron    │  │
│                                     └────────────────────────┘  │
└─────────────┬───────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MASTER MANAGER AGENT                          │
│              (High-reasoning: Llama 3.3 70B / Gemini)           │
│                                                                  │
│  Responsibilities:                                               │
│  • Task decomposition & delegation                               │
│  • Sub-agent lifecycle management                                │
│  • Quality assurance & result aggregation                        │
│  • HITL escalation & DND enforcement                             │
│  • 24/7 heartbeat monitoring                                     │
└──────┬──────────┬──────────┬──────────┬──────────┬──────────────┘
       │          │          │          │          │
       ▼          ▼          ▼          ▼          ▼
┌──────────┐┌──────────┐┌──────────┐┌──────────┐┌──────────────┐
│ARCHITECT ││ CODER    ││ DEVOPS   ││   QA     ││ RESEARCHER   │
│ Agent    ││ Agent    ││ Agent    ││ Agent    ││ Agent        │
│          ││          ││          ││          ││              │
│Qwen 2.5 ││Qwen 2.5  ││Nemotron  ││DeepSeek  ││Llama 3.3    │
│14B      ││Coder 14B ││Nano 30B  ││Coder    ││8B            │
└──────────┘└────┬─────┘└──────────┘└──────────┘└──────────────┘
                 │
                 ▼ (spawns if needed)
          ┌──────────────┐
          │ TOOL-MAKER   │
          │ Agent        │
          │ (builds MCP  │
          │  servers on  │
          │  demand)     │
          └──────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    MCP SERVER LAYER                              │
│  ┌───────────┐ ┌───────────┐ ┌──────────┐ ┌────────────────┐  │
│  │Kubernetes │ │ GitHub    │ │PostgreSQL│ │ Browser        │  │
│  │MCP Server │ │ MCP Server│ │MCP Server│ │ MCP Server     │  │
│  └───────────┘ └───────────┘ └──────────┘ └────────────────┘  │
│  ┌───────────┐ ┌───────────┐ ┌──────────┐ ┌────────────────┐  │
│  │Filesystem │ │ Docker    │ │ Redis    │ │ Custom (built  │  │
│  │MCP Server │ │ MCP Server│ │MCP Server│ │ by Tool-Maker) │  │
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
│                    KUBERNETES CLUSTER                            │
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
2. Install OpenClaw: `npm install -g openclaw` (or via NemoClaw installer)
3. Install NemoClaw: `curl -fsSL https://www.nvidia.com/nemoclaw.sh | bash`
4. Download local models via Ollama:
   - `ollama pull qwen2.5-coder:14b` (coding tasks)
   - `ollama pull llama3.3:70b` (reasoning, if hardware allows)
   - `ollama pull nemotron:mini` (agentic tasks)
   - `ollama pull nomic-embed-text` (embeddings for memory)
5. Configure OpenClaw gateway (`openclaw.json`)
6. Set up PostgreSQL + pgvector via Docker Compose
7. Verify basic agent can execute shell commands in sandbox

### Phase 2: Master Manager Agent (Week 2-3)
**Goal**: Create the central orchestrator with task decomposition

1. Write SOUL.md for Master Manager identity and rules
2. Write AGENTS.md with sub-agent delegation instructions
3. Configure model routing (Privacy Router):
   - Local Ollama for sub-agents (free, no limits)
   - Groq API for Master reasoning (free tier: ~30 req/min)
   - Gemini API for complex planning (free tier: 15 req/min)
4. Implement task decomposition logic via SOUL.md instructions
5. Test: Give Master a simple task → verify it creates a plan

### Phase 3: Specialist Agent Army (Week 3-4)
**Goal**: Create and test each specialist agent profile

1. Create agent profiles in `agents/` directory:
   - `architect/SOUL.md` — system design specialist
   - `coder/SOUL.md` — code generation specialist
   - `devops/SOUL.md` — infrastructure specialist
   - `qa/SOUL.md` — testing & security specialist
   - `researcher/SOUL.md` — web research specialist
2. Register agents: `openclaw agents add --name coder --model qwen2.5-coder:14b`
3. Configure sub-agent spawning in Master's config:
   - `maxSpawnDepth: 3`
   - `maxConcurrent: 5`
   - `maxChildrenPerAgent: 3`
4. Test A2A communication between Master → Coder → QA

### Phase 4: MCP Server Integration (Week 4-5)
**Goal**: Connect agents to external tools via MCP

1. Configure MCPorter (`config/mcporter.json`) with:
   - Kubernetes MCP Server (cluster management)
   - GitHub MCP Server (repo management, PRs)
   - PostgreSQL MCP Server (database operations)
   - Browser MCP Server (web automation)
   - Filesystem MCP Server (sandboxed file access)
2. Test each MCP server independently
3. Grant specific MCP access per agent via NemoClaw policies:
   - Coder → Filesystem + GitHub
   - DevOps → Kubernetes + Docker
   - Architect → PostgreSQL + GitHub
   - QA → GitHub + Filesystem
   - Researcher → Browser only

### Phase 5: Persistent Memory System (Week 5-6)
**Goal**: Replace Markdown memory with PostgreSQL + pgvector

1. Deploy PostgreSQL with pgvector extension
2. Create memory schema (embeddings table, agent_state, audit_log)
3. Configure OpenClaw memory backend: `memory.backend = "postgres"`
4. Implement semantic memory search for cross-agent knowledge sharing
5. Test: Agent recalls decisions made by other agents days prior

### Phase 6: Communication & HITL (Week 6-7)
**Goal**: Telegram/WhatsApp integration with DND protocol

1. Create Telegram bot via @BotFather
2. Add bot token to `openclaw.json` channels config
3. Bind Master Manager to Telegram: `openclaw agents bind --agent master --bind telegram`
4. Implement DND logic in USER.md:
   - Define DND schedules
   - Queue non-urgent notifications
   - Allow override for critical alerts only
5. Implement HITL approval flow:
   - Agent requests permission → Master pauses → Telegram alert → User approves/denies
6. (Optional) Configure WhatsApp as secondary channel

### Phase 7: 24/7 Continuous Operation (Week 7-8)
**Goal**: Implement heartbeat loop and self-healing

1. Write HEARTBEAT.md with scheduled routines:
   - Every 5 min: Check sub-agent health
   - Every 15 min: Commit uncommitted code
   - Every 1 hour: Summarize progress to memory
   - Every 6 hours: Run full system diagnostics
   - On failure: Auto-respawn failed agents (max 3 retries)
2. Set up system cron for heartbeat trigger
3. Implement auto-recovery: detect crashed agents, parse logs, respawn
4. Test: Kill an agent manually → verify auto-recovery

### Phase 8: Kubernetes Production Deployment (Week 8-10)
**Goal**: Move from Docker Compose to full K8s deployment

1. Create K8s namespace: `wow-ai-agents`
2. Deploy all components as K8s resources:
   - Master Manager: Deployment (always-on, 1 replica)
   - Specialist agents: Jobs/Deployments (ephemeral)
   - PostgreSQL: StatefulSet with PVC
   - Redis: Deployment
   - Ollama: Deployment with GPU affinity
3. Apply network policies (strict egress/ingress per agent)
4. Configure GPU time-slicing if GPU available
5. Set up Ingress for web GUI

### Phase 9: Web GUI Dashboard (Week 10-12)
**Goal**: Build monitoring and interaction interface

1. Scaffold Next.js app with Tailwind CSS
2. Implement pages:
   - `/dashboard` — Live agent status, task progress
   - `/agents` — Agent list, health, logs
   - `/tasks` — Task queue, history, results
   - `/chat` — Direct chat with Master Manager
   - `/settings` — DND config, API keys, model routing
   - `/preview` — Live preview of generated applications
3. Connect to PostgreSQL for real-time data
4. WebSocket for live agent status updates

### Phase 10: Self-Evolving Loop (Week 12+)
**Goal**: Agents that create new agents and tools on demand

1. Implement Tool-Maker agent profile
2. When a specialist lacks a tool:
   - Specialist → A2A → Master → Spawn Tool-Maker
   - Tool-Maker builds custom MCP server
   - Tool-Maker registers new MCP with MCPorter
   - Original specialist now has the new tool
3. Implement agent template system:
   - Master can create new SOUL.md files for new specialties
   - Register with OpenClaw dynamically
4. Implement learning loop:
   - After each completed project, extract patterns
   - Store as vector embeddings in pgvector
   - Future projects benefit from past solutions

---

## 5. MODEL ROUTING STRATEGY

| Task Type            | Model                    | Provider     | Cost  | Why                          |
|----------------------|--------------------------|--------------|-------|------------------------------|
| Master reasoning     | Llama 3.3 70B            | Groq         | Free  | Fast, high-quality reasoning |
| Complex planning     | Gemini 1.5 Pro           | Google       | Free  | Large context, strong planning|
| Code generation      | Qwen 2.5 Coder 14B      | Ollama       | Free  | Best open-source coder       |
| System design        | Qwen 2.5 14B             | Ollama       | Free  | Good general reasoning       |
| DevOps/Infra         | Nemotron Nano 30B        | Ollama       | Free  | Optimized for agentic tasks  |
| Testing/QA           | DeepSeek Coder           | Ollama       | Free  | Strong code analysis         |
| Quick research       | Llama 3.3 8B             | Ollama       | Free  | Fast, lightweight            |
| Embeddings           | nomic-embed-text         | Ollama       | Free  | High-quality embeddings      |
| Fallback reasoning   | DeepSeek R1 Distill 70B  | Groq         | Free  | When Llama is rate-limited   |

---

## 6. SECURITY MODEL

### NemoClaw Policy Layers

1. **Sandbox Isolation** (OpenShell)
   - seccomp filters restrict system calls
   - Landlock enforces unprivileged access control
   - Dedicated network namespaces per agent
   - Agents can only write to `/sandbox` and `/tmp`

2. **Network Policies** (Kubernetes + NemoClaw)
   - Default: deny all egress/ingress
   - Allowlist per agent type (see Phase 4)
   - No agent can access host network
   - Privacy Router intercepts all LLM API calls

3. **Credential Vaulting**
   - API keys stored in Kubernetes Secrets
   - Privacy Router injects keys at gateway level
   - Sub-agents NEVER see actual credentials
   - Time-limited tokens for external services

4. **HITL Security Gates**
   - Production deployments require human approval
   - Financial operations require human approval
   - New external API integrations require human approval
   - NemoClaw policy changes require human approval

---

## 7. FREE API KEYS NEEDED

| Service        | Get Key At                              | Free Tier Limits              |
|----------------|----------------------------------------|-------------------------------|
| Groq           | console.groq.com                       | ~30 req/min, daily cap        |
| Google Gemini  | aistudio.google.com                    | 15 req/min, 1M tokens/day    |
| Telegram Bot   | t.me/BotFather                         | Unlimited                     |
| GitHub         | github.com/settings/tokens             | 5000 req/hour                 |
| Ollama         | ollama.com (local install)             | Unlimited (local)             |

---

## 8. HARDWARE REQUIREMENTS

### Minimum (Development)
- CPU: 8 cores
- RAM: 16 GB (32 GB recommended)
- Storage: 100 GB SSD
- GPU: Optional (CPU inference works, just slower)

### Recommended (Production)
- CPU: 16+ cores
- RAM: 64 GB
- Storage: 500 GB NVMe SSD
- GPU: NVIDIA RTX 3090/4090 (24GB VRAM) or better
- Network: Stable internet for Groq/Gemini fallback

### Cloud Alternative (Free Tier)
- Oracle Cloud: 4 ARM cores, 24GB RAM (Always Free)
- Google Cloud: $300 credit for 90 days
- K3s instead of full Kubernetes for resource efficiency

---

## 9. PROJECT DIRECTORY STRUCTURE

```
wow_ai/
├── BLUEPRINT.md                          # This document
├── docker-compose.yml                    # Local development stack
├── .env.example                          # Environment variables template
│
├── openclaw/                             # OpenClaw configuration
│   ├── openclaw.json                     # Gateway configuration
│   ├── SOUL.md                           # Master Manager identity
│   ├── USER.md                           # Admin profile + DND rules
│   ├── AGENTS.md                         # Sub-agent delegation rules
│   ├── HEARTBEAT.md                      # 24/7 continuous operation loop
│   └── config/
│       └── mcporter.json                 # MCP server configuration
│
├── agents/                               # Specialist agent profiles
│   ├── architect/
│   │   └── SOUL.md
│   ├── coder/
│   │   └── SOUL.md
│   ├── devops/
│   │   └── SOUL.md
│   ├── qa/
│   │   └── SOUL.md
│   ├── researcher/
│   │   └── SOUL.md
│   └── tool-maker/
│       └── SOUL.md
│
├── nemoclaw/                             # NemoClaw security config
│   ├── nemoclaw.config.yml               # Main NemoClaw configuration
│   └── policies/
│       ├── network-egress.yml            # Network allowlists per agent
│       ├── agent-permissions.yml         # Agent capability restrictions
│       └── hitl-rules.yml                # Human-in-the-loop triggers
│
├── mcp-servers/                          # MCP server configurations
│   ├── kubernetes-mcp.json
│   ├── github-mcp.json
│   ├── postgres-mcp.json
│   └── browser-mcp.json
│
├── memory/                               # Database initialization
│   └── init.sql                          # PostgreSQL + pgvector schema
│
├── kubernetes/                           # K8s deployment manifests
│   ├── namespace.yml
│   ├── master-agent-deployment.yml
│   ├── postgres-statefulset.yml
│   ├── redis-deployment.yml
│   ├── ollama-deployment.yml
│   ├── network-policies.yml
│   └── gpu-time-slicing-config.yml
│
├── gui/                                  # Next.js web dashboard
│   └── (scaffolded in Phase 9)
│
└── scripts/                              # Setup and utility scripts
    ├── setup.sh                          # One-click full setup
    ├── install-models.sh                 # Download Ollama models
    └── start.sh                          # Start the orchestrator
```

---

## 10. CRITICAL WARNINGS AND LIMITATIONS

1. **NemoClaw is in ALPHA** (released March 16, 2026). Expect breaking changes.
   Not production-ready. Track: https://github.com/NVIDIA/NemoClaw

2. **Free API tiers have rate limits**. The system MUST implement intelligent
   fallback: Groq → Gemini → Ollama (local). Never let a rate limit crash the
   pipeline.

3. **GPU memory is the bottleneck**. Running 70B models locally requires 48GB+
   VRAM. For consumer hardware (24GB), use 14B models and offload reasoning to
   Groq/Gemini cloud APIs.

4. **Infinite agent spawning is dangerous**. Always enforce:
   - `maxSpawnDepth: 3` (not infinite)
   - `maxConcurrent: 5` (per agent)
   - `runTimeoutSeconds: 3600` (1 hour max per sub-agent)

5. **Context window exhaustion** is the #1 killer of long-running agents. The
   PostgreSQL + pgvector memory system is CRITICAL. Without it, agents enter
   infinite compaction loops and burn API credits.

6. **Security is non-negotiable**. Never run agents without NemoClaw sandbox.
   A rogue agent with host access can destroy your system.
