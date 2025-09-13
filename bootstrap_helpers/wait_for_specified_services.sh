#!/bin/bash
# Helper to wait for all current command input arg list of services, to be in running state (in your local docker)
echo ".. Helper: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load_env_first.sh"

services=("$@")
END=$((SECONDS+CONTAINER_START_TIMEOUT))
for service in "${services[@]}"; do
  echo "Waiting for service $service.."
  while true; do
    RUNNING=$(docker inspect -f '{{.State.Running}}' "$service" 2>/dev/null || echo "false")
    [ "$RUNNING" == "true" ] && break
    [ $SECONDS -ge $END ] && { 
      echo "Timeout waiting for $service. Dumping last 20 logs:"
      docker logs --tail=20 "$service"
      docker ps
      exit 1
    }
    sleep 2
  done
  echo "Done waiting for service $service."
done
echo "All containers for ${services[@]} are up and running."