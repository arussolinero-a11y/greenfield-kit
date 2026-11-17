#!/usr/bin/env bash
# init.sh — starts the environment and checks that it's healthy. Adapt the marked lines to the project's stack.
set -euo pipefail
cd "$(dirname "$0")"

# ── Stack settings (the initializer fills these in from the spec and the stack) ──────────────
RUNTIME_NAME="node"                      # ← adapt: node, python3, go…
RUNTIME_VERSION_CMD="node --version"     # ← adapt: "python3 --version", "go version"…
RUNTIME_PIN_FILE=".nvmrc"                # ← adapt: .nvmrc, .node-version, .python-version, .go-version… (single source of the minimum)
RUNTIME_MIN_FALLBACK="20.0.0"            # used only if the pin file doesn't exist
SECRETS_FILES=(".env")                   # ← adapt: every local secrets file this stack uses (e.g. .env, .dev.vars, .env.local)
INSTALL="npm ci"                         # ← adapt
BUILD="npm run build"                    # ← adapt
START="npm run dev"                      # ← adapt: one command, optionally with VAR=value prefixes (e.g. "PORT=3000 npm run dev")
PORT="3000"                              # ← adapt: the port the local server really uses
HEALTH_URL="http://localhost:${PORT}/health"   # ← adapt
READY_TIMEOUT=60                         # seconds to wait for the service
LOG_DIR=".cache"; LOG="$LOG_DIR/dev.log"

echo "▶ Checking the runtime version"
version_of() { grep -Eo '[0-9]+(\.[0-9]+){0,2}' | head -n1; }
version_ge() {   # true if $1 >= $2, comparing major.minor.patch numerically (portable, no sort -V)
  local IFS=.; local -a a=($1) b=($2); local i
  for i in 0 1 2; do
    local x=$(( 10#${a[i]:-0} )) y=$(( 10#${b[i]:-0} ))
    if (( x > y )); then return 0; elif (( x < y )); then return 1; fi
  done
  return 0
}
RUNTIME_MIN="$RUNTIME_MIN_FALLBACK"
if [ -f "$RUNTIME_PIN_FILE" ]; then RUNTIME_MIN="$(version_of < "$RUNTIME_PIN_FILE" || true)"; fi
[ -n "$RUNTIME_MIN" ] || RUNTIME_MIN="$RUNTIME_MIN_FALLBACK"   # e.g. a pin like "lts/iron" with no number
have="$(bash -c "$RUNTIME_VERSION_CMD" 2>/dev/null | version_of || true)"
if [ -z "$have" ]; then echo "✗ $RUNTIME_NAME is not installed (need $RUNTIME_MIN or newer)"; exit 1; fi
if ! version_ge "$have" "$RUNTIME_MIN"; then
  echo "✗ $RUNTIME_NAME $have is too old: this project needs $RUNTIME_MIN or newer ($RUNTIME_PIN_FILE)"; exit 1
fi
echo "  $RUNTIME_NAME $have (minimum $RUNTIME_MIN)"

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
bash -c "exec env $START" > "$LOG" 2>&1 &   # exec env: allows VAR=value prefixes; stopping DEV_PID stops the server itself
DEV_PID=$!
trap 'kill $DEV_PID 2>/dev/null || true' EXIT

echo "▶ Smoke test (waiting up to ${READY_TIMEOUT}s)"
deadline=$(( SECONDS + READY_TIMEOUT ))
while (( SECONDS < deadline )); do
  if curl -fs --max-time 2 "$HEALTH_URL" | grep -q '"ok"'; then echo "✅ Environment ready"; exit 0; fi
  if ! kill -0 "$DEV_PID" 2>/dev/null; then break; fi   # the server died: stop waiting
  sleep 1
done
echo "✗ Smoke test failed: $HEALTH_URL didn't answer \"ok\". Last lines of $LOG:"
tail -n 30 "$LOG" || true
exit 1
