# CLAUDE.md — <project>

## Commands
- Install and start: `./init.sh`
- Build: `<cmd>` · Lint: `<cmd>` · Test: `<cmd>` · E2E: `<cmd>`
- Gate (before every commit, judged by exit code): `./scripts/gate.sh` (`--affected` during a task)
- Runtime: <runtime> ≥ <version> · Local port: <port> · Formatter: <tool and config | none>. Never reformat files outside your task.

## Languages
<!-- If CLAUDE.md already has a Languages section (written by /greenfield:discover), keep that one and drop this placeholder. -->
- Conversation: <language> · Documentation: <language> · Names in code: <language> · Interface copy: <language>
- Plans keep task headings as `Task N` in English (tools parse them).

## Scope
- Active release: `mvp` (only features with this `release` are built; later releases wait for `--resync`)
- Build path: <lean | lean-fast | lanes | guided> (chosen with `/greenfield:build-path`; details in docs/build-path.md)

## Non-negotiable rules
- <rule 1 — and how it's verified (feature F-xxx or hook)>
- <rule 2>

## Every-session routine (don't skip it)
1. Read `claude-progress.txt` and `git log --oneline -10`.
2. Run `./init.sh`. If anything fails, fix it BEFORE touching features.
3. Regression: re-verify 1–2 features with `passes: true`.
4. Take the first `pending` feature of the active release with no open dependencies and no pending `human_review` (or use `/greenfield:next`).
5. Run it according to its `mode` and the build path. One feature per session; never start a second one in the same session. Every feature gets a fresh reviewer on a different model; triage findings S1–S4 (backlog in docs/backlog.md).
6. `passes: true` only with the `verify_cmd` output visible. If a person still has to approve or act, the feature is `in_review`. Then update `claude-progress.txt` and end.
7. Before waiting a long time for a human (review, approval), wrap up first: commit, update the progress log and `feature_list.json`, end the session.

## Changes during the build
- A new design (for example, from a brainstorming session) updates the spec, then `/greenfield:initializer --resync`, then the group plan; never straight to a plan or to code.
- A real call with a person's credential follows guide §6.7: the script loads it at run time; never read, print or store it.

## feature_list.json
You may only change `passes`, `status`, `built_on_unapproved` and `history`. Never delete features or edit `steps`.

## Files that never go to git
- `.env` and `private/` (sensitive inputs). Never copy personal data from `private/` into code, docs or logs.

## References
- Product: docs/product/PRD.md · Design: docs/design/DESIGN.md · Decisions: docs/decisions/
