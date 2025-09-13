#!/bin/bash
# test_grafanamcp_server.sh: Test the Grafana MCP server

echo "-------"
echo ""
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"
echo "Starting TESTS"

echo "What we will be testing: "
echo "│"
echo "├── Checks Zed is installed"
echo "│"
echo "├── Creates dashboard summary JSON for Zed"
echo "│   └── Used for metadata viewing (not dashboard creation)"
echo "│"
echo "├── Launches Zed with summary file"
echo "│"
echo "├── Calls create_example_dashboard_for_grafanamcp.sh"
echo "│   └── Generates metrics, builds dashboard, uploads via API"
echo "│"
echo "├── Opens dashboard in browser"
echo "│"
echo "└── Verifies dashboard exists via curl + token"


# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../bootstrap_helpers/load_env_first.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../.env.grafanamcp"

# -------------------------------
# ZED INTEGRATION + DASHBOARD LAUNCH
# Note Grafana's stock mcp-grafana doesn't expose regular REST endpoints, so you need to install a client like Zed to interface with the mcp-grafana dashboards and create etc.
# -------------------------------

echo ""
echo "Checking for Zed installation..."

if ! command -v zed &> /dev/null; then
  echo "Zed not found. Installing Zed editor..."
  curl -fsSL https://zed.dev/install.sh | sh
else
  echo "Zed is already installed."
fi

# Create a test MCP config or dashboard summary file
ZED_TEST_FILE="$SCRIPT_DIR/test_mcp_dashboard_summary.json"
echo "Creating test MCP dashboard summary file at $ZED_TEST_FILE..."

cat > "$ZED_TEST_FILE" <<EOF
{
  "grafana_url": "${GRAFANA_URL}",
  "mcp_endpoint": "${GRAFANA_MCP_URL}",
  "tenant": "my-tenant",
  "dashboard": {
    "title": "My Dashboard",
    "url": "${GRAFANA_URL}/d/my-dashboard/my-dashboard?orgId=1",
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  },
  "notes": "This dashboard was created via MCP test script. You can use this file to summarize or extend dashboard metadata."
}
EOF

# Launch Zed with the test file
echo "Launching Zed with dashboard summary..."
zed "$ZED_TEST_FILE" &

# Create dashboard:
echo "Creating MCP metrics dashboard..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/../../example_metrics_emitter/create_example_dashboard_for_grafanamcp.sh"

# Open dashboard in browser
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../example_metrics_emitter/open_example_dashboard_for_grafanamcp.sh"

echo ""
echo "Running curl test to fetch dashboard metadata..."
DASHBOARD_UID="mcp-metrics-dashboard"
CURL_CMD="curl -H \"Authorization: Bearer ${GRAFANA_SERVICE_ACCOUNT_TOKEN}\" \"${GRAFANA_URL}/api/dashboards/uid/${DASHBOARD_UID}\""
echo "Executing: $CURL_CMD"
eval "$CURL_CMD"

echo ""
echo "Script complete."

