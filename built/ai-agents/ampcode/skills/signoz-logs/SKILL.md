---
name: signoz-logs
description: |
  Query SigNoz logs via curl using SIGNOZ_URL and SIGNOZ_API_KEY environment variables.
  Use when asked to search logs, inspect recent errors, look up log lines, or query SigNoz safely.
  Read-only: only use the logs query endpoint, never write or mutate SigNoz resources.
compatibility: Requires SIGNOZ_URL and SIGNOZ_API_KEY to be set in the environment.
---

# SigNoz Logs

Use this skill for read-only SigNoz log queries.

## Rules

- Only query logs.
- Only use `POST $SIGNOZ_URL/api/v5/query_range`.
- Always send the API key in the `SIGNOZ-API-KEY` header.
- Never use write endpoints.
- Default to a small, safe time window and small result limit unless the user asks otherwise.
- Summarize results briefly; avoid dumping large raw payloads unless asked.

## Required environment

```bash
SIGNOZ_URL=https://your-workspace.signoz.cloud
SIGNOZ_API_KEY=...
```

Before querying, verify both env vars are set.

## Default query shape

Use a logs `builder_query` against `/api/v5/query_range`.

- Default window: last 15 minutes
- Default limit: 20
- Order: timestamp desc, id desc
- `requestType`: `raw`
- `signal`: `logs`

## Curl template

```bash
end_ms=$(python - <<'PY'
import time
print(int(time.time() * 1000))
PY
)
start_ms=$((end_ms - 15 * 60 * 1000))

curl -sS \
  -X POST \
  -H "SIGNOZ-API-KEY: $SIGNOZ_API_KEY" \
  -H 'Content-Type: application/json' \
  "$SIGNOZ_URL/api/v5/query_range" \
  --data @- <<JSON
{
  "schemaVersion": "v1",
  "start": $start_ms,
  "end": $end_ms,
  "requestType": "raw",
  "compositeQuery": {
    "queries": [
      {
        "type": "builder_query",
        "spec": {
          "name": "A",
          "signal": "logs",
          "disabled": false,
          "limit": 20,
          "offset": 0,
          "order": [
            {"key": {"name": "timestamp"}, "direction": "desc"},
            {"key": {"name": "id"}, "direction": "desc"}
          ],
          "having": {"expression": ""},
          "aggregations": [{"expression": "count()"}]
        }
      }
    ]
  },
  "formatOptions": {"formatTableResultForUI": false, "fillGaps": false}
}
JSON
```

## Search/filtering

When the user provides a search term or asks for specific errors, add a logs filter expression inside the query. Prefer the smallest filter that answers the question.

Common examples:

- text contains an error word
- service-specific logs
- severity-based filtering
- narrow time windows around an incident

If the exact filter syntax is unclear, start with an unfiltered recent query, inspect available fields in returned rows, then refine.

## Result handling

After querying:

1. Check HTTP status and top-level `status`
2. Extract `data.data.results[0].rows`
3. Summarize count and the most relevant rows
4. Include key fields when useful, such as timestamp, body, severity, service/resource attrs
5. If there are no rows, say so and suggest widening the time range or changing filters

## Safety

- Never create alerts, channels, dashboards, saved views, pipelines, or preferences from this skill.
- Never call non-log endpoints from this skill.
- Treat this skill as read-only even if the key appears to have broader access.

$ARGUMENTS
