#!/bin/bash
# Helper to start a Docker Compose service

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SERVICE_NAME=$1
CONTAINER_NAME=$2

MODE=${3:-up}  # default 'up', can also pass 'restart'

# Determine Docker Compose command
source "$SCRIPT_DIR/bootstrap_helpers/get_docker_compose_cmd.sh"

if [ "$MODE" == "restart" ]; then
  echo "Restarting $SERVICE_NAME container..."
  docker rm -f "${CONTAINER_NAME}" || true
  $COMPOSE_CMD up -d "${SERVICE_NAME}"
else
  if docker ps -a --format '{{.Names}}' | grep -q "${CONTAINER_NAME}"; then
    if docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}" | grep -q "true"; then
      echo "$SERVICE_NAME service is already up and running."
    else
      $COMPOSE_CMD up -d "${SERVICE_NAME}"
    fi
  else
    $COMPOSE_CMD up -d "${SERVICE_NAME}"
  fi
fi

if [ $? -eq 0 ]; then
  # Wait for service to be up
  source "$SCRIPT_DIR/bootstrap_helpers/wait_for_specified_services.sh" "${CONTAINER_NAME}"
fi
