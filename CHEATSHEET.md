# Dynatrace Investigation Cheat Sheet

**Keep this handy while troubleshooting.** Copy-paste queries, customize as needed.

---

## 🚀 Quick Start Commands

| Task | Command |
|------|---------|
| **Check service health** | `/health-check [service-name]` |
| **Troubleshoot active problem** | `/troubleshoot-problem` |
| **Create investigation notebook** | Ask: *"Create a notebook for [issue]"* |

---

## 📋 Most Common DQL Queries

### 1. List Active Problems (ALWAYS START HERE)
```dql
fetch dt.davis.problems, from: now()-24h, to: now()
| filter not(dt.davis.is_duplicate) and event.status == "ACTIVE"
| sort event.start desc
```

### 2. Service RED Metrics (Last 1 Hour)
```dql
fetch spans, from: now()-1h, to: now()
| filter dt.service.name == "[SERVICE]" AND request.is_root_span == true
| summarize 
    requests = count(),
    errors = count(http.response.status_code >= 400),
    p99_latency_ms = percentile(duration, 99)
```

### 3. Find Slowest Endpoints
```dql
fetch spans, from: now()-1h, to: now()
| filter dt.service.name == "[SERVICE]" AND request.is_root_span == true
| summarize p99_duration = percentile(duration, 99), by: {request.endpoint}
| sort p99_duration desc
| limit 5
```

### 4. Get Error Rate by Status Code
```dql
fetch spans, from: now()-1h, to: now()
| filter dt.service.name == "[SERVICE]" AND request.is_root_span == true
| summarize total = count(), by: {http.response.status_code}
| sort total desc
```

### 5. Query Logs (SCOPED ONLY!)
```dql
fetch logs, from: [problem.start - 5min], to: [problem.end + 5min]
| filter dt.entity.service == "[SERVICE]"
| filter loglevel == "ERROR" OR loglevel == "WARN"
| sort timestamp desc
| limit 50
```

### 6. Trace a Failing Request
```dql
fetch spans, from: now()-30m, to: now()
| filter trace_id == "[TRACE-ID]"
| sort start_time asc
```

### 7. Correlate Logs by Trace ID
```dql
fetch logs, from: now()-30m, to: now()
| filter dt.trace_id == "[TRACE-ID]" OR trace_id == "[TRACE-ID]"
| sort timestamp asc
```

---

## ⚠️ Critical Rules

| Rule | Why | How |
|------|-----|-----|
| **Start with problems first** | Avoid 500GB log scans | Always use `@troubleshoot-problem` |
| **Scope log queries** | Hits 500GB limit without context | Add `dt.entity.service` + timeframe ±5min |
| **Use `{}` for multiple fields** | Syntax error if missing | `by: {field1, field2}` ✅ not `field1, field2` ❌ |
| **Use `in()` not arrays** | DQL syntax | `in(field, "a", "b")` ✅ not `["a", "b"]` ❌ |
| **Load `dt-dql-essentials`** | Ensure correct DQL syntax | Load before writing any DQL |
| **5-minute buffer** | Catch pre/post-incident logs | `from: [start - 5min], to: [end + 5min]` |

---

## 🔧 Common Customizations

| Need | Adjustment |
|------|------------|
| Different timeframe | Change `now()-1h` → `now()-24h` or `now()-7d` |
| Multiple services | `filter in(dt.service.name, "[SVC1]", "[SVC2]")` |
| Production only | `filter dt.environment == "prod"` |
| Group by host | Add `by: {dt.host.name}` to summarize |
| Case-insensitive search | `contains(lower(content), "timeout")` |
| Specific error type | `filter contains(lower(content), "connection refused")` |

---

## 📊 Data Objects Quick Reference

| Object | Purpose | Use Case |
|--------|---------|----------|
| `fetch spans` | Distributed tracing | Request flows, latency, errors |
| `fetch logs` | Log events | Debug, correlate with errors |
| `fetch dt.davis.problems` | Davis problems | Active incidents, RCA |
| `fetch bizevents` | Business metrics | Custom events, user actions |
| `timeseries` | Metrics over time | CPU, memory, throughput trends |

---

## 🎯 Standard Investigation Workflow (7 Steps)

**Step 1: List Active Problems**
```dql
fetch dt.davis.problems, from: now()-24h, to: now()
| filter not(dt.davis.is_duplicate) and event.status == "ACTIVE"
| sort event.start desc
```
→ Extract problem ID, start time, end time, affected service

**Step 2: Scope Investigation**
- Problem context: `[problemId, startTime, endTime, affected_entities]`

**Step 3: Query Logs (Scoped ±5 min)**
```dql
fetch logs, from: [startTime - 5min], to: [endTime + 5min]
| filter dt.entity.service == "[SERVICE]"
| filter loglevel == "ERROR" OR loglevel == "WARN"
| sort timestamp desc
```
→ Extract trace ID, error pattern, affected component

**Step 4: Classify Errors**
- Categories: app error, infrastructure, auth, external, benign

**Step 5: Trace Analysis**
```dql
fetch spans | filter trace_id == "[TRACE-ID]" | sort start_time asc
```
→ Answer: What call failed? Which service? Why?

**Step 6: Summarize Findings**
- Root cause hypothesis
- Affected services / users
- Next steps (fix or escalate)

---

## 🚨 Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Unknown data object` | Typo in object | Check: `fetch logs` vs `fetch events` |
| `Field not found` | Wrong field name | Use correct case: `dt.entity.service` ✅ |
| `Syntax error at position X` | Missing `{}` in grouping | Use `by: {field1, field2}` |
| `Query scanned 500GB+` | Too broad scope | Reduce timeframe ±2min + add filters |
| Empty results | Correct query, no data | Extend timeframe or verify filters |
| No spans in trace | Trace not indexed | Fall back to log-based lookup by `dt.trace_id` |

---

## 💡 Pro Tips

1. **Test with `limit 1` first** — Verify query structure before full results
2. **Filter early** — `filter A | filter B` is faster than broad query
3. **Parallel queries** — Batch independent queries together (saves time)
4. **Case matters** — `dt.service.name` not `dt.SERVICE.name`
5. **Include 5-min buffer** — `from: [startTime - 5min], to: [endTime + 5min]`
6. **Never skip problem context** — Always scope before querying logs

---

## 📞 When to Load Skills

| Situation | Load Skill |
|-----------|-----------|
| Writing DQL queries | `dt-dql-essentials` |
| Service performance | `dt-obs-services` |
| Problem RCA | `dt-obs-problems` |
| Request tracing | `dt-obs-tracing` |
| Searching logs | `dt-obs-logs` |
| Frontend/RUM issues | `dt-obs-frontends` |
| Kubernetes/pod issues | `dt-obs-kubernetes` |
| Infrastructure/host issues | `dt-obs-hosts` |
| AWS infrastructure | `dt-obs-aws` |
| Terminal/CLI workflows | `dtctl` |

---

## 🔗 Session Management

**Switch MCP Server:**
```
"For all queries, use the tdg63684-mcp server"
```

**Workspace Conventions**: See governing briefing (`copilot-instructions.md` or `CLAUDE.md`) + `CONVENTIONS.md` (single source of truth for temp organization, Live State Reconciliation & Conflict Protection, review mandates, Sync Checklist, and redundancy reduction). 
- Always review `temp_dtctl_files/**` first (`list_dir` + `grep_search`).
- For notebooks/dashboards: re-export live state before any AI change; stop and ask on conflict with manual edits.
- Organize experiments strictly by subfolder; keep root generic.
- Follow mandatory initialization sequence on every agent switch.

**Parallel Queries:**
Multiple unrelated queries in same prompt = faster than sequential

**Trace Fallback:**
If trace has no spans, use log-based lookup:
```dql
fetch logs | filter dt.trace_id == "[TRACE-ID]" OR trace_id == "[TRACE-ID]"
```

**Viewport Overflow:**
If hitting 500GB limit:
1. Reduce timeframe (±2 min instead of ±5 min)
2. Add more filters (service, host, error type)
3. Ask user for narrower problem context

---

## ✅ Pre-Query Checklist

- [ ] Load `dt-dql-essentials` skill
- [ ] Start with `@troubleshoot-problem` or problem context
- [ ] Have problem timeframe (start, end)
- [ ] Know affected service/entity
- [ ] Plan ±5 min buffer for log queries
- [ ] Use correct entity selectors (`dt.entity.*`)
- [ ] Use `by: {field1, field2}` for multiple groupings
- [ ] Check viewport (500GB limit)

---

**Last Updated:** April 10, 2026 | **Default MCP:** demo.live | **Status:** Production
