import os
import socket
import time

import redis
from flask import Flask, Response, g, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = Flask(__name__)

# Connection settings come from environment variables:
#   REDIS_HOST, REDIS_PORT -> ConfigMap visit-counter-config
#   REDIS_PASSWORD         -> Secret visit-counter-secret
r = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    password=os.getenv("REDIS_PASSWORD") or None,  # gitleaks:allow - value is read from an env var, not hardcoded
    socket_connect_timeout=2,
    socket_timeout=2,
    decode_responses=True,
)

# --- Prometheus metrics -------------------------------------------------------
REQUESTS = Counter(
    "visit_counter_http_requests_total",
    "Total HTTP requests handled",
    ["method", "route", "status"],
)
LATENCY = Histogram(
    "visit_counter_http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["route"],
)


def endpoint_label():
    # Use the route pattern, never the raw path, to keep label cardinality bounded.
    return request.url_rule.rule if request.url_rule else "unmatched"


@app.before_request
def start_timer():
    g.start_time = time.perf_counter()


@app.after_request
def record_metrics(response):
    if request.path != "/metrics":
        endpoint = endpoint_label()
        LATENCY.labels(endpoint).observe(time.perf_counter() - g.start_time)
        REQUESTS.labels(request.method, endpoint, str(response.status_code)).inc()
    return response


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


# --- Application endpoints ----------------------------------------------------
@app.route("/")
def index():
    try:
        visits = r.incr("visits")
    except redis.RedisError as err:
        return jsonify(error="Redis unavailable", detail=str(err)), 503
    return jsonify(
        message="Hello from the visit counter, deployed by Jenkins!",
        visits=visits,
        pod=socket.gethostname(),
        version=os.getenv("APP_VERSION", "dev"),
    )


@app.route("/healthz")
def healthz():
    # Liveness: is this process alive? Deliberately does NOT check Redis.
    return jsonify(status="ok")


@app.route("/readyz")
def readyz():
    # Readiness: can this Pod serve real requests right now? Needs Redis.
    try:
        r.ping()
    except redis.RedisError as err:
        return jsonify(status="not ready", detail=str(err)), 503
    return jsonify(status="ready")