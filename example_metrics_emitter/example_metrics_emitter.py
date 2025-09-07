# This script serves as a stub for a real server that would dump metrics to Prometheus.
# It exposes example metrics to Prometheus using the Prometheus client library.

# TODO: implement like below:
from prometheus_client import start_http_server, Gauge
import time, random

# define some example metrics
cpu_usage = Gauge('example_cpu_usage', 'Example CPU usage %')
memory_usage = Gauge('example_memory_usage', 'Example memory usage MB')
exampleMetricA = Gauge('exampleMetricA', 'exampleMetricA')

if __name__ == "__main__":
    # start metrics server
    start_http_server(8001)
    while True:
        cpu_usage.set(random.uniform(0, 100))
        memory_usage.set(random.uniform(100, 16000))
        exampleMetricA.set(random.uniform(1,200))
        time.sleep(5)
