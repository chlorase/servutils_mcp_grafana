# open_open_example_dashboard_for_grafanamcp.sh
open_grafana_dashboard_for_grafanamcp() {
    DASHBOARD_URL="$GRAFANA_URL/d/mcp-metrics-dashboard/mcp-metrics-dashboard?orgId=1&from=now-6h&to=now&timezone=utc&refresh=30s"
    echo "Opening Grafana example dashboard: $DASHBOARD_URL"
    case "$OSTYPE" in
      darwin*) /Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge "$DASHBOARD_URL" ;;
      linux*) xdg-open "$DASHBOARD_URL" >/dev/null 2>&1 || true ;;
      msys*|cygwin*) start "$DASHBOARD_URL" ;;
    esac
}

# Call the function
open_grafana_dashboard_for_grafanamcp