#!/bin/bash
# start_example_emitter_server.sh

set -euo pipefail
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

# This script starts the Example Metrics Emitter service and waits for Prometheus to scrape metrics.
# It also creates an example dashboard in Grafana if the service is restarted.

# Load environment variables, ensure Docker is running
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap_helpers/load_env_first.sh"
source "$SCRIPT_DIR/../bootstrap_helpers/ensure_docker_running.sh"

MODE=${1:-up}  # default 'up', can also pass 'restart'

echo "Starting Example Metrics Emitter in mode: $MODE"

# Start the Example Metrics Emitter service
echo "Starting service..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_cmd="source $SCRIPT_DIR/../bootstrap_helpers/start_service.sh example_metrics_emitter_servicename example_metrics_container $MODE"
echo "Running command: $_cmd"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap_helpers/start_service.sh" "example_metrics_emitter_servicename" "example_metrics_container" "${MODE}"
echo "Example Metrics Emitter started."

if [ "$MODE" == "restart" ]; then
    # Wait for Prometheus to scrape at least one metric from example_metrics
    PROM_SCRAPE_TIMEOUT=${PROM_SCRAPE_TIMEOUT:-30}  # seconds, configurable in .env
    echo "Waiting for Prometheus to scrape metrics from example_metrics..."
    END_SCRAPE=$((SECONDS+PROM_SCRAPE_TIMEOUT))
    while true; do
        METRIC_COUNT=$(curl -s http://${PROMETHEUS_HOST:-localhost}:${PROMETHEUS_PORT}/metrics | grep -c '.')
        echo "Metrics scraped so far: $METRIC_COUNT"
        if [ "$METRIC_COUNT" -gt 0 ]; then
            echo "Prometheus has scraped metrics from example_metrics."
            break
        fi
        [ $SECONDS -ge $END_SCRAPE ] && { echo "Timeout waiting for Prometheus to scrape example_metrics"; break; }
        sleep 2
    done
    
    # Create example dashboard (with retry)
    echo ""
    echo "Creating example dashboard..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    "$SCRIPT_DIR/create_example_dashboard.sh"
    echo "Example dashboard created."
else
    # Open Grafana dashboard URL
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/open_example_dashboard.sh"
fi