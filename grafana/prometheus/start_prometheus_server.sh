#!/bin/bash
set -euo pipefail

# Load environment variables, ensure Docker is running
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../bootstrap_helpers/load_env_first.sh"
source "$SCRIPT_DIR/../bootstrap_helpers/ensure_docker_running.sh"

MODE=${1:-up}  # default 'up', can also pass 'restart'

PROMETHEUS_CONTAINER="${PROJECT_PREFIX}_prometheus"
PROMETHEUS_SERVICE="prometheus"

echo "Waiting for Prometheus to start..."
source "$SCRIPT_DIR/../bootstrap_helpers/start_service.sh" "${PROMETHEUS_SERVICE}" "${PROMETHEUS_CONTAINER}" "${MODE}"
echo "Prometheus started."