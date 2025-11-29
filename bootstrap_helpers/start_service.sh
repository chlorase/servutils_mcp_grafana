#!/bin/bash
# start_service.sh
# Helper to start a Docker Compose service
# TODO: refactor to use common helper in installers/_helpers/installers_docker instead of this file's duplicating code.

SERVICE_NAME=$1
CONTAINER_NAME=$2
MODE=${3:-up}  # default 'up', can also pass 'restart'
echo ".. Helper: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"
echo "SERVICE_NAME: $SERVICE_NAME"
echo "CONTAINER_NAME: $CONTAINER_NAME"
echo "MODE: $MODE"

# Determine Docker Compose command
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/get_docker_compose_cmd.sh"

if [ "$MODE" == "restart" ]; then
  echo "Restarting $SERVICE_NAME container..."
  if docker ps -a --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
    docker stop "$CONTAINER_NAME" || true
    docker rm "$CONTAINER_NAME" || true
  fi
  $COMPOSE_CMD rm -f "${SERVICE_NAME}" || true
  $COMPOSE_CMD up -d "$SERVICE_NAME"
else
  if docker ps -a --format '{{.Names}}' | grep -q "${CONTAINER_NAME}"; then
    if docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}" | grep -q "true"; then
      echo "$SERVICE_NAME service is already up and running."
    else
      echo "Starting service $SERVICE_NAME for container..."
      $COMPOSE_CMD up -d "${SERVICE_NAME}"
    fi
  else
    echo "Starting service $SERVICE_NAME..."
    $COMPOSE_CMD up -d "${SERVICE_NAME}"
  fi
fi
echo "Service $SERVICE_NAME started."


if [ $? -eq 0 ]; then
  # Wait for service to be up
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/wait_for_specified_services.sh" "${CONTAINER_NAME}"
fi
