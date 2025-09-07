#!/bin/bash
# Starts Grafana, Prometheus, Loki, Promtail, example metrics outputter, MCP servers.
# ensures Grafana admin password, creates example dashboard, and opens browser. #TODO IMPLEMENT all these
set -euo pipefail

MODE=${1:-up}  # default 'up', can also pass 'restart'

# Start Grafana server
source "./grafana/start_grafana_server.sh" "${MODE}" || { echo "Failed to start Grafana server"; exit 1; }

# Start Grafana Prometheus server
source "./grafana/prometheus/start_prometheus_server.sh" "${MODE}" || { echo "Failed to start Prometheus server"; exit 1; }

# Start example metrics emitter and create dashboard
source "./example-metrics_emitter/start_example_emitter_server.sh" "${MODE}" || { echo "Failed to start example metrics emitter"; exit 1; }

#TODO IMPLEMENT rest

echo "All services started."