open_grafana_dashboard() {
    DASHBOARD_URL="$GRAFANA_URL/d/example-dashboard/example-metrics-dashboard?orgId=1&from=now-6m&to=now&timezone=utc&refresh=30s"
    echo "Opening Grafana example dashboard: $DASHBOARD_URL"
    case "$OSTYPE" in
      darwin*) /Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge "$DASHBOARD_URL" ;;
      linux*) xdg-open "$DASHBOARD_URL" >/dev/null 2>&1 || true ;;
      msys*|cygwin*) start "$DASHBOARD_URL" ;;
    esac
}

# Call the function
open_grafana_dashboard