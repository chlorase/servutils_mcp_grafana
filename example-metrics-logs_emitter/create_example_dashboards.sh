#TODO: Fixup and implement this completely, namings and paths etc  need fixups:
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
export $(grep -v '^#' "$SCRIPT_DIR/../../env/.env" | xargs)

DASHBOARD_JSON_FILE="$SCRIPT_DIR/../../provisioning/dashboards/example-metrics_dashboard.json"
TIME_SERIES_FILE="$SCRIPT_DIR/servutils_example_metrics.prom"

# -----------------------------
# Generate example metrics
# -----------------------------
echo "Generating example metrics..."
NOW=$(date +%s)
START=$((NOW - 7200))  # 2 hours ago
> "$TIME_SERIES_FILE"

for TS in $(seq $START 1 $NOW); do
    EXAMPLE_VALUE=$((100 + RANDOM % 100))
    CPU_VALUE=$((50 + RANDOM % 50))
    MEM_VALUE=$((50 + RANDOM % 200))

    echo "exampleMetricA{instance=\"servutils_example-metrics:8001\"} $EXAMPLE_VALUE $TS" >> "$TIME_SERIES_FILE"
    echo "example_cpu_usage{instance=\"servutils_example-metrics:8001\"} $CPU_VALUE $TS" >> "$TIME_SERIES_FILE"
    echo "example_memory_usage{instance=\"servutils_example-metrics:8001\"} $MEM_VALUE $TS" >> "$TIME_SERIES_FILE"
done

echo "Example metrics generated at $TIME_SERIES_FILE"

# Copy metrics to Prometheus container (ensure container is rebuilt if needed)
docker compose up -d --build example-metrics
docker cp "$TIME_SERIES_FILE" "${PROM_CONTAINER:-servutils_prometheus}":/tmp/servutils_example_metrics.prom

# -----------------------------
# Create dashboard JSON
# -----------------------------
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
PANEL=$(jq -n --argjson panelId 1 '
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
    { "expr": "exampleMetricA{instance=\"servutils_example-metrics:8001\"}", "legendFormat": "ExampleMetricA", "refId": "A" },
    { "expr": "example_cpu_usage{instance=\"servutils_example-metrics:8001\"}", "legendFormat": "CPU", "refId": "B" },
    { "expr": "example_memory_usage{instance=\"servutils_example-metrics:8001\"}", "legendFormat": "Mem", "refId": "C" }
  ],
  "datasource": "Prometheus"
}
')

DASHBOARD_JSON=$(echo "$DASHBOARD_JSON" | jq --argjson panel "$PANEL" '.dashboard.panels += [$panel]')

# Write updated JSON back to provisioning folder
echo "$DASHBOARD_JSON" | jq '.' > "$DASHBOARD_JSON_FILE"
echo "Updated dashboard JSON saved to $DASHBOARD_JSON_FILE"

# -----------------------------
# Upload dashboard to Grafana
# -----------------------------
GRAFANA_URL="http://localhost:${GRAFANA_PORT}"
GRAFANA_URL_ADMINACCESS="http://${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}@localhost:${GRAFANA_PORT}"

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

# -----------------------------
# Open dashboard in browser
# -----------------------------
DASHBOARD_URL="$GRAFANA_URL/d/example-dashboard/example-metrics-dashboard?orgId=1&from=now-6m&to=now&timezone=utc&refresh=30s"
echo "Opening Grafana example dashboard: $DASHBOARD_URL"
case "$OSTYPE" in
  darwin*) /Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge "$DASHBOARD_URL" ;;
  linux*) xdg-open "$DASHBOARD_URL" >/dev/null 2>&1 || true ;;
  msys*|cygwin*) start "$DASHBOARD_URL" ;;
esac
