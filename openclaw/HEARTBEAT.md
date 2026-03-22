# HEARTBEAT — 24/7 Continuous Operation Loop

## Purpose
This file defines the Master Manager's autonomous operation cycle.
The heartbeat runs continuously, ensuring the agent swarm never stalls.

## Heartbeat Schedule

### Every 5 Minutes — Agent Health Check
```
ROUTINE: health-check
ACTIONS:
  - Check status of all active sub-agents
  - Verify no agent has exceeded its timeout
  - If agent is unresponsive for > 2 checks, mark as failed
  - If agent failed, attempt respawn (max 3 retries)
  - If respawn fails 3x, escalate to human via HITL
  - Log health status to PostgreSQL
```

### Every 15 Minutes — Work Checkpoint
```
ROUTINE: work-checkpoint
ACTIONS:
  - Query all active agents for current progress
  - Save progress snapshots to PostgreSQL memory
  - If any agent is stuck (no progress in 2 consecutive checks):
    - Analyze the blocker
    - Attempt to provide guidance via A2A message
    - If still stuck after 1 more cycle, respawn with fresh context
  - Commit any uncommitted code in agent workspaces
```

### Every 1 Hour — Progress Summary
```
ROUTINE: progress-summary
ACTIONS:
  - Aggregate all agent activities from the past hour
  - Generate concise progress report
  - If NOT in DND mode:
    - Send summary to human via Telegram
  - If IN DND mode:
    - Queue summary for delivery when DND ends
  - Store summary in PostgreSQL for audit trail
  - Evaluate if project is on track or needs replanning
```

### Every 6 Hours — System Diagnostics
```
ROUTINE: system-diagnostics
ACTIONS:
  - Check Kubernetes cluster health (via K8s MCP)
  - Verify PostgreSQL database connectivity and disk usage
  - Verify Redis connectivity
  - Check Ollama model availability
  - Test Groq/Gemini API connectivity (single ping)
  - Check disk space on host
  - If any system issue found:
    - Attempt auto-fix if possible
    - Escalate to human if critical
  - Run memory compaction (prune old, irrelevant embeddings)
  - Log diagnostics report
```

### Every 24 Hours — Daily Report
```
ROUTINE: daily-report
ACTIONS:
  - Compile comprehensive daily summary:
    - Tasks completed
    - Tasks in progress
    - Tasks blocked
    - Agents spawned/terminated
    - Errors encountered and resolutions
    - Resource usage (CPU, memory, disk, API calls)
  - Extract learned patterns from the day's work
  - Store patterns as new memory embeddings for future use
  - If NOT in DND mode: send daily report to human
  - If IN DND mode: queue for delivery
  - Clean up completed/stale agent pods in K8s
```

## Auto-Recovery Protocol

### On Agent Crash
```
1. Detect crash via health check (agent unresponsive)
2. Retrieve agent's last checkpoint from PostgreSQL
3. Parse exit logs for root cause
4. Respawn agent with:
   - Same task context
   - Last checkpoint as starting point
   - Additional context: "Previous attempt failed because: [reason]"
5. If same crash occurs 3 times:
   - Try with a different model (fallback chain)
   - If still failing: escalate to human
```

### On API Rate Limit
```
1. Detect 429 status from Groq/Gemini
2. Immediately switch to next provider in fallback chain:
   Groq → Gemini → Ollama (local, no limits)
3. Queue pending requests for rate-limited provider
4. Retry rate-limited provider after cooldown period
5. Log rate limit event for optimization
```

### On Database Connection Loss
```
1. Detect connection failure
2. Pause all agents (prevent data loss)
3. Attempt reconnection (max 5 retries, exponential backoff)
4. If reconnected: resume all agents
5. If failed: escalate to human (CRITICAL)
```

## DND Queue Management
```
When DND is active:
  - All non-critical messages → append to dnd_queue table
  - Tag each message with: timestamp, priority, source_agent, project
  - When DND expires:
    1. Sort queue by priority (critical > high > medium > low)
    2. Compile into structured summary
    3. Send to human via Telegram
    4. Clear the queue
```
