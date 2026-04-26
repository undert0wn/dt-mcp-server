# dt-mcp-server

**This is a modified and extended version of the [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) project**, with added MCP server integration, per-app smart reconciliation, Live State Conflict Protection, Windows-first documentation, and non-technical accessibility improvements.

**ELI5:** You are setting up an AI assistant that can answer questions about your Dynatrace environment in plain English. Type a question → get a real answer from live production data.

An AI-powered observability workspace for Dynatrace — combining GitHub Copilot or Claude AI, the Dynatrace MCP server, and the dynatrace-for-ai skills framework to accelerate incident triage, root cause analysis, and day-to-day observability workflows.

> **What this gives you:** Ask AI natural language questions about your Dynatrace environment and get accurate, production-aware answers — powered by verified domain knowledge, live API access, and pre-built investigation workflows.

---

## What's Inside

```
dynatrace-ai-workspace/
├── CHEATSHEET.md                 # Quick reference — 7 copy-paste DQL queries and critical rules
├── ARCHITECTURE.md               # How the workspace is built and how components connect
├── CONVENTIONS.md                # Single source of truth for all agent rules (reconciliation, DQL, Sync Checklist)
├── ELI5.md                       # Beginner-friendly 15-minute install guide
├── README.md                     # Setup guide and quick reference
├── CLAUDE.md                     # Auto-loaded session briefing for Claude Code
├── scripts/                      # Validation helpers (validate-tenant-write.ps1 runs before any dtctl tenant write)
├── skills-lock.json              # Locked skill versions
├── .gitignore
├── .github/
│   ├── copilot-instructions.md   # Auto-loaded session briefing for GitHub Copilot
│   └── prompts/                  # 7 investigation workflows
│       ├── health-check.prompt.md
│       ├── daily-standup.prompt.md
│       ├── daily-standup-notebook.prompt.md
│       ├── investigate-error.prompt.md
│       ├── troubleshoot-problem.prompt.md
│       ├── incident-response.prompt.md
│       └── performance-regression.prompt.md
├── .agents/skills/               # 13 Dynatrace domain skills
├── .claude/skills/               # Symlinks for Claude Code compatibility
├── .mcp.json                     # MCP server configuration for Copilot CLI
├── .vscode/
│   └── mcp.json                  # MCP server configuration for VS Code Copilot
└── demos/
    └── ai-observability-demo.md  # Demo script
```

| What | Why | Get It |
|---|---|---|
| [VS Code](https://code.visualstudio.com/) | Where you will work with the AI | Download from code.visualstudio.com |
| GitHub Copilot or Claude Code | The AI brain | Copilot: github.com/features/copilot (subscription) · Claude: claude.ai/code |
| [Node.js](https://nodejs.org/) v18+ | Powers the skill installer and MCP server | Download LTS version |
| [dtctl](https://github.com/dynatrace-oss/dtctl) | Lets you verify what the AI creates (notebooks, dashboards, etc.) | See Step 3 below |
| A Dynatrace environment | Live data source | Any `*.apps.dynatrace.com` tenant you have access to |

---

## Setup

> **Dynatrace employees & partners:** This workspace is pre-configured for the standard
> Dynatrace demo environment (`guu84124.apps.dynatrace.com`). No changes are
> required to run demos against the production demo tenant. Clone the repo,
> reload VS Code, and authenticate via your Dynatrace SSO when prompted.

### Choose Your Frontend

This workspace works with:
- **GitHub Copilot** in VS Code (requires subscription)
- **Claude Code** via web or desktop (requires Claude Pro or Team)

Select your setup path below. Both receive the same skills, prompts, and MCP server access.

**GitHub Copilot Path** → Follow Steps 1–6 below. Copilot loads `.github/copilot-instructions.md` automatically.

**Claude Code Path** → Follow Steps 1–5, then open `CLAUDE.md` in your Claude Code session. Claude loads `.claude/skills/` symlinks automatically.

### Recommended VS Code Extensions (GitHub Copilot users)

This workspace assumes **VS Code + GitHub Copilot**. Install these extensions from the VS Code marketplace before setup:

| Extension | Why |
|---|---|
| **GitHub Copilot Chat** | Main AI assistant for the workspace |
| **Dynatrace Apps** | Strato app development and dashboard component support |
| **Dynatrace Debugging Extension** | Debugging and testing in Dynatrace |
| **PowerShell** | Enables validation scripts (validate-tenant-write.ps1, refresh-context.ps1) |
| **GitLens** | Git history, blame, branch management — helpful for collaboration |

> **Claude Code users:** No extension installation needed — Claude Code runs in the web browser or desktop app.

### 1. Clone the workspace

```bash
git clone https://github.com/israel-salgado/dynatrace-ai-workspace.git
cd dynatrace-ai-workspace
```

Then open the folder in VS Code via **File → Open Folder**.

### 2. Update skills to latest

```bash
npx skills add dynatrace/dynatrace-for-ai
npx skills add dynatrace-oss/dtctl
```

> Run this command any time Dynatrace releases new skills.

### 3. Install and configure dtctl

`dtctl` is a command-line tool that lets you verify what the AI creates — like checking that a notebook it built actually exists in Dynatrace.

**Install dtctl first:**

```bash
# macOS / Linux — direct install (no package manager required)
curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash

# Windows — install via npm (requires Node.js v18+, recommended option)
npm install -g @dynatrace-oss/dtctl

# Verify installation across all platforms
dtctl --version
```

**Then authenticate to the demo tenant:**

```bash
# Local desktop (macOS/Windows/Linux with keyring): OAuth login
dtctl auth login --context demo.live \
  --environment "https://guu84124.apps.dynatrace.com"

# GitHub Codespaces / CI: token-based auth
dtctl config set-context demo.live \
  --environment "https://guu84124.apps.dynatrace.com" \
  --token-ref demo.live-token
dtctl config set-credentials demo.live-token --token <YOUR_PLATFORM_TOKEN>

# Verify
dtctl doctor
```

Create your platform token in Dynatrace: Identity & Access Management → Access Tokens → Generate new token → Platform token.

If you are in Codespaces and see `keyring probe failed` or `dbus-launch` errors, skip OAuth and use token-based auth.

### 4. Configure your sprint environment (optional)

The workspace is pre-configured with two MCP servers — the shared demo tenant
(`guu84124`) and a personal sprint tenant. The sprint entry is specific to the
original author and **must be updated** if you want to use your own sprint environment.

Complete all four steps below to fully configure your sprint tenant. Skipping
any step will result in Copilot referencing a server that doesn't exist or
authenticating against the wrong environment.

> If you only need the shared demo tenant (`guu84124`,`demo.live`), skip this section entirely —
> no sprint configuration is required for demos.

#### Sprint Tenant Checklist

**Step 4.A — Update `.vscode/mcp.json`**

Replace `<your-tenant-id>` with your personal sprint tenant ID (e.g. `abc12345`):

```json
{
  "servers": {
    "demo.live": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@dynatrace-oss/dynatrace-mcp-server@latest", "--stdio"],
      "env": {
        "DT_ENVIRONMENT": "https://guu84124.apps.dynatrace.com"
      }
    },
    "<your-tenant-id>-mcp": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@dynatrace-oss/dynatrace-mcp-server@latest", "--stdio"],
      "env": {
        "DT_ENVIRONMENT": "https://<your-tenant-id>.sprint.apps.dynatracelabs.com"
      }
    }
  }
}
```

**Step 4.B — Update `.mcp.json`**

`.mcp.json` is used by Copilot CLI and must stay in sync with `.vscode/mcp.json`.
Run this command to regenerate it from your updated `.vscode/mcp.json`:

```bash
jq "{mcpServers: .servers}" .vscode/mcp.json > .mcp.json
```

Verify the output looks correct before continuing:

```bash
cat .mcp.json
```

You should see both MCP server entries with your sprint tenant ID in place.

**Step 4.C — Update `.github/copilot-instructions.md` and `CLAUDE.md`**

Find the Environment table in both files and update the fallback server name and URL to match your tenant ID:

```
| **Fallback MCP server** | `<your-tenant-id>-mcp` → https://<your-tenant-id>.sprint.apps.dynatracelabs.com |
```

Both `.github/copilot-instructions.md` (GitHub Copilot) and `CLAUDE.md` (Claude Code) must be updated with your tenant ID or they will reference the original author's sprint environment.

**Step 4.D — Authenticate dtctl**

```bash
# Local desktop (macOS/Windows/Linux with keyring): OAuth login
dtctl auth login --context <your-tenant-id> \
  --environment "https://<your-tenant-id>.sprint.apps.dynatracelabs.com"

# GitHub Codespaces / CI: token-based auth
dtctl config set-context <your-tenant-id> \
  --environment "https://<your-tenant-id>.sprint.apps.dynatracelabs.com" \
  --token-ref <your-tenant-id>-token
dtctl config set-credentials <your-tenant-id>-token --token <YOUR_PLATFORM_TOKEN>
```

If OAuth fails with a keyring error (for example, `dbus-launch` not found), use the token-based method above.

### 5. Reload VS Code

Press `Cmd+Shift+P` → `Developer: Reload Window`

When you first use a prompt in Copilot Chat, a browser window will open for
Dynatrace SSO authentication. This is expected — complete the login and return
to VS Code. Subsequent sessions authenticate automatically.

### 6. Verify the connection

**GitHub Copilot users:** In Copilot Chat, type:

```
Using the demo.live server, list the top 5 services by request volume in the last hour
```

**Claude Code users:** In Claude Code, type the same query or copy it from the GitHub Copilot instruction above.

If you see a table of services with request counts — you are live and ready to demo.

## What Just Happened?

| Piece | What It Does | Analogy |
|---|---|---|
| Skills | Domain knowledge about Dynatrace | A textbook the AI reads before answering |
| MCP server | Live connection to your Dynatrace data | A phone line to production |
| Prompts | Pre-built investigation workflows | Recipes you follow step by step |
| dtctl | Terminal access for verification | An inspector who checks the AI's work |

## Your First Commands

| Type This | What It Does |
|---|---|
| `/health-check` | Is my service healthy right now? |
| `/incident-response` | What is currently broken in production? |
| `/daily-standup` | Give me a morning report across all services |

---

## Skills

Skills are domain knowledge files that teach Copilot how Dynatrace works — correct DQL syntax, field names, query patterns, and investigation workflows. They load automatically when relevant.

| Skill | What It Covers |
|---|---|
| `dt-dql-essentials` | DQL syntax, common pitfalls, query patterns — **load before any DQL** |
| `dt-obs-problems` | Davis Problems, root cause analysis, impact assessment |
| `dt-obs-logs` | Log queries, filtering, pattern analysis, error classification |
| `dt-obs-tracing` | Distributed traces, spans, failure detection, log correlation |
| `dt-obs-services` | RED metrics, SLA tracking, runtime-specific monitoring (Java, .NET, Node.js, Python, PHP, Go) |
| `dt-obs-hosts` | Host and process metrics, CPU, memory, disk, containers |
| `dt-obs-kubernetes` | Pods, workloads, nodes, labels, ingress, PVCs |
| `dt-obs-aws` | EC2, RDS, Lambda, ECS/EKS, VPC, cost optimization |
| `dt-obs-frontends` | RUM, Web Vitals, user sessions, mobile crashes |
| `dt-app-dashboards` | Dashboard JSON creation and modification |
| `dt-app-notebooks` | Notebook creation and analytics workflows |
| `dt-migration` | Classic entity DQL → Smartscape migration |
| `dtctl` | CLI commands for managing Dynatrace resources from the terminal |

---

## Prompts

Prompts are pre-built investigation workflows available as slash commands.

- **GitHub Copilot:** Type `/` in Copilot Chat (see `.github/prompts/`)
- **Claude Code:** Type `/` in Claude chat or paste prompt content from `.github/prompts/`

| Prompt | When to Use |
|---|---|
| `/health-check` | Routine service health — performance, problems, deployments, vulnerabilities |
| `/daily-standup` | Morning team report across multiple services with today vs yesterday comparison |
| `/daily-standup-notebook` | Standup report + Dynatrace notebook creation + dtctl verification |
| `/investigate-error` | "Something is wrong with this service" — error-focused investigation |
| `/troubleshoot-problem` | Deep 7-step investigation into a specific Dynatrace problem |
| `/incident-response` | Full production incident triage — all active problems, prioritized by business impact |
| `/performance-regression` | Did my deployment cause a slowdown? Before vs after comparison with trace analysis |

### Investigation Workflow

The prompts follow a structured drill-down pattern:

```
/health-check          →  flag concerns
/troubleshoot-problem  →  investigate a specific problem
/investigate-error     →  drill into error patterns
/incident-response     →  full triage when things are on fire
```

---

## Key Concepts

### Why Skills Matter

Copilot without skills will guess DQL syntax — and get it wrong. For example, it might use `event.status == "OPEN"` (doesn't exist) instead of `event.status == "ACTIVE"`, or `log.level` instead of `loglevel`. The skills encode the corrections for known failure modes before Copilot writes a single query.

### How MCP Works

The Dynatrace MCP server gives Copilot live API access to your environment. When you run `/health-check`, Copilot calls the MCP server to execute real DQL queries and return live data — not cached or synthetic results.

### The Investigation Rule

**Always start with problems, never with broad log searches.** Broad log queries without a problem context will hit Dynatrace's 500GB scan limit and return zero results. The prompts enforce this automatically.

### MCP Configuration Files

This workspace maintains two MCP configuration files that must be kept in sync:

| File | Used By |
|---|---|
| `.vscode/mcp.json` | VS Code GitHub Copilot and Claude Code |
| `.mcp.json` | GitHub Copilot CLI |

When adding or updating MCP servers, always update both files. Regenerate `.mcp.json` from `.vscode/mcp.json` using:

```bash
jq "{mcpServers: .servers}" .vscode/mcp.json > .mcp.json
```

---

## dtctl CLI

[dtctl](https://github.com/dynatrace-oss/dtctl) is a kubectl-style CLI for Dynatrace that complements this workspace — giving you terminal-level access to run DQL queries, manage workflows, verify notebooks, and more.

```bash
# macOS / Linux — direct install (no package manager required)
curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash

# Local desktop (macOS/Windows/Linux with keyring): OAuth login
dtctl auth login --context demo.live \
  --environment "https://guu84124.apps.dynatrace.com"

# GitHub Codespaces / CI: token-based auth
dtctl config set-context demo.live \
  --environment "https://guu84124.apps.dynatrace.com" \
  --token-ref demo.live-token
dtctl config set-credentials demo.live-token --token <YOUR_PLATFORM_TOKEN>

# Verify
dtctl doctor

# Example commands
dtctl get workflows
dtctl get notebooks
dtctl query 'fetch dt.davis.problems | filter event.status == "ACTIVE" | limit 5'
```

---

## Keeping Up to Date

```bash
# Update all skills to latest
npx skills add dynatrace/dynatrace-for-ai
npx skills add dynatrace-oss/dtctl

# Regenerate .mcp.json after any MCP server changes
jq "{mcpServers: .servers}" .vscode/mcp.json > .mcp.json

# Commit the updates
git add .
git commit -m "Update skills to latest"
git push
```

---

## Related Resources

- [ARCHITECTURE.md](./ARCHITECTURE.md) — How the workspace components connect
- [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — Skills and prompts source repo
- [dtctl](https://github.com/dynatrace-oss/dtctl) — Dynatrace CLI for humans and AI agents
- [Dynatrace MCP Server](https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server) — Official MCP server docs
- [Agent Skills spec](https://agentskills.io) — The open standard this workspace follows

---

## License

Skills and prompts sourced from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) and [dtctl](https://github.com/dynatrace-oss/dtctl) are Apache-2.0 licensed.
