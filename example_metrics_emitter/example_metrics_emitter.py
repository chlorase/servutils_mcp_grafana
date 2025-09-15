# example_metrics_emitter.py
# This script serves as a stub for a real server that would dump metrics to Prometheus.
# It exposes example metrics to Prometheus using the Prometheus client library.

from prometheus_client import start_http_server, Gauge
import time, random

# define some example metrics
cpu_usage = Gauge('example_cpu_usage', 'Example CPU usage %')
memory_usage = Gauge('example_memory_usage', 'Example memory usage MB')
exampleMetricA1 = Gauge('exampleMetricA1', 'exampleMetricA1')
exampleMetricA2 = Gauge('exampleMetricA2', 'exampleMetricA2')

if __name__ == "__main__":
    # start metrics server
    start_http_server(8001)
    while True:
        cpu_usage.set(random.uniform(0, 100))
        memory_usage.set(random.uniform(100, 16000))
        exampleMetricA1_value = random.uniform(1, 200)
        exampleMetricA1.set(exampleMetricA1_value)
        exampleMetricA2.set(exampleMetricA1_value * 1.3 + random.uniform(-5, 5))  # introduce some randomness to simulate real-world data
        time.sleep(5)