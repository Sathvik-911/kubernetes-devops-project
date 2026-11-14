# Small official Python base image
FROM python:3.12-alpine

# Don't write .pyc files; print logs immediately (important for kubectl logs)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Create the non-root user early: this layer rarely changes, so it stays cached
RUN adduser -D -u 10001 appuser

# Install dependencies before copying code, so this layer is cached
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Version is set at build time: docker build --build-arg APP_VERSION=x.y.z
ARG APP_VERSION=dev
ENV APP_VERSION=$APP_VERSION

# Application code changes most often, so it goes last
COPY app.py .

USER 10001
EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
