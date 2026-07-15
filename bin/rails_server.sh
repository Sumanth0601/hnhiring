#!/bin/bash
set -e

APP_DIR="/Users/sumanth/Developer/hnhiring"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

echo "$LOG_PREFIX Starting hnhiring Rails server"

# ── 1. Ensure Docker Desktop is running ──────────────────────────────────────
if ! /usr/local/bin/docker info > /dev/null 2>&1; then
  echo "$LOG_PREFIX Docker not running — launching Docker Desktop..."
  open -a Docker

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

# ── 3. Remove stale puma pid/socket if present ───────────────────────────────
rm -f "$APP_DIR/tmp/pids/server.pid"
rm -f "$APP_DIR/tmp/sockets/puma.sock"

# ── 4. Start Rails server ────────────────────────────────────────────────────
export HOME="/Users/sumanth"
export PATH="/Users/sumanth/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export RAILS_ENV="development"

echo "$LOG_PREFIX Starting Rails on port 3000..."
cd "$APP_DIR"
exec /Users/sumanth/.local/bin/mise exec -- bundle exec rails server -p 3000 -b 127.0.0.1
