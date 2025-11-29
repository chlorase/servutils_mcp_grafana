#!/bin/bash
# start_grafana_server.sh

set -euo pipefail
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

# Load environment variables, ensure Docker is running, and determine Docker Compose command
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap_helpers/load_env_first.sh"
source "$SCRIPT_DIR/../bootstrap_helpers/ensure_docker_running.sh"

MODE=${1:-up}  # default 'up', can also pass 'restart'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap_helpers/start_service.sh" "grafana" "servutils_mcp_grafana_grafana_container" "${MODE}"
