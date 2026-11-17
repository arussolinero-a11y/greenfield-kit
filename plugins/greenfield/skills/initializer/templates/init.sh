#!/usr/bin/env bash
# init.sh — starts the environment and checks that it's healthy. Adapt the marked lines to the project's stack.
set -euo pipefail
cd "$(dirname "$0")"

# ── Stack settings (the initializer fills these in from the spec and the stack) ──────────────
RUNTIME_CMD="node"                       # ← adapt: node, python3, go…
RUNTIME_MIN="20.0.0"                     # ← adapt: minimum version, also pinned in engines / .nvmrc / .python-version
SECRETS_FILES=(".env")                   # ← adapt: every local secrets file this stack uses (e.g. .env, .dev.vars, .env.local)
INSTALL="npm ci"                         # ← adapt
BUILD="npm run build"                    # ← adapt
START="npm run dev"                      # ← adapt (a single command)
PORT="3000"                              # ← adapt: the port the local server really uses
HEALTH_URL="http://localhost:${PORT}/health"   # ← adapt
READY_TIMEOUT=60                         # seconds to wait for the service
LOG_DIR=".cache"; LOG="$LOG_DIR/dev.log"

echo "▶ Checking the runtime version"
have="$("$RUNTIME_CMD" --version 2>/dev/null | grep -Eo '[0-9]+(\.[0-9]+){1,2}' | head -n1 || true)"
if [ -z "$have" ]; then echo "✗ $RUNTIME_CMD is not installed (need $RUNTIME_MIN or newer)"; exit 1; fi
if [ "$(printf '%s\n%s\n' "$RUNTIME_MIN" "$have" | sort -V | head -n1)" != "$RUNTIME_MIN" ]; then
  echo "✗ $RUNTIME_CMD $have is too old: this project needs $RUNTIME_MIN or newer"; exit 1
fi
echo "  $RUNTIME_CMD $have (minimum $RUNTIME_MIN)"

echo "▶ Installing dependencies"
bash -c "$INSTALL"

echo "▶ Checking local secrets files (contents are never printed)"
for f in "${SECRETS_FILES[@]}"; do
  [ -f "$f" ] || { echo "✗ Missing $f (copy $f.example, if there is one, and fill it in)"; exit 1; }
done

echo "▶ Build"
bash -c "$BUILD"

echo "▶ Starting the local service on port $PORT"
mkdir -p "$LOG_DIR"
bash -c "exec $START" > "$LOG" 2>&1 &   # exec: stopping DEV_PID stops the server itself
DEV_PID=$!
trap 'kill $DEV_PID 2>/dev/null || true' EXIT

echo "▶ Smoke test (waiting up to ${READY_TIMEOUT}s)"
for _ in $(seq 1 "$READY_TIMEOUT"); do
  if curl -fs "$HEALTH_URL" | grep -q '"ok"'; then echo "✅ Environment ready"; exit 0; fi
  if ! kill -0 "$DEV_PID" 2>/dev/null; then break; fi   # the server died: stop waiting
  sleep 1
done
echo "✗ Smoke test failed: $HEALTH_URL didn't answer \"ok\". Last lines of $LOG:"
tail -n 30 "$LOG" || true
exit 1
