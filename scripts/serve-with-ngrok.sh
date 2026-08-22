#!/usr/bin/env bash
# Run Closr signaling on this laptop and expose it via free ngrok.
# Usage: ./scripts/serve-with-ngrok.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/backend"
PORT="${PORT:-3000}"

if ! command -v ngrok >/dev/null 2>&1; then
  echo "ngrok not found. Install: brew install ngrok"
  echo "Then: ngrok config add-authtoken <token from https://dashboard.ngrok.com/get-started/your-authtoken>"
  exit 1
fi

if ! curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
  echo "Starting backend on port ${PORT}..."
  (
    cd "$BACKEND"
    npm run build
    npm run start
  ) &
  BACKEND_PID=$!
  trap 'kill "$BACKEND_PID" 2>/dev/null || true' EXIT

  for i in $(seq 1 30); do
    if curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
      break
    fi
    sleep 0.5
  done

  if ! curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    echo "Backend failed to start on port ${PORT}"
    exit 1
  fi
  echo "Backend healthy."
else
  echo "Backend already running on port ${PORT}."
fi

echo ""
echo "Opening ngrok tunnel → http://127.0.0.1:${PORT}"
echo "Copy the https://….ngrok-free.app URL, then:"
echo "  1. Vercel → frontend env: VITE_BACKEND_URL=<that https url>"
echo "  2. Redeploy frontend (Vite bakes the URL at build time)"
echo "  3. backend/.env ALLOWED_ORIGINS must include https://closr-live.vercel.app"
echo ""
echo "Keep this laptop awake. Ctrl+C stops the tunnel (and backend if we started it)."
echo ""

exec ngrok http "${PORT}" --log=stdout
