#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables, ensure Docker is running, and determine Docker Compose command
#set +u
#source "$SCRIPT_DIR/../.env"
#set -u
source "$SCRIPT_DIR/../bootstrap_helpers/load_env_first.sh"
source "$SCRIPT_DIR/../bootstrap_helpers/ensure_docker_running.sh"

MODE=${1:-up}  # default 'up', can also pass 'restart'

GRAFANA_CONTAINER="${PROJECT_PREFIX}_grafana"
GRAFANA_SERVICE="grafana"
source "$SCRIPT_DIR/../bootstrap_helpers/start_service.sh" "${GRAFANA_SERVICE}" "${GRAFANA_CONTAINER}" "${MODE}"
