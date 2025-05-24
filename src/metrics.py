from prometheus_client import Counter

gandalf_requests = Counter(
    "gandalf_requests_total", "Total number of requests to /gandalf"
)
colombo_requests = Counter(
    "colombo_requests_total", "Total number of requests to /colombo"
)
