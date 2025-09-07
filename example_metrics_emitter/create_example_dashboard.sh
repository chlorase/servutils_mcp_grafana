#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
source "$SCRIPT_DIR/../bootstrap_helpers/load_env_first.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_JSON_FILE="$SCRIPT_DIR/provisioning/grafana/example-metrics-dashboard.json"
TIME_SERIES_FILE="$SCRIPT_DIR/provisioning/grafana/temp_example_metrics.prom"
EXAMPLE_METRICS_EMITTER_CONTAINERNAME="example_metrics_container"

# Generate example metrics
echo "Generating example metrics..."
NOW=$(date +%s)
START=$((NOW - 7200))  # 2 hours ago
> "$TIME_SERIES_FILE"

for TS in $(seq $START 1 $NOW); do
    EXAMPLE_VALUE=$((100 + RANDOM % 100))
    CPU_VALUE=$((50 + RANDOM % 50))
    MEM_VALUE=$((50 + RANDOM % 200))

    echo "exampleMetricA{instance=\"${EXAMPLE_METRICS_EMITTER_CONTAINERNAME}:${EXAMPLE_METRICS_EMITTER_PORT}\"} $EXAMPLE_VALUE $TS" >> "$TIME_SERIES_FILE"
    echo "example_cpu_usage{instance=\"${EXAMPLE_METRICS_EMITTER_CONTAINERNAME}:${EXAMPLE_METRICS_EMITTER_PORT}\"} $CPU_VALUE $TS" >> "$TIME_SERIES_FILE"
    echo "example_memory_usage{instance=\"${EXAMPLE_METRICS_EMITTER_CONTAINERNAME}:${EXAMPLE_METRICS_EMITTER_PORT}\"} $MEM_VALUE $TS" >> "$TIME_SERIES_FILE"
done

echo "Example metrics generated at $TIME_SERIES_FILE"

# Copy metrics to Prometheus container (ensure container is rebuilt if needed)
docker compose up -d --build "example_metrics_emitter_servicename"
docker cp "$TIME_SERIES_FILE" "${EXAMPLE_METRICS_EMITTER_CONTAINERNAME}":/tmp/temp_example_metrics.prom

# Create dashboard JSON
DASHBOARD_JSON=$(jq -n --arg title "Example Metrics Dashboard" '
{
  "dashboard": {
    "id": null,
    "uid": "example-dashboard",
    "title": $title,
    "timezone": "utc",
    "refresh": "30s",
    "panels": [],
    "schemaVersion": 37,
    "version": 0
  },
  "overwrite": true
}
')

# Single panel combining all metrics
PANEL=$(jq -n --argjson panelId 1 \
  --arg containerName "$EXAMPLE_METRICS_EMITTER_CONTAINERNAME" \
  --arg port "$EXAMPLE_METRICS_EMITTER_PORT" '
{
  "id": $panelId,
  "type": "timeseries",
  "title": "ExampleMetricA, Example CPU + Example mem",
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
  "datasource": "Prometheus_main"
}
')

DASHBOARD_JSON=$(echo "$DASHBOARD_JSON" | jq --argjson panel "$PANEL" '.dashboard.panels += [$panel]')

# Write updated JSON back to provisioning folder
echo "$DASHBOARD_JSON" | jq '.' > "$DASHBOARD_JSON_FILE"
echo "Updated dashboard JSON saved to $DASHBOARD_JSON_FILE"

# Upload dashboard to Grafana
GRAFANA_URL_ADMINACCESS="http://${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}@${GRAFANA_HOST:-localhost}:${GRAFANA_PORT}"

echo "Grafana URL for dashboard upload: $GRAFANA_URL"
echo "Grafana username: $GRAFANA_ADMIN_USER"
echo "Grafana password: $GRAFANA_ADMIN_PASSWORD"

echo "Uploading example dashboard to Grafana..."
RETRY_COUNT=0
MAX_RETRIES=10
while true; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$GRAFANA_URL_ADMINACCESS/api/dashboards/db" \
        -H "Content-Type: application/json" \
        -d @"$DASHBOARD_JSON_FILE" || true)

    if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 409 ]; then
        echo "Dashboard uploaded successfully (HTTP $HTTP_STATUS)"
        break
    else
        echo "Failed to upload dashboard (HTTP $HTTP_STATUS), retrying in 5s..."
        sleep 5
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            echo "Max retries reached. Dashboard not uploaded."
            break
        fi
    fi
done

# Open dashboard in browser
DASHBOARD_URL="$GRAFANA_URL/d/example-dashboard/example-metrics-dashboard?orgId=1&from=now-6m&to=now&timezone=utc&refresh=30s"
echo "Opening Grafana example dashboard: $DASHBOARD_URL"
case "$OSTYPE" in
  darwin*) /Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge "$DASHBOARD_URL" ;;
  linux*) xdg-open "$DASHBOARD_URL" >/dev/null 2>&1 || true ;;
  msys*|cygwin*) start "$DASHBOARD_URL" ;;
esac
