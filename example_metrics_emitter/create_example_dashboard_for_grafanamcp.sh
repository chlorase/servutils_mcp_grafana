#!/bin/bash
# create_example_dashboard_for_grafanamcp.sh: Create a dashboard with example metrics
set -euo pipefail
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap_helpers/load_env_first.sh"
source "$SCRIPT_DIR/../${ENV_GRAFANAMCP_FILENAME}"

EXAMPLE_METRICS_EMITTER_CONTAINERNAME="example_metrics_container"
# Dashboard metadata
DASHBOARD_TITLE="MCP Metrics Dashboard"
DASHBOARD_UID="mcp-metrics-dashboard"
DASHBOARD_REFRESH="30s"
DATASOURCE_NAME="Prometheus_main"

# Single panel combining all metrics
PANEL=$(jq -n --argjson panelId 1 \
  --arg containerName "$EXAMPLE_METRICS_EMITTER_CONTAINERNAME" \
  --arg port "$EXAMPLE_METRICS_EMITTER_PORT" '
{
  "id": $panelId,
  "type": "timeseries",
  "title": "ExampleMetricA, CPU, Mem",
  "gridPos": { "h": 8, "w": 24, "x": 0, "y": 0 },
  "fieldConfig": {
    "defaults": { "unit": "none" },
    "overrides": [
      {
        "matcher": { "id": "byName", "options": "Mem" },
        "properties": [
          { "id": "custom.axisPlacement", "value": "right" }
        ]
      }
    ]
  },
  "options": { "legend": { "displayMode": "list" }, "tooltip": { "mode": "single" } },
  "targets": [
    { "expr": "exampleMetricA{instance=\"\($containerName):\($port)\"}", "legendFormat": "ExampleMetricA", "refId": "A" },
    { "expr": "example_cpu_usage{instance=\"\($containerName):\($port)\"}", "legendFormat": "CPU", "refId": "B" },
    { "expr": "example_memory_usage{instance=\"\($containerName):\($port)\"}", "legendFormat": "Mem", "refId": "C" }
  ],
  "datasource": "'"$DATASOURCE_NAME"'"
}
')

# Assemble dashboard JSON
DASHBOARD_JSON=$(jq -n \
  --arg title "$DASHBOARD_TITLE" \
  --arg uid "$DASHBOARD_UID" \
  --arg refresh "$DASHBOARD_REFRESH" \
  --argjson panel "$PANEL" '
{
  "dashboard": {
    "id": null,
    "uid": $uid,
    "title": $title,
    "timezone": "utc",
    "refresh": $refresh,
    "panels": [$panel],
    "schemaVersion": 37,
    "version": 0
  },
  "overwrite": true
}
')

# Push dashboard via API
echo "Creating dashboard via Grafana API..."
cmd=(curl -s -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRAFANA_SERVICE_ACCOUNT_TOKEN" \
  -d "$DASHBOARD_JSON" \
  "$GRAFANA_URL/api/dashboards/db")
echo "Running command: ${cmd[@]}"
RESPONSE=$("${cmd[@]}")
echo "Dashboard creation response: $RESPONSE"
