#!/bin/bash
# start_grafanamcp_server.sh
# Start the Grafana MCP server

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

# Ensure created service account and token ..

SERVICE_ACCOUNT_NAME="mcp-service-account"
SERVICE_ACCOUNT_ROLE="Admin"
# todo: update script to do this more controlled here like this:
# Assign folder permissions (example: give Editor access to folder ID 1)
#FOLDER_ID=1
#PERMISSION_LEVEL=2  # 1=Viewer, 2=Editor, 4=Admin
#echo "Assigning folder permissions to service account..."
#cmd=(curl -v -s -m 10 -X POST -H "Content-Type: application/json" \
#  -d "{\"items\": [{\"userId\": $SERVICE_ACCOUNT_ID, \"permission\": $PERMISSION_LEVEL}]}" \
#  ${GRAFANA_URL}/api/folders/$FOLDER_ID/permissions \
#  -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD})
#echo "Running command: ${cmd[@]}"
#"${cmd[@]}"

TOKEN_NAME="mcp-service-account-token"

echo "1st checking if service account exists..."
cmd=(curl -v -s -m 10 -X GET -H "Content-Type: application/json" ${GRAFANA_URL}/api/serviceaccounts/search -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD})
echo "Running command: ${cmd[@]}"
SERVICE_ACCOUNTS_RESPONSE=$("${cmd[@]}")
echo ".. result: ${SERVICE_ACCOUNTS_RESPONSE}"
SERVICE_ACCOUNT_ID=$(echo "$SERVICE_ACCOUNTS_RESPONSE" | jq -r '.serviceAccounts[] | select(.name == "'"$SERVICE_ACCOUNT_NAME"'") | .id')

# Create service account (if not exist)
if [ -z "$SERVICE_ACCOUNT_ID" ]; then
  echo "Creating service account..."
  cmd=(curl -v -s -m 10 -X POST -H "Content-Type: application/json" -d "{\"name\": \"$SERVICE_ACCOUNT_NAME\", \"role\": \"$SERVICE_ACCOUNT_ROLE\"}" ${GRAFANA_URL}/api/serviceaccounts -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD})
  echo "Running command: ${cmd[@]}"
  SERVICE_ACCOUNT_RESPONSE=$("${cmd[@]}")
  echo ".. result: ${SERVICE_ACCOUNT_RESPONSE}"
  if [ $? -ne 0 ]; then
    echo "Error creating service account: $?"
    exit 1
  fi
  SERVICE_ACCOUNT_ID=$(echo "$SERVICE_ACCOUNT_RESPONSE" | jq -r '.id')
  if [ -z "$SERVICE_ACCOUNT_ID" ]; then
    echo "Error parsing service account ID: $SERVICE_ACCOUNT_RESPONSE"
    exit 1
  fi
else
  echo "Service account $SERVICE_ACCOUNT_NAME already exists with ID $SERVICE_ACCOUNT_ID"
fi

# Get existing tokens
echo "1st checking if existing tokens exist (will remove to refresh/recreate if there are).."
cmd=(curl -v -s -m 10 -X GET -H "Content-Type: application/json" ${GRAFANA_URL}/api/serviceaccounts/$SERVICE_ACCOUNT_ID/tokens -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD})
echo ".. Running command: ${cmd[@]}"
TOKENS_RESPONSE=$("${cmd[@]}")
echo ".. result: ${TOKENS_RESPONSE} (If this is empty means no existing tokens)"

# Delete existing token with the same name
for token in $(echo "$TOKENS_RESPONSE" | jq -r '.[] | select(.name == "'"$TOKEN_NAME"'") | .id'); do
  echo "Deleting an existing token (will refresh).."
  cmd=(curl -v -s -m 10 -X DELETE -H "Content-Type: application/json" ${GRAFANA_URL}/api/serviceaccounts/$SERVICE_ACCOUNT_ID/tokens/$token -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD})
  echo ".. Running command: ${cmd[@]}"
  "${cmd[@]}"
done

# Create token
echo "Creating service account's token..."
cmd=(curl -v -s -m 10 -X POST -H "Content-Type: application/json" -d "{\"name\": \"$TOKEN_NAME\"}" ${GRAFANA_URL}/api/serviceaccounts/$SERVICE_ACCOUNT_ID/tokens -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD})
echo "Running command: ${cmd[@]}"
TOKEN_RESPONSE=$("${cmd[@]}")
echo ".. result: ${TOKEN_RESPONSE}"
if [ $? -ne 0 ]; then
  echo "Error creating token: $?"
  exit 1
fi
TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.key')
if [ -z "$TOKEN" ]; then
  echo "Error parsing token: $TOKEN_RESPONSE"
  exit 1
fi

# Save credentials to ${ENV_GRAFANAMCP_FILENAME} file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_GRAFANAMCP_FILEPATH="$SCRIPT_DIR/../../${ENV_GRAFANAMCP_FILENAME}"
echo "Saving credentials to: $ENV_GRAFANAMCP_FILEPATH ."
echo "# Auto-generated credentials for local MCP Grafana instance" > "$ENV_GRAFANAMCP_FILEPATH"
echo "GRAFANA_URL=${GRAFANA_URL}" >> "$ENV_GRAFANAMCP_FILEPATH"
echo "GRAFANA_SERVICE_ACCOUNT_TOKEN=$TOKEN" >> "$ENV_GRAFANAMCP_FILEPATH"
echo "GRAFANA_MCP_URL=${GRAFANA_MCP_URL}" >> "$ENV_GRAFANAMCP_FILEPATH"
echo "GRAFANA_MCP_PORT=${GRAFANA_MCP_PORT}" >> "$ENV_GRAFANAMCP_FILEPATH"

# Run tests by default, but allow suppression
if [ "$RUN_TESTS" = "true" ]; then
  echo "Running tests... Awaiting container first..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$ENV_GRAFANAMCP_FILEPATH"
  start_time=$(date -u +%s)
  echo ".. GRAFANA_MCP_URL: $GRAFANA_MCP_URL"
  echo ".. start_time: $start_time"

  TEMP_LOG_DIR="${SCRIPT_DIR}/localgenerated"
  [ ! -d "${TEMP_LOG_DIR}" ] && mkdir -p "$TEMP_LOG_DIR" && chmod u+w "$TEMP_LOG_DIR"
  TEMP_CURL_LOG_PATH="${TEMP_LOG_DIR}/curl_output.log"

  cmd=(curl -s -f -m 5 ${GRAFANA_MCP_URL}) # Ensure to include the -m timeout so this exits
  echo ".. checking using cmd: ${cmd[@]} .."
  while ! $("${cmd[@]}") &> ${TEMP_CURL_LOG_PATH}; do
    echo "curl command failed, checking again..."
    current_time=$(date -u +%s)
    if (( current_time - start_time > CONTAINER_START_TIMEOUT )); then
      echo "Timeout waiting ${CONTAINER_START_TIMEOUT}s for Grafana MCP server to become available"
      cat ${TEMP_CURL_LOG_PATH}
      break
    elif [ $? -ne 0 ]; then
      echo "curl command exited with non-zero status, exiting loop"
      # You can choose to break or continue here based on your needs
      break
    fi
    sleep 1
    echo -n "."
  done

  echo "===================================="
  echo "Running tests..."
  cmd="$SCRIPT_DIR/test_grafanamcp_server.sh"
  $cmd
else
  echo "Tests suppressed."
fi

echo "Grafana MCP server started."
