#!/usr/bin/env bash
# init.sh — starts the environment and checks that it's healthy. Adapt to the project's stack.
set -euo pipefail

echo "▶ Installing dependencies"
npm ci                                   # ← adapt (pip install -r requirements.txt, etc.)

echo "▶ Validating environment variables"
[ -f .env ] || { echo "✗ Missing .env (copy .env.example and fill it in)"; exit 1; }

echo "▶ Build"
npm run build                            # ← adapt

echo "▶ Starting local service"
npm run dev > /tmp/dev.log 2>&1 &        # ← adapt
DEV_PID=$!
trap 'kill $DEV_PID 2>/dev/null || true' EXIT
sleep 5

echo "▶ Smoke test"
curl -fs http://localhost:3000/health | grep -q '"ok"' \
  && echo "✅ Environment ready" \
  || { echo "✗ Smoke test failed (see /tmp/dev.log)"; exit 1; }
