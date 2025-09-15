#!/bin/bash
# Starts Grafana, Prometheus, Loki, Promtail, example metrics outputter, MCP servers.
# ensures Grafana admin password, creates example dashboard, and opens browser. #TODO IMPLEMENT all these
set -euo pipefail
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

MODE=${1:-up}  # default 'up', can also pass 'restart'

if [ "$MODE" == "restart" ]; then
    echo "Stopping all containers..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    "$SCRIPT_DIR/stop_everything.sh"

    echo removing extra local dirs to clear grafana
    rm -rf ./grafana-data
    rm -rf ./wal
    rm -rf ./loki-chunks
    rm -rf ./loki-config.yaml
    rm -rf ./loki-index
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "./bootstrap_helpers/ensure_installers_helpers_synced.sh"

# Start Grafana server
source "./grafana/start_grafana_server.sh" "${MODE}" || { echo "Failed to start Grafana server"; exit 1; }

# Start Grafana Prometheus server
source "./grafana/prometheus/start_prometheus_server.sh" "${MODE}" || { echo "Failed to start Prometheus server"; exit 1; }

# Start example metrics emitter and create dashboard
source "./example_metrics_emitter/start_example_emitter_server.sh" "${MODE}" || { echo "Failed to start example metrics emitter"; exit 1; }

# Start 'Grafana MCP' Server and create test dashboard
source "./grafana/grafanamcp/start_grafanamcp_server.sh" "${MODE}" || { echo "Failed to start Grafana MCP"; exit 1; }

# Start LLM Server
source "./llm/start_local_llm_mistral.sh" "${MODE}" || { echo "Failed to start LLM server"; exit 1; }

# Start LLM Agent Connection
source "./llm/start_local_ollama_mcp_agent.sh" "${MODE}" || { echo "Failed to start LLM agent"; exit 1; }


#TODO IMPLEMENT rest

echo "All services started."