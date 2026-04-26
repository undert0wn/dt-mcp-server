---
name: dt-obs-events
description: Work with Dynatrace events including custom event ingestion, Davis events, business events, and event correlation. Covers send_event tool, event types, properties, correlation IDs, polling, and integration with logs, problems, and notebooks. Always load dt-dql-essentials/SKILL.md first.
---

# Dynatrace Events Skill (Observability)

## Overview

Dynatrace events are a core observability data type. This skill covers custom event ingestion (`send_event`), Davis events, business events, and correlation patterns.

**Event types in Dynatrace:**
- Custom events (ingested via Events API v2 — primary focus of `send-event.ts`)
- Davis events (`dt.davis.events`)
- Business events (`bizevents`)
- Problem events, security events, Kubernetes events, etc.

**When to use this skill:**
- Sending custom events (deployments, releases, alerts, business milestones)
- Working with event properties, entity selectors, and correlation IDs
- Correlating events with logs, problems, traces, and notebooks
- Tracking asynchronous event processing

**MANDATORY:** Always load `.agents/skills/dt-dql-essentials/SKILL.md` FIRST before any DQL or event work.

## Core Rules

- Start all investigations with **problems** (never broad log or event searches).
- Use unique `event.type` + `event.provider` for workflow isolation.
- Follow notebook Live State Reconciliation & Conflict Protection.
- Validate all DQL in exact context (standalone + notebook tile).
- Prefer JSON payloads and re-export/verify after any notebook change.

## Sending Events (`send_event` tool)

From `send-event.ts` patterns:

**Core fields:**
- `eventType` (e.g. `CUSTOM_INFO`, `CUSTOM_DEPLOYMENT`, `ERROR_EVENT`)
- `title` — required, human-readable name
- `entitySelector` — link to affected entities
- `properties` — key/value metadata (rich context)
- `startTime` / `endTime` — optional timestamps

**Example usage:**
```json
{
  "eventType": "CUSTOM_DEPLOYMENT",
  "title": "Version 2.1.0 deployed to production",
  "entitySelector": "type(SERVICE),entityId(SERVICE-123)",
  "properties": {
    "version": "2.1.0",
    "environment": "prod",
    "commit": "a1b2c3d"
  }
}
```

**Result handling:**
- Check `success`, `reportCount`, and per-event `correlationId` + `status`.
- Use correlation ID to track processing or correlate with logs/problems.
- Robust error handling for HTTP/SDK failures (status, body, stack).

## Integration Patterns

- **With problems:** Send events on problem resolution or RCA completion.
- **With notebooks:** Add event send results as markdown or DQL sections using full metadata (`type: dql`, `state.input.value`, `visualizationSettings`).
- **With logs:** Correlate custom events with log patterns via `event.type` and properties.
- **With Davis:** Trigger analyzers or annotate Davis problems with custom events.

## Best Practices

- Use meaningful `eventType` values and rich `properties`.
- Always include entity context when possible.
- Monitor correlation IDs in follow-up queries.
- Record generic lessons only in `/memories/repo/`.

## Related Skills

- `dt-dql-essentials` (mandatory)
- `dt-obs-logs`
- `dt-obs-problems`
- `dt-app-notebooks`
- `dt-obs-tracing`

Load this skill for any work involving custom events, event ingestion, correlation IDs, or sending notifications via events.