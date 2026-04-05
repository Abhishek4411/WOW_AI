# AGENTS — Sub-Agent Delegation Rules

## Overview
This document is injected into every sub-agent's context. It defines how agents
communicate, collaborate, and escalate issues.

## Agent Roster

| Agent       | Specialty                        | Model                   | MCP Access                      |
|-------------|----------------------------------|-------------------------|---------------------------------|
| architect   | System design, schemas, APIs     | openai/gpt-4.1-mini    | Filesystem                      |
| coder       | Code generation, debugging       | openai/gpt-4.1-mini    | Filesystem                      |
| devops      | K8s, Docker, CI/CD, infra        | openai/gpt-4.1-mini    | Filesystem                      |
| qa          | Testing, security, code review   | openai/gpt-4.1-mini    | Filesystem                      |
| researcher  | Web research, docs, API discovery| openai/gpt-4.1-mini    | Browser, web_search, web_fetch  |
| tool-maker  | Build MCP servers, custom tools  | openai/gpt-4.1-mini    | Filesystem                      |

> **NOTE — OpenClaw Bug #24852**: Sub-agents spawned via `sessions_spawn` do **NOT** read
> SOUL.md files at runtime. They only load AGENTS.md and TOOLS.md. All critical instructions
> (output path, quality rules, self-sufficiency rules) **MUST** be embedded directly in the
> `task` parameter when spawning.

> **Model fallback chain (all agents)**: `openai/gpt-4.1-mini` →
> `google/gemini-2.5-flash` → `groq/llama-3.3-70b-versatile`

## Communication Protocol (A2A)

### Sending Messages
Use the `sessions_spawn` tool from the master-manager to delegate tasks:
```json
{
  "task": "Detailed description with ALL instructions, output path, and quality requirements",
  "agentId": "coder",
  "mode": "run",
  "cleanup": "keep",
  "runtime": "subagent"
}
```

### Message Format
Always structure A2A messages as:
```
[FROM: your-agent-name]
[PRIORITY: low|medium|high|critical]
[TYPE: request|response|status|error]

<message body>
```

### Escalation Chain
1. If you cannot complete your task → message the Master Manager
2. If you need a tool that doesn't exist → request tool-maker via Master
3. If you encounter a security issue → IMMEDIATELY alert Master (priority: critical)
4. If you need human input → message Master with HITL request

## Collaboration Patterns

### Building a Web Application
```
Master → architect: "Design the system for [project]. Save DESIGN.md to C:/.../try_out_demos/{project}/"
architect → Master: Returns DESIGN.md (WAIT for completion — SEQUENTIAL)
Master verifies DESIGN.md exists before proceeding
Master → coder: "Implement based on DESIGN.md at C:/.../try_out_demos/{project}/DESIGN.md.
                  Create EVERY file in the manifest. Save all files to C:/.../try_out_demos/{project}/"
coder → Master: Returns implemented files (WAIT for completion)
Master verifies all manifest files exist
Master → qa: "Review all files in C:/.../try_out_demos/{project}/. Check for broken refs."
qa → Master: Returns test results
Master → Human: "[PROJECT COMPLETE] Files: <list> | Open: index.html in browser"
```

**CRITICAL**: WAIT for each agent to complete before spawning the next.
**DO NOT** spawn coder and devops at the same time — they depend on sequenced outputs.

### Fixing a Bug
```
Master → researcher: "Find documentation on: [error message]"
researcher → Master: Returns relevant docs/solutions (WAIT)
Master → coder: "Fix this bug using: [solution context]"
coder → Master: Returns fix (WAIT)
Master → qa: "Verify this fix: [code reference]"
qa → Master: Returns verification
```

### Building a Missing Tool
```
coder → Master: "I need a tool for [X] but no MCP server exists"
Master → tool-maker: "Build an MCP server for: [X]. Save to C:/.../try_out_demos/{project}/tools/"
tool-maker → Master: Returns new MCP server
Master → coder: "Tool is now available, continue your task"
```

## Rules for All Sub-Agents

1. **Stay in your lane**: Only perform tasks within your specialty
2. **Report progress**: Send final status to Master on completion
3. **Fail gracefully**: If stuck after 3 retries, message Master with error details — do NOT loop forever
4. **Self-sufficiency**: Install missing packages yourself (`pip install`, `npm install`). Use `web_search` and `web_fetch` to find solutions. NEVER ask the user for anything.
5. **Write to absolute path**: Write ALL output files to the absolute path specified in the task (typically `C:\Users\Dancy Naik\Documents\VS_Code_Test\wow_ai\try_out_demos\{project-name}\`). Create the directory with `mkdir -p` first. NEVER write to `/sandbox` or `/tmp` — those paths are not shared.
6. **No direct human contact**: All human communication goes through Master
7. **Time limit**: You have 1 hour max. If running long, checkpoint and report
8. **Spawn wisely**: Only create sub-agents if truly needed (max depth: 3)
