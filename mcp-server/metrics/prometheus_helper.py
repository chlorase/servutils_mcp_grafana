#TODO: below is a intiial sample, may or not need chagnes.
import requests
from typing import Dict, List

def query_prometheus(prometheus_url: str, promql: str, start_ts: int, end_ts: int, step_sec: int) -> Dict[str, List]:
    """
    Query Prometheus over a time range and return the data points in a simple dict format.
    
    :param prometheus_url: Base URL of Prometheus, e.g. http://localhost:9090
    :param promql: PromQL query string, e.g. 'exampleMetricA{instance="servutils_example-metrics:8001"}'
    :param start_ts: Start time as UNIX timestamp (seconds)
    :param end_ts: End time as UNIX timestamp (seconds)
    :param step_sec: Step size in seconds
    :return: Dict with 'timestamps' and 'values' lists

        Sample response:
        {
            "metric": { "instance": "servutils_example-metrics:8001", ... },
            "timestamps": [...],
            "values": [...]
        }

    """
    api_url = f"{prometheus_url}/api/v1/query_range"
    params = {
        "query": promql,
        "start": start_ts,
        "end": end_ts,
        "step": step_sec
    }

    response = requests.get(api_url, params=params)
    response.raise_for_status()
    data = response.json()

    if data["status"] != "success":
        raise RuntimeError(f"Prometheus query failed: {data}")

    # Support multiple series (but flatten for simplicity)
    results = []
    for series in data["data"]["result"]:
        metric_labels = series.get("metric", {})
        values = series.get("values", [])  # list of [timestamp, value_str]
        results.append({
            "metric": metric_labels,
            "timestamps": [float(v[0]) for v in values],
            "values": [float(v[1]) for v in values]
        })

    return results