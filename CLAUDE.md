# Dynatrace AI Workspace — Session Briefing

## Environment

| | |
|---|---|
| **Default MCP server** | `demo.live` → https://guu84124.apps.dynatrace.com |
| **Fallback MCP server** | `bon05374-mcp` → https://bon05374.sprint.apps.dynatracelabs.com |

To target a specific environment for a session:
```
"Use the bon05374-mcp server for all queries in this session"
```

## Global Rule

**Always start with problems — never run broad log searches.**
Broad queries without problem context hit Dynatrace's 500GB scan limit and return zero results.
All investigation workflows enforce this automatically.

## Prompts

Type `/` in Copilot Chat to access these slash commands:

| Prompt | When to use |
|---|---|
| `/health-check` | Routine service health — metrics, problems, deployments, vulnerabilities |
| `/daily-standup` | Morning report across services — today vs yesterday comparison |
| `/daily-standup-notebook` | Standup report + Dynatrace notebook creation + dtctl verification |
| `/investigate-error` | Error-focused investigation from a service name |
| `/troubleshoot-problem` | Deep 7-step investigation into a specific Dynatrace problem |
| `/incident-response` | Full triage of all active problems during a live incident |
| `/performance-regression` | Before vs after deployment comparison with rollback/hotfix recommendation |

## Skills

13 domain knowledge skills are installed in `.agents/skills/`. They load automatically when relevant — no manual loading required.

## Notebook Update Contract

This workspace follows a strict notebook update contract:

1. Resolve target notebook by ID first, not name.
2. Export current state before modification.
3. Apply changes using JSON payload format.
4. Keep one notebook document per file.
5. Use explicit DQL section metadata in every query section.
6. Re-export and verify:
   - section count
   - section types
   - non-empty `state.input.value` for each DQL section
7. If delete fails with access denied, report and stop destructive retries.

Failure mode reminders:
- Duplicate names can point to different ownership.
- Mixed encoding and non-ASCII punctuation can create parser issues.
- Missing `type: dql` can produce empty or non-functional query sections.