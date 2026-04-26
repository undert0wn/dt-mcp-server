# Dynatrace AI Workspace — Session Briefing

## Governing Reference for Tenant Interaction (Agent-Agnostic)

**The single governing reference file for GitHub Copilot is `.github/copilot-instructions.md` (auto-loaded at session start). For Claude it is `CLAUDE.md`. Both are kept in sync.**

This file (and its counterpart) defines **exactly** how any agent interacts with a Dynatrace tenant:
- Default/fallback MCP servers (the live bridge to the tenant via the Model Context Protocol).
- How to switch tenants/contexts when changing agents.
- Global rule, available prompts, skills, notebook guardrails, and agent-agnostic DQL rules.

**When switching agents or tenants, ALWAYS start the session with an explicit context statement** such as:
```
"Use the liit-mcp server for all queries in this session"
```
(or the equivalent for the target MCP server defined in `.mcp.json`).

**Mandatory agent initialization sequence** (review files first, then run/validate):
1. Read this file + `CLAUDE.md` + `ARCHITECTURE.md` + `CONVENTIONS.md`.
2. **ALWAYS load `.agents/skills/dt-dql-essentials/SKILL.md` FIRST** (before any DQL).
3. Review **all** relevant workspace files (`current-notebook.json`, `temp_dtctl_files/**`, `clean-dashboard.json`, skills, `memories/repo/*`). Use temp/ only for experiments.
4. For dtctl/MCP tenant context: Run `dtctl config current-context`, `dtctl auth whoami --plain`, and/or MCP `get_environment_info` / `find_entity_by_name`.
5. Follow the Global Rule and all Agent-Agnostic DQL Rules below strictly. No tenant-specific names/IDs in root source files.

This ensures identical, predictable behavior across agent switches.

See `CONVENTIONS.md` for full details on Workspace & Temp File Conventions, Live State Reconciliation & Conflict Protection, DQL rules, Sync Checklist, and agent behavior.

## Environment

| | |
|---|---|
| **Default MCP server** | `demo.live` → https://guu84124.apps.dynatrace.com |
| **Fallback MCP server** | `YOURTENANTID-mcp` → https://YOURTENANTID.apps.dynatraces.com |

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

- **Live State Reconciliation & Conflict Protection (Mandatory)**: Before any modification, `dtctl apply`, or MCP update, always re-export the current live state from the tenant first (`dtctl get notebook <id> -o json` or equivalent, using ID not name). Update the local reference file (`current-notebook.json` etc.). If a conflict with manual user edits is detected (version mismatch, changed sections, ownership differences), stop immediately, clearly report the conflict, and ask for explicit user permission before proceeding or overwriting. Never silently overwrite user work.
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

## Notebook (and App) Update Contract

This workspace follows a per-app smart reconciliation contract (full details in `CONVENTIONS.md`):

- Use per-app folders (`temp_<type>_files/`) with `current-<type>.json` and index. Auto-create for new types (e.g. business_flow).
- Target **only the specific app** being modified. Refresh current reference when starting work on a type.
- On user UI edits: give 1-2 sentence summary. Smart-merge unrelated changes into local JSON. Stop and ask (with options: stop/let AI overwrite/do something else) only on conflicting overwrites.
- Keep timestamped before-user-edit snapshot for revert.
- Prefer JSON payloads, ID-based operations, explicit DQL metadata, re-export + verify after apply.

**Agent-Agnostic DQL Rules** (apply to ALL agents for consistency):
- **ALWAYS load `.agents/skills/dt-dql-essentials/SKILL.md` FIRST** before generating any DQL (including dashboards/notebooks).
- Review **all** relevant workspace files first (`current-notebook.json`, `temp_dtctl_files/*`, `clean-dashboard.json`, skills, memories/repo/*).
- Use **unique `event.type`** + `event.provider` filter for workflow isolation to prevent data mixing.
- Validate **EVERY** query in the *exact target context* (standalone `dtctl query`/MCP `execute_dql` **AND** live dashboard tile/notebook section). Dashboard tiles are stricter — prefer `fields`/`fieldsAdd bin()`/`sort`/`limit` over `summarize {..} by {..}` if "'by' isnt allowed here" appears.
- Start all investigations with **problems** (never broad log searches). Record **generic** lessons in `/memories/repo/` only (no tenant specifics; temp files for experiments only). 
- Prefer JSON payloads; re-export/verify post-apply. This ensures identical safe, file-aware behavior across agents (varying only in speed). Root source must remain standardized for any user/GitHub.
