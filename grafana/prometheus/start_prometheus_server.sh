#!/bin/bash
set -euo pipefail
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

# Load environment variables, ensure Docker is running
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../bootstrap_helpers/load_env_first.sh"
source "$SCRIPT_DIR/../bootstrap_helpers/ensure_docker_running.sh"

MODE=${1:-up}  # default 'up', can also pass 'restart'

echo "Waiting for Prometheus to start..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../bootstrap_helpers/start_service.sh" "prometheus" "servutils_mcp_prometheus_container" "${MODE}"
echo "Prometheus started."