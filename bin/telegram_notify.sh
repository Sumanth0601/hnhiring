#!/bin/bash
set -e

APP_DIR="/Users/sumanth/Downloads/hnhiring"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

echo "$LOG_PREFIX Starting hnhiring telegram notify"

# ── 1. Ensure Docker Desktop is running ──────────────────────────────────────
if ! /usr/local/bin/docker info > /dev/null 2>&1; then
  echo "$LOG_PREFIX Docker not running — launching Docker Desktop..."
  open -a Docker

  # Wait up to 60 seconds for the Docker daemon to become ready
  WAIT=0
  until /usr/local/bin/docker info > /dev/null 2>&1; do
    sleep 2
    WAIT=$((WAIT + 2))
    if [ "$WAIT" -ge 60 ]; then
      echo "$LOG_PREFIX ERROR: Docker did not start within 60 seconds. Aborting."
      exit 1
    fi
  done
  echo "$LOG_PREFIX Docker is ready (waited ${WAIT}s)"
else
  echo "$LOG_PREFIX Docker is already running"
fi

# ── 2. Ensure the postgres container is up ───────────────────────────────────
cd "$APP_DIR"

if ! /usr/local/bin/docker compose ps postgres | grep -q "running"; then
  echo "$LOG_PREFIX Starting postgres container..."
  /usr/local/bin/docker compose up -d postgres
fi

# Wait for postgres to accept connections (up to 30 seconds)
WAIT=0
until /usr/local/bin/docker compose exec -T postgres pg_isready -d hnhiring_dev -q > /dev/null 2>&1; do
  sleep 2
  WAIT=$((WAIT + 2))
  if [ "$WAIT" -ge 30 ]; then
    echo "$LOG_PREFIX ERROR: Postgres did not become healthy within 30 seconds. Aborting."
    exit 1
  fi
done
echo "$LOG_PREFIX Postgres is ready"

# ── 3. Run the rake task ─────────────────────────────────────────────────────
export HOME="/Users/sumanth"
export PATH="/Users/sumanth/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

echo "$LOG_PREFIX Running rake telegram:notify_python_remote"
cd "$APP_DIR"
/Users/sumanth/.local/bin/mise exec -- bundle exec rake telegram:notify_python_remote
