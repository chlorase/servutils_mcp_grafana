#!/usr/bin/env bash
# create_example_dashboard.sh. 
# This script generates *initial* example metrics, creates a dashboard JSON file, and uploads it to Grafana.
# NOTE: for dynamically updated metric values, you should *also* ensure the example_metrics_emitter.py service is constantly running.
set -euo pipefail
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap_helpers/load_env_first.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_JSON_FILE="$SCRIPT_DIR/provisioning/grafana/dashboards/example-metrics-dashboard.json"
TIME_SERIES_FILE="$SCRIPT_DIR/provisioning/grafana/dashboards/temp_example_metrics.prom"
EXAMPLE_METRICS_EMITTER_CONTAINERNAME="example_metrics_container"

# Generate example metrics
echo "Generating example metrics..."
NOW=$(date +%s)
START=$((NOW - 7200))  # 2 hours ago
> "$TIME_SERIES_FILE"

for TS in $(seq $START 1 $NOW); do
    EXAMPLE_VALUE_A1=$((100 + RANDOM % 100))
    EXAMPLE_VALUE_A2=$((EXAMPLE_VALUE_A1 * 12 / 10))  # 1.2 times EXAMPLE_VALUE_A1
    CPU_VALUE=$((50 + RANDOM % 50))
    MEM_VALUE=$((500 + RANDOM % 200))

    echo "exampleMetricA1{instance=\"${EXAMPLE_METRICS_EMITTER_CONTAINERNAME}:${EXAMPLE_METRICS_EMITTER_PORT}\"} $EXAMPLE_VALUE_A1 $TS" >> "$TIME_SERIES_FILE"
    echo "exampleMetricA2{instance=\"${EXAMPLE_METRICS_EMITTER_CONTAINERNAME}:${EXAMPLE_METRICS_EMITTER_PORT}\"} $EXAMPLE_VALUE_A2 $TS" >> "$TIME_SERIES_FILE"
    echo "example_cpu_usage{instance=\"${EXAMPLE_METRICS_EMITTER_CONTAINERNAME}:${EXAMPLE_METRICS_EMITTER_PORT}\"} $CPU_VALUE $TS" >> "$TIME_SERIES_FILE"
    echo "example_memory_usage{instance=\"${EXAMPLE_METRICS_EMITTER_CONTAINERNAME}:${EXAMPLE_METRICS_EMITTER_PORT}\"} $MEM_VALUE $TS" >> "$TIME_SERIES_FILE"
done

echo "Example metrics generated at $TIME_SERIES_FILE"

# Copy metrics to Prometheus container (ensure container is rebuilt if needed)
echo "Copying metrics to Prometheus container..."
${COMPOSE_CMD} up -d --build "example_metrics_emitter_servicename"
docker cp "$TIME_SERIES_FILE" "${EXAMPLE_METRICS_EMITTER_CONTAINERNAME}":/tmp/temp_example_metrics.prom
echo "Metrics copied to Prometheus container."

# Create dashboard JSON
echo "Creating dashboard JSON..."
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
  "title": "ExampleMetricA1, ExampleMetricA2, Example CPU + Example mem",
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
    { "expr": "exampleMetricA1{instance=\"\($containerName):\($port)\"}", "legendFormat": "ExampleMetricA1", "refId": "A" },
    { "expr": "exampleMetricA2{instance=\"\($containerName):\($port)\"}", "legendFormat": "ExampleMetricA2", "refId": "B" },
    { "expr": "example_cpu_usage{instance=\"\($containerName):\($port)\"}", "legendFormat": "CPU", "refId": "C" },
    { "expr": "example_memory_usage{instance=\"\($containerName):\($port)\"}", "legendFormat": "Mem", "refId": "D" }
  ],
  "datasource": "Prometheus_main"
}
')

DASHBOARD_JSON=$(echo "$DASHBOARD_JSON" | jq --argjson panel "$PANEL" '.dashboard.panels += [$panel]')
echo "Dashboard JSON created."

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
            echo "Max retries reached. Dashboard not uploaded. Aborting."
            exit 1
        fi
    fi
done

# Open dashboard in browser (refactored to a function)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/open_example_dashboard.sh"