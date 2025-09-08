#!/bin/bash
# Test the Grafana MCP server

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../bootstrap_helpers/load_env_first.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env.grafanamcp"

# List all tenants
echo "Listing all tenants..."
curl ${GRAFANA_MCP_URL}/tenants

# Create a new tenant
echo "Creating a new tenant..."
curl -X POST -H "Content-Type: application/json" -d '{"name": "my-tenant"}' ${GRAFANA_MCP_URL}/tenants

# List all dashboards for the new tenant
echo "Listing all dashboards for the new tenant..."
curl ${GRAFANA_MCP_URL}/tenants/my-tenant/dashboards

# Create a new dashboard for the new tenant
echo "Creating a new dashboard for the new tenant..."
curl -X POST -H "Content-Type: application/json" -d '{"title": "My Dashboard"}' ${GRAFANA_MCP_URL}/tenants/my-tenant/dashboards

# Open the dashboard in the Grafana UI
echo "Opening dashboard in Grafana UI..."
case "$OSTYPE" in
  darwin*) /Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge "${GRAFANA_URL}/d/my-dashboard/my-dashboard?orgId=1" ;;
  linux*) xdg-open "${GRAFANA_URL}/d/my-dashboard/my-dashboard?orgId=1" >/dev/null 2>&1 || true ;;
  msys*|cygwin*) start "${GRAFANA_URL}/d/my-dashboard/my-dashboard?orgId=1" ;;
esac
