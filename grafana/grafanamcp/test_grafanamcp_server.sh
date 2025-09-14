#!/bin/bash
# test_grafanamcp_server.sh
# Test the Grafana MCP server

echo "-------"
echo ""
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"
echo "Starting TESTS"
echo "What we will be testing: "
echo "│"
echo "├── Creates dashboard summary JSON for hooking up to MCP agents"
echo "│   └── Used for metadata viewing (not dashboard creation)"
echo "│"
echo "├── Calls create_example_dashboard_for_grafanamcp.sh"
echo "│   └── Generates metrics, builds dashboard, uploads via API"
echo "│"
echo "├── Opens dashboard in browser, just to confirm its there"
echo "│"
echo "├── Verifies dashboard exists via curl + token"
echo "|-- TEST our Custom Grafana-MCP server is up."
echo "│"
echo "├── ZED Grafana-MCP local server setup/integration. Checks Zed is installed, and launches it (if on Mac)"
echo "│   └── Launches Zed with summary file sample (just to confirm)"
echo "│   └── Launches Zed with zed-mcp-grafana loca server setup (*separate* server instance of mcp-grafana install locally in Zed!). Then tells user to use an @..text file to prompt in Zed."
echo "│"
echo "└── END"


# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../bootstrap_helpers/load_env_first.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../${ENV_GRAFANAMCP_FILENAME}"

echo "# -------------------------------"
echo "# Setup dashboard first in grafana (no MCP specific testing yet)"
echo "# -------------------------------"
echo "Pre-tests Grafana Dashboard/Metrics Setup.."
echo ""
# Create dashboard:
echo "..Creating MCP metrics dashboard..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/../../example_metrics_emitter/create_example_dashboard_for_grafanamcp.sh"

# Open dashboard in browser
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../example_metrics_emitter/open_example_dashboard_for_grafanamcp.sh"
echo ".. Running curl test to fetch dashboard metadata..."
DASHBOARD_UID="mcp-metrics-dashboard"
CURL_CMD="curl -H \"Authorization: Bearer ${GRAFANA_SERVICE_ACCOUNT_TOKEN}\" \"${GRAFANA_URL}/api/dashboards/uid/${DASHBOARD_UID}\""
echo "..Executing: $CURL_CMD"
eval "$CURL_CMD"
echo ""

# -------------------------------
# Custom Grafana-MCP Server tests
# (Test of our Custom Grafana-MCP server (not Zed started one))
# -------------------------------
echo "# -------------------------------"
echo "# Custom Grafana-MCP Server tests"
echo "# -------------------------------"
echo "..Checking if our custom instance of MCP server port 8000 is open..."
( echo > /dev/tcp/localhost/8000 ) &> /dev/null && \
  echo "...Port 8000 is open and accepting connections." || \
  echo "...Port 8000 is closed or MCP server is not listening."

# -------------------------------
# ZED INTEGRATION + DASHBOARD LAUNCH
# Note Grafana's stock mcp-grafana doesn't expose regular REST endpoints, so you need to install a client like Zed to interface with the mcp-grafana dashboards and create etc (Zed has LLM and grafana MCP libraries etc you can use later, for dev use)
# -------------------------------
echo "Zed integration tests"

# Zed client install, and verification.

# Create a test MCP config or dashboard summary file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_GEN_DIR="$SCRIPT_DIR/localgenerated"
[ ! -d "${LOCAL_GEN_DIR}" ] && mkdir -p "$LOCAL_GEN_DIR" && chmod u+w "$LOCAL_GEN_DIR"
ZED_TEST_DASH_FILE="${LOCAL_GEN_DIR}/test_mcp_dashboard_summary.json"

echo "Creating test MCP dashboard summary file at $ZED_TEST_DASH_FILE..."
cat > "$ZED_TEST_DASH_FILE" <<EOF
{
  "grafana_url": "${GRAFANA_URL}",
  "mcp_endpoint": "${GRAFANA_MCP_URL}",
  "tenant": "my-tenant",
  "dashboard": {
    "title": "MCP Metrics Dashboard",
    "url": "${GRAFANA_URL}/d/mcp-metrics-dashboard/mcp-metrics-dashboard?orgId=1"
  },
  "notes": "This dashboard was created via MCP test script. You can use this file to summarize or extend dashboard metadata."
}
EOF
# Launch Zed with the test file
echo "Launching Zed with dashboard summary..."
zed "$ZED_TEST_DASH_FILE" &

# -------------------------------
# ZED AGENT PANEL + GEMINI CLI TEST
# -------------------------------
echo ""
echo "Test: Launching Zed with Gemini CLI agent and sample query files saved..."
# Temp local dir:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_GEN_DIR="$SCRIPT_DIR/localgenerated"
[ ! -d "${LOCAL_GEN_DIR}" ] && mkdir -p "$LOCAL_GEN_DIR" && chmod u+w "$LOCAL_GEN_DIR"

# Create a sample Gemini query file to get last 30 minutes of metrics, to load into Zed:
ZED_QUERY_FILE_GET30MIN="${LOCAL_GEN_DIR}/test_zed_gemini_query_get30min.txt"
echo ".. Creating sample Gemini query file at $ZED_QUERY_FILE_GET30MIN..."
cat > "$ZED_QUERY_FILE_GET30MIN" <<EOF
Note: A sample url format is like this: http://localhost:3000/explore?schemaVersion=1&panes=%7B%22qbf%22:%7B%22datasource%22:%22PB78FB031097FA2F6%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22exampleMetricA1%22,%22range%22:true,%22instant%22:true,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22PB78FB031097FA2F6%22%7D,%22editorMode%22:%22builder%22,%22legendFormat%22:%22__auto%22,%22useBackend%22:false,%22disableTextWrap%22:false,%22fullMetaSearch%22:false,%22includeNullMetadata%22:true%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1
Query the CPU and memory usage from the last 30 minutes using the 'prometheus' datasource. Visualize the result in Grafana Explore (try to ensure the URL works as needed).
EOF

# Create a sample Gemini query file to get last 30 minutes of metrics, to load into Zed:
ZED_QUERY_FILE_GETCORRELATIONS="${LOCAL_GEN_DIR}/test_zed_gemini_query_getCorrelations.txt"
echo ".. Creating sample Gemini query file at $ZED_QUERY_FILE_GETCORRELATIONS..."
cat > "$ZED_QUERY_FILE_GETCORRELATIONS" <<EOF
Note: A sample url format is like this: http://localhost:3000/explore?schemaVersion=1&panes=%7B%22qbf%22:%7B%22datasource%22:%22PB78FB031097FA2F6%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22exampleMetricA1%22,%22range%22:true,%22instant%22:true,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22PB78FB031097FA2F6%22%7D,%22editorMode%22:%22builder%22,%22legendFormat%22:%22__auto%22,%22useBackend%22:false,%22disableTextWrap%22:false,%22fullMetaSearch%22:false,%22includeNullMetadata%22:true%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1
Find correlations CPU, memory, ExampleMetricA1, ExampleMetricA2, during the last 5 minutes.
EOF


# Open Zed:
echo ".. Launching Zed with dashboard summary and Gemini query..."
zed "$ZED_TEST_DASH_FILE" "$ZED_QUERY_FILE_GET30MIN" "$ZED_QUERY_FILE_GETCORRELATIONS" &
# Remind user to open Agent panel manually:
echo ".. Note: To run Gemini CLI agent, open Zed's Agent panel (Cmd-?) and click '+' to start a Gemini thread."
echo ".. Then @-mention the query file: @$ZED_QUERY_FILE_GET30MIN, or @$$ZED_QUERY_FILE_GETCORRELATIONS.."

echo ""
echo ""
echo ""
echo "Grafana-MCP related tests complete."

