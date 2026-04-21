# Dynatrace AI Workspace — Session Briefing

## Environment

| | |
|---|---|
| **Default MCP server** | `demo.live` → https://guu84124.apps.dynatrace.com |
| **Fallback MCP server** | `tdg63684-mcp` → https://tdg63684.sprint.apps.dynatracelabs.com |

To target a specific environment for a session:
```
"Use the tdg63684-mcp server for all queries in this session"
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

## Notebook Authoring Guardrails (Dynatrace)

When creating or updating Dynatrace notebooks:

- Prefer JSON payloads over YAML for `dtctl apply`.
- Always include explicit section metadata for DQL sections:
  - `type: dql`
  - `showTitle`
  - `state.input.timeframe`
  - `state.input.value`
  - `state.querySettings`
  - `state.visualization`
  - `visualizationSettings`
- Always include notebook `id` when updating an existing notebook.
- Never concatenate multiple notebook documents into one file.
- Avoid non-ASCII punctuation in DQL comments and query text.
- After apply, immediately run:
  1. `dtctl get notebook <id> -o yaml --plain`
  2. verify each DQL section has non-empty `state.input.value`
- If duplicate notebook names exist, prefer ID-based operations and report ownership/access constraints.