#!/bin/bash
set -euo pipefail

# Load environment variables, ensure Docker is running
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap_helpers/load_env_first.sh"
source "$SCRIPT_DIR/../bootstrap_helpers/ensure_docker_running.sh"

MODE=${1:-up}  # default 'up', can also pass 'restart'

source "$SCRIPT_DIR/../bootstrap_helpers/start_service.sh" "example_metrics_emitter_servicename" "example_metrics_container" "${MODE}"

if [ "$MODE" == "restart" ]; then
    # Wait for Prometheus to scrape at least one metric from example-metrics
    PROM_SCRAPE_TIMEOUT=${PROM_SCRAPE_TIMEOUT:-30}  # seconds, configurable in .env
    echo "Waiting for Prometheus to scrape metrics from example-metrics..."
    END_SCRAPE=$((SECONDS+PROM_SCRAPE_TIMEOUT))
    while true; do
        METRIC_COUNT=$(curl -s http://${PROMETHEUS_HOST:-localhost}:${PROMETHEUS_PORT}/metrics | grep -c '.')
        echo "Metrics scraped so far: $METRIC_COUNT"
        if [ "$METRIC_COUNT" -gt 0 ]; then
            echo "Prometheus has scraped metrics from example-metrics."
            break
        fi
        [ $SECONDS -ge $END_SCRAPE ] && { echo "Timeout waiting for Prometheus to scrape example-metrics"; break; }
        sleep 2
    done
    # Create example dashboard (with retry)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    "$SCRIPT_DIR/create_example_dashboard.sh"
else
    # Open Grafana dashboard URL
    DASHBOARD_URL="$GRAFANA_URL/dashboards"
    echo "Opening existing Grafana dashboards in browser..."
    case "$OSTYPE" in
      darwin*) /Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge "$DASHBOARD_URL" ;;
      linux*) xdg-open "$DASHBOARD_URL" >/dev/null 2>&1 || true ;;
      msys*|cygwin*) start "$DASHBOARD_URL" ;;
    esac
    echo "Grafana ready at: $GRAFANA_URL"
fi
