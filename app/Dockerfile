# Small official Python base image
FROM python:3.12-alpine

# Don't write .pyc files; print logs immediately (important for kubectl logs)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first, so this layer is cached when only code changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Then copy the application code
COPY app.py .

# Run as a non-root user
RUN adduser -D -u 10001 appuser
USER 10001

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
