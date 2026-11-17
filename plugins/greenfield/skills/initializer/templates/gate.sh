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
FORMAT_CHECK=""                                  # ← adapt: e.g. "npx prettier --check ." or "ruff format --check"; empty = no formatter
TEST_AFFECTED="$TEST"                            # ← adapt: Vitest "npm test --silent -- --changed", Jest "npm test --silent -- --onlyChanged"; keep $TEST if the runner can't filter
DEPS_READY() { [ -d node_modules ]; }            # ← adapt (venv, vendor…)

MARKER_MAX_MIN=120                               # a marker older than this is treated as left over
MODE="${1:-full}"

if [ "$MODE" = "--hook" ] && [ -f .claude/subagent-active ]; then
  if [ -n "$(find .claude/subagent-active -mmin -"$MARKER_MAX_MIN" 2>/dev/null)" ]; then
    echo "gate: skipped — a subagent is working (.claude/subagent-active). The coordinator runs the gate after its delivery." >&2
    exit 0
  fi
  echo "gate: .claude/subagent-active is older than $MARKER_MAX_MIN min — treating it as left over and running the gate. Delete it if no subagent is working." >&2
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
[ -n "$FORMAT_CHECK" ] && step "format" "$FORMAT_CHECK"
step "lint" "$LINT"
if [ "$MODE" = "--affected" ]; then step "tests (affected)" "$TEST_AFFECTED"; else step "tests" "$TEST"; fi
echo "✅ gate green"
