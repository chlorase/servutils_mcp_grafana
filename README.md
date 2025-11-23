# servutils_mcp_grafana
* ./restart_everything.sh (or start_everything.sh restart): To re-run but not re-install/recreate all containers.
* ./start_everything.sh: To re-run but not re-install/recreate all containers.
* ./stop_everything.sh:  To stop all containers/servers locally.

# Details
When you run ./restart_everything.sh, it
* Cleans up old runs.
* Starts a Grafana, Prometheus, a custom metrics-emitting server, a Grafana grafana-mcp server, an ollama LLM server, and an  Ollama MCP customized agnet.
* Has prometheus scrape metrics at a cadence from the metrics-emitting service.
* Adds a grafana dash that shows the metrics.
* (not finished yet but was close: Starts a LLM session
* * Eg was trying to use Zed Editor's LLM plugin, that allows interfacing with prometheus and the metrics (currently though I had  trouble  hooking it to the local Ollama LLM IIRC..)
* * TODO: probably want to simply move to another IDE/messenger, like Slack to do this instead of Zed (plus Zed is barely even available on windows as of Nov 2025, only available on Mac)

# NOTES and STATUS
* This project is largely built originally off servutils_grafana_prometheus, and was a 'next step' exercise to try to integrate grafana-mcp.
* As of Nov 2025, I'm likely moving over to newer project first, servutils_n8n_grafana, which will leverage stuff I've already successfully implemented here.