#!/usr/bin/env bash
# gate.sh — the project's single gate: typecheck + lint + tests. The exit code is the verdict.
#   ./scripts/gate.sh             full gate: before review, after each merge, before closing a feature
#   ./scripts/gate.sh --affected  quick gate during a task: only tests related to changed files
#   ./scripts/gate.sh --hook      used by the Stop hook: skipped while a subagent is working
# Adapt the four commands below to the project's stack.
set -uo pipefail
cd "$(dirname "$0")/.."

TYPECHECK="npm run -s typecheck"                 # ← adapt
LINT="npm run -s lint"                           # ← adapt
TEST="npm test --silent"                         # ← adapt
TEST_AFFECTED="npm test --silent -- --changed"   # ← adapt (or reuse TEST if the runner can't filter)
DEPS_READY() { [ -d node_modules ]; }            # ← adapt (venv, vendor…)

MODE="${1:-full}"

if [ "$MODE" = "--hook" ] && [ -f .claude/subagent-active ]; then
  echo "gate: skipped — a subagent is working (.claude/subagent-active). The coordinator runs the gate after its delivery." >&2
  exit 0
fi

if ! DEPS_READY; then
  echo "gate: dependencies are not installed — run ./init.sh first." >&2
  [ "$MODE" = "--hook" ] && exit 0 || exit 1
fi

step() {
  local name="$1" cmd="$2" out
  if ! out="$(bash -c "$cmd" 2>&1)"; then
    echo "✗ gate failed at: $name" >&2
    echo "$out" | tail -n 40 >&2
    exit 2
  fi
  echo "✓ $name"
}

step "typecheck" "$TYPECHECK"
step "lint" "$LINT"
if [ "$MODE" = "--affected" ]; then step "tests (affected)" "$TEST_AFFECTED"; else step "tests" "$TEST"; fi
echo "✅ gate green"
