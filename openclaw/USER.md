# USER — Administrator Profile

## Identity
- **Name**: Admin (update with your actual name)
- **Role**: Platform administrator and sole human operator
- **Timezone**: IST (UTC+5:30) — update to your timezone

## Communication Preferences
- **Primary Channel**: Telegram
- **Secondary Channel**: WhatsApp (if configured)
- **Language**: English
- **Style**: Concise updates. No fluff. Lead with status, then details if needed.

## Do Not Disturb (DND) Schedule

### Regular Schedule
- **Deep Work**: 9:00 AM - 12:00 PM (no interruptions)
- **Sleep**: 11:00 PM - 7:00 AM (no interruptions)
- During DND: Queue all non-critical updates. Deliver summary when DND ends.

### DND Override — These ALWAYS interrupt:
- Kubernetes cluster is down or unresponsive
- Security breach detected
- Agent swarm has completely stalled (all agents failed)
- Critical data loss event
- Production system outage

### Extended DND
- If I say "do not disturb me for X days", operate fully autonomously
- Queue ALL updates including progress reports
- Continue solving problems without any human input
- Deliver comprehensive summary when DND expires
- Only interrupt for DND Override events listed above

## Human-in-the-Loop (HITL) Triggers
These events REQUIRE my explicit approval before proceeding:
1. Deploying any application to production
2. Creating or modifying cloud resources that cost money
3. Pushing code to main/master branch of any public repository
4. Making any financial transaction or purchase
5. Accessing systems not in the pre-approved MCP server list
6. Modifying NemoClaw security policies

## Approval Protocol
When requesting approval:
1. Send a Telegram message with: [ACTION REQUIRED] prefix
2. Clearly state what you want to do and why
3. List any risks or side effects
4. Wait for my explicit "approved" or "yes" response
5. If no response within 2 hours during active hours, send one reminder
6. If no response within 24 hours, queue the task and move to other work

## Project Preferences
- **Code Style**: Clean, well-documented, production-grade
- **Testing**: Minimum 80% code coverage before deployment
- **Git**: Feature branches, squash merges, conventional commits
- **Infrastructure**: Kubernetes-first, containerize everything
- **Database**: PostgreSQL preferred, Redis for caching only
- **Frontend**: Next.js + Tailwind CSS unless I specify otherwise
