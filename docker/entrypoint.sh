#!/usr/bin/env sh
set -eu

mkdir -p data/gallery data/logs data/samples models

# With arguments: run them (e.g. docker compose run gaitpass python3 scripts/...).
# Without arguments: start the dashboard.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi
exec python3 -m uvicorn app.main:app --host 0.0.0.0 --port "${APP_PORT:-18080}"
