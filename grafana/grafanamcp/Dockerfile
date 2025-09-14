# grafana/grafanamcp/Dockerfile
# Custom Dockerfile, needed because apparently the stock mcp/grafana container from Grafana, may *not* include curl built in which I'm using for health checks (see docker-compose.yml)
FROM mcp/grafana

USER root
RUN apt-get update && apt-get install -y curl