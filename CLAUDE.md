# Dynatrace AI Workspace — Session Briefing

## Governing Reference for Tenant Interaction (Agent-Agnostic)

**The single governing reference file for GitHub Copilot is `.github/copilot-instructions.md` (auto-loaded at session start). For Claude it is `CLAUDE.md`. Both are kept in sync.**

This file (and its counterpart) defines **exactly** how any agent interacts with a Dynatrace tenant:
- Default/fallback MCP servers (the live bridge to the tenant via the Model Context Protocol).
- How to switch tenants/contexts when changing agents.
- Global rule, available prompts, skills, notebook guardrails, and agent-agnostic DQL rules.

**When switching agents or tenants, ALWAYS start the session with an explicit context statement** such as:
```
"Use the tdg63684-mcp server for all queries in this session"
```
(or the equivalent for the target MCP server defined in `.mcp.json`).

**Mandatory agent initialization sequence** (review files first, then run/validate):
1. Read this file + `copilot-instructions.md` + `CONVENTIONS.md` + `ARCHITECTURE.md`.
2. **ALWAYS load `.agents/skills/dt-dql-essentials/SKILL.md` FIRST** (before any DQL).
3. Review **all** relevant workspace files (`current-notebook.json`, `temp_dtctl_files/**`, `clean-dashboard.json`, skills).
4. For dtctl/MCP tenant context: Run `dtctl config current-context`, `dtctl auth whoami --plain`, and/or MCP `get_environment_info` / `find_entity_by_name`.
5. Follow the Global Rule and rules in `CONVENTIONS.md` strictly. No tenant-specific names/IDs in root source files.

See `CONVENTIONS.md` for full Workspace & Temp File Conventions, Live State Reconciliation & Conflict Protection, DQL rules, and Sync Checklist.

This ensures identical, predictable behavior across agent switches.

See `CONVENTIONS.md` for full details on Workspace & Temp File Conventions, Live State Reconciliation & Conflict Protection, DQL rules, Sync Checklist, and agent behavior.

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

17 domain knowledge skills are installed in `.agents/skills/`. They load automatically when relevant — no manual loading required.

## Notebook (and App) Update Contract

This workspace follows a per-app smart reconciliation contract (full details in `CONVENTIONS.md`):

- Use per-app folders (`temp_<type>_files/`) with `current-<type>.json` and index. Auto-create for new types (e.g. business_flow).
- Target **only the specific app** being modified. Refresh current reference when starting work on a type.
- On user UI edits: give 1-2 sentence summary. Smart-merge unrelated changes into local JSON. Stop and ask (with options: stop/let AI overwrite/do something else) only on conflicting overwrites.
- Keep timestamped before-user-edit snapshot for revert.
- Prefer JSON payloads, ID-based operations, explicit DQL metadata, re-export + verify after apply.

**Agent-Agnostic DQL Rules** (apply to ALL agents — see also copilot-instructions.md):
- **ALWAYS load dt-dql-essentials/SKILL.md FIRST**. Review the relevant per-app folder and current reference first.
- Unique `event.type` + provider for isolation. Validate in exact context (dashboard tiles require `fields`/`bin()`/`sort`/`limit` fallback).
- Prefer JSON, start with problems, record generic lessons only. Ensures identical safe behavior. Root remains standardized; per-app temp folders hold context.

Failure mode reminders:
- Duplicate names can point to different ownership.
- Mixed encoding and non-ASCII punctuation can create parser issues.
- Missing `type: dql` can produce empty or non-functional query sections.