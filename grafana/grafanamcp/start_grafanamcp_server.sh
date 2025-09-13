#!/bin/bash
# start_grafanamcp_server.sh: Start the Grafana MCP server

echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="source $SCRIPT_DIR/../../bootstrap_helpers/load_env_first.sh"
echo "Running command: $cmd"
$cmd

# Determine Docker Compose command
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="source $SCRIPT_DIR/../../bootstrap_helpers/get_docker_compose_cmd.sh"
echo "Running command: $cmd"
$cmd

# Parse options
MODE=${1:-up}
RUN_TESTS=${2:-true}

# Start the MCP server
echo "Starting Grafana MCP server in mode $MODE..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="$SCRIPT_DIR/../../bootstrap_helpers/start_service.sh grafanamcp servutils_mcp_grafanamcp_container $MODE"
echo "Running command: $cmd"
$cmd

# Create a service account and token
echo "Creating service account and token..."
SERVICE_ACCOUNT_NAME="mcp-service-account"
SERVICE_ACCOUNT_ROLE="Viewer"
TOKEN_NAME="mcp-service-account-token"

# Create service account
cmd="curl -s -X POST -H \"Content-Type: application/json\" -d '{\"name\": \"$SERVICE_ACCOUNT_NAME\", \"role\": \"$SERVICE_ACCOUNT_ROLE\"}' ${GRAFANA_URL}/api/serviceaccounts -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}"
echo "Running command: $cmd"
SERVICE_ACCOUNT_RESPONSE=$($cmd)
SERVICE_ACCOUNT_ID=$(echo "$SERVICE_ACCOUNT_RESPONSE" | jq -r '.id')

# Create token
cmd="curl -s -X POST -H \"Content-Type: application/json\" -d '{\"name\": \"$TOKEN_NAME\"}' ${GRAFANA_URL}/api/serviceaccounts/$SERVICE_ACCOUNT_ID/tokens -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}"
echo "Running command: $cmd"
TOKEN_RESPONSE=$($cmd)
TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.key')

# Save credentials to .env.grafanamcp file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "GRAFANA_URL=${GRAFANA_URL}" > "$SCRIPT_DIR/../../.env.grafanamcp"
echo "GRAFANA_SERVICE_ACCOUNT_TOKEN=$TOKEN" >> "$SCRIPT_DIR/../../.env.grafanamcp"
echo "GRAFANA_MCP_URL=${GRAFANA_MCP_URL}" >> "$SCRIPT_DIR/../../.env.grafanamcp"
echo "GRAFANA_MCP_PORT=${GRAFANA_MCP_PORT}" >> "$SCRIPT_DIR/../../.env.grafanamcp"

# Run tests by default, but allow suppression
if [ "$RUN_TESTS" = "true" ]; then
  echo "Running tests... Awaiting container first..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/../../.env.grafanamcp"
  echo "GRAFANA_MCP_URL: $GRAFANA_MCP_URL"
  start_time=$(date +%s)
  while ! curl -s -f -v ${GRAFANA_MCP_URL} &> curl_output.log; do
    current_time=$(date +%s)
    if (( current_time - start_time > CONTAINER_START_TIMEOUT )); then
      echo "Timeout waiting ${CONTAINER_START_TIMEOUT}s for Grafana MCP server to become available"
      cat curl_output.log
      break
    fi
    sleep 1
    echo -n "."
  done
  # Try this too to get more debugging info in case:
  echo "Running tests... Double checking container again first..."
  cmd="docker exec servutils_mcp_grafanamcp_container curl -s -f -v http://localhost:8080"
  echo "Running command: $cmd"
  while ! $cmd &> /dev/null; do
    current_time=$(date +%s)
    if (( current_time - start_time > CONTAINER_START_TIMEOUT )); then
      echo "Timeout waiting ${CONTAINER_START_TIMEOUT}s for Grafana MCP server to become available"
      exit 1
    fi
    sleep 1
    echo -n "."
  done
  echo ""
  echo "Running tests..."
  cmd="$SCRIPT_DIR/test_grafanamcp_server.sh"
  echo "Running command: $cmd"
  $cmd
else
  echo "Tests suppressed."
fi

echo "Grafana MCP server started."
