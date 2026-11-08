# CLAUDE.md — <project>

## Commands
- Install and start: `./init.sh`
- Build: `<cmd>` · Lint: `<cmd>` · Test: `<cmd>` · E2E: `<cmd>`

## Non-negotiable rules
- <rule 1 — and how it's verified (feature F-xxx or hook)>
- <rule 2>

## Every-session routine (don't skip it)
1. Read `claude-progress.txt` and `git log --oneline -10`.
2. Run `./init.sh`. If anything fails, fix it BEFORE touching features.
3. Regression: re-verify 1–2 features with `passes: true`.
4. Take the first `pending` feature with no open dependencies and no pending `human_review` (or use `/greenfield:next`).
5. Run it according to its `mode`. One feature per session.
6. `passes: true` only with the `verify_cmd` output visible. Then update `claude-progress.txt` and end.

## feature_list.json
You may only change `passes`, `status` and `history`. Never delete features or edit `steps`.

## References
- Product: docs/product/PRD.md · Design: docs/design/DESIGN.md · Decisions: docs/decisions/
