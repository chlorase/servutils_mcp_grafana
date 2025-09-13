#!/bin/bash
# test_grafanamcp_server.sh: Test the Grafana MCP server

echo "-------"
echo ""
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"
echo "Starting TESTS"

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../bootstrap_helpers/load_env_first.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env.grafanamcp"

# PRE: the MCP server URL, should be in .env file:
# GRAFANA_MCP_URL="http://localhost:${GRAFANA_MCP_PORT}/mcp"

# List all tenants
echo "Listing all tenants..."
cmd=(curl ${GRAFANA_MCP_URL}/tenants)
echo ".. Running command: ${cmd[@]}"
"${cmd[@]}"

# Create a new tenant
echo "Creating a new tenant..."
cmd=(curl -X POST -H "Content-Type: application/json" -d "{\"name\": \"my-tenant\"}" ${GRAFANA_MCP_URL}/tenants)
echo ".. Running command: ${cmd[@]}"
"${cmd[@]}"

# List all dashboards for the new tenant
echo "Listing all dashboards for the new tenant..."
cmd=(curl ${GRAFANA_MCP_URL}/tenants/my-tenant/dashboards)
echo ".. Running command: ${cmd[@]}"
"${cmd[@]}"

# Create a new dashboard for the new tenant
echo "Creating a new dashboard for the new tenant..."
cmd=(curl -X POST -H "Content-Type: application/json" -d "{\"title\": \"My Dashboard\"}" ${GRAFANA_MCP_URL}/tenants/my-tenant/dashboards)
echo ".. Running command: ${cmd[@]}"
"${cmd[@]}"

# Open the dashboard in the Grafana UI
echo "Opening dashboard in Grafana UI..."
case "$OSTYPE" in
  darwin*) /Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge "${GRAFANA_URL}/d/my-dashboard/my-dashboard?orgId=1" ;;
  linux*) xdg-open "${GRAFANA_URL}/d/my-dashboard/my-dashboard?orgId=1" >/dev/null 2>&1 || true ;;
  msys*|cygwin*) start "${GRAFANA_URL}/d/my-dashboard/my-dashboard?orgId=1" ;;
esac
