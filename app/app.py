import os
import socket

import redis
from flask import Flask, jsonify

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


@app.route("/")
def index():
    try:
        visits = r.incr("visits")
    except redis.RedisError as err:
        return jsonify(error="Redis unavailable", detail=str(err)), 503
    return jsonify(
        message="Hello from the visit counter!",
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
