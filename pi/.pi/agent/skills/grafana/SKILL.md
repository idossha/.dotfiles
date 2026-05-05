---
name: grafana
description: Grafana dashboard and observability patterns for metrics, logs, and alerts. Use when creating or reviewing Grafana dashboards, Prometheus/PromQL panels, SLO views, alerting layouts, or production monitoring UX.
---

# Grafana

Use this skill when the task involves Grafana dashboards, panel JSON, PromQL, observability layout, or alert-oriented visualization.

## Default approach

1. Identify the audience: operator, developer, on-call, product, or exec.
2. Identify the signal type: metrics, logs, traces, uptime, or business KPIs.
3. Design top-down:
   - **Row 1:** status / burn / traffic summary
   - **Row 2:** core time series
   - **Row 3+:** breakdowns, saturation, errors, logs, drilldowns
4. Prefer a few trustworthy panels over dense wall-of-charts dashboards.

## Core frameworks

### RED for services
- **Rate** — throughput / requests
- **Errors** — failure rate or count
- **Duration** — latency, ideally p50/p95/p99

### USE for infrastructure
- **Utilization** — how busy
- **Saturation** — queues / waiting / pressure
- **Errors** — failures / drops / OOM / restarts

## Good dashboard habits

- Use meaningful titles: `API error rate`, not `Panel 12`.
- Show units everywhere.
- Use templating variables sparingly; too many variables make dashboards hard to read.
- Put thresholds on stat panels only when the thresholds are operationally meaningful.
- Prefer derived service-level signals over raw host counters when monitoring application health.
- For latency, use percentiles from histograms, not averages.
- For error rate, divide errors by requests over the same window.

## PromQL patterns

```promql
sum(rate(http_requests_total[5m])) by (service)
```

```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

```promql
histogram_quantile(
  0.95,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
)
```

```promql
100 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100
```

## Panel selection

- **Stat:** current value, budget burn, uptime, queue depth
- **Time series:** trends over time
- **Table:** current per-service/per-host status
- **Heatmap:** latency distributions, histogram buckets
- **Logs panel:** correlated error investigation

## Don't

- Don’t mix unrelated systems in one dashboard unless the user explicitly wants a cross-system view.
- Don’t use averages for tail-latency questions.
- Don’t color everything red/yellow/green without real thresholds.
- Don’t create 30 near-duplicate panels when a variable or legend split solves it.
- Don’t hide legend labels or units.

## When helping with Grafana code/config

- If the user has dashboard JSON or provisioning files, edit those rather than describing dashboards abstractly.
- Preserve datasource UIDs, panel IDs, and variable names unless changing them is intentional.
- Call out Grafana-version-specific schema assumptions.
- When reviewing a dashboard, report: audience, missing signals, clutter, and concrete panel/query fixes.
