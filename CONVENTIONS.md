# Dynatrace AI Workspace Conventions

This is the committed, single source of truth for agent behavior, workspace rules, and conventions. It is referenced by the governing briefing files, skills, ARCHITECTURE.md, and CHEATSHEET.md.

## Governing Reference
- **Primary files**: `.github/copilot-instructions.md` (for GitHub Copilot) and `CLAUDE.md` (for Claude). Both are auto-loaded at session start and kept in sync.
- They define tenant interaction via MCP/dtctl, context switching, Global Rule, prompts, skills, notebook guardrails, and agent initialization.

## Mandatory Agent Initialization Sequence
When starting a session or switching agents/tenants:
1. Read the governing briefing file + this `CONVENTIONS.md` + `ARCHITECTURE.md`.
2. **ALWAYS load `.agents/skills/dt-dql-essentials/SKILL.md` FIRST** (before any DQL).
3. Review the relevant **per-app folder** (`temp_<type>_files/`) and its `current-<type>.json` + index first.
4. Establish tenant context: `dtctl config current-context`, `dtctl auth whoami --plain`, and/or MCP `get_environment_info` / `find_entity_by_name`.
5. Follow the Global Rule and all conventions below strictly. No tenant-specific names/IDs in root source files.

This ensures identical behavior across agents.

## Workspace & Temp File Conventions
- `temp_dtctl_files/` is **only** for tenant-specific experiments (ignored by `.gitignore`; **never** commit tenant names, IDs, or specific artifacts to root).
- Use **per-app working context**: Organize by type (`temp_notebook_files/`, `temp_dashboard_files/`, `temp_workflow_files/`, etc.). Automatically create `temp_<newtype>_files/` (with current reference and index) when encountering a new resource type.
- `reference/official/` holds extracted patterns from the official MCP server for analysis (do not commit tenant-specific code; use for skill enhancement only).
- Agents **must** review the relevant per-app folder and `current-<type>.json` first using `list_dir` + `grep_search`.
- After experiments, clean up or archive. Root source must remain fully generic/standardized for any user/GitHub.

## Live State Reconciliation & Conflict Protection (Mandatory)
- Use per-app working context. When starting work on an app (or new type), refresh the `current-<type>.json` reference and per-folder index from the tenant (using stable ID).
- Before any modification, `dtctl apply`, or MCP update on a **specific resource**: re-export **only that resource's** live state (`dtctl get <resource> <id> -o json`, using ID not name).
- Run `scripts/validate-tenant-write.ps1` targeted at that single resource (it consults the per-app index for context).
- On detected user edits in the UI:
  - Provide a brief 1-2 sentence summary of what the user changed.
  - If edits are unrelated to the AI's pending changes → smart-merge user's edits into the local JSON, update the outgoing payload, and proceed.
  - Only stop and ask for explicit permission if the AI's changes would overwrite user edits. Offer options: stop, let AI overwrite, or do something else.
- Always keep a timestamped "before-user-edit" snapshot in the per-app folder with notes for easy revert.
- Never silently overwrite user work. Report ownership/access constraints.

## DQL Rules (All Agents)
- Use unique `event.type` + `event.provider` for workflow isolation.
- Dashboard tiles are stricter than notebooks/standalone: Avoid `summarize {..} by {..}` if "'by' isnt allowed here". Prefer `fields`/`fieldsAdd bin()`/`sort`/`limit`. Validate in *exact* target context (live tile, notebook section, MCP `execute_dql`, `dtctl query`).
- Start all investigations with **problems** (never broad log searches).
- Prefer JSON payloads; re-export and verify after apply.
- Record **generic** lessons only. `dt-dql-essentials/SKILL.md` + `references/dql/*` are canonical for syntax and pitfalls.

## Sync Checklist
After any change to governing files, this file, memory, or SKILL.md:
- Update both briefing files.
- Propagate generic lessons to this file and `/memories/repo/*`.
- Update `ARCHITECTURE.md`, `CHEATSHEET.md`, relevant skills, and run `scripts/validate-tenant-write.ps1`.
- Verify no tenant-specific references in root via grep.

## Agent Behavior
- Review files first (minimal corrections).
- Use `temp_dtctl_files/` for experiments only.
- Update this file when new patterns or lessons emerge.
- The memory system (`/memories/repo/`) holds AI-side notes; committed rules live here.

This ensures predictable, safe, file-aware behavior for any user or AI.