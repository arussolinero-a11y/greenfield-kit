---
name: next
description: Starts a build session (Phase 2 of the greenfield guide). Runs the start routine, picks the next feature from feature_list.json, and builds it on the build path recorded in docs/build-path.md (lean, lean-fast, lanes or guided), with checkpoints in plain language, a fresh reviewer per feature and severity triage. With "fixes", runs a fix session for problems the human found in their own review. Use at the start of every build session ("next feature", "let's keep building", "continue the build", "fix what I found").
argument-hint: "[optional F-ID | fixes]"
---

# /greenfield:next

One session = one feature, in a fresh context. This skill **orchestrates**: it follows the build path the human chose and uses Superpowers where that path calls for it.
The greenfield guide ships with this plugin: `../../claude-code-greenfield-guide.md` (relative to this skill's folder). Section numbers below (§) refer to it; the build paths are in §7.0.

**Never chain features.** If this session already built a feature, don't start another: tell the user to open a new session and run `/greenfield:next` there. (The `lanes` coordinator is the only exception, and it doesn't write code.)

## 1. Start routine (always)
1. Read `claude-progress.txt` and `git log --oneline -10`.
2. Detect the hand-off mode: if `git remote` prints nothing, this is a **local-only** project (guide §7.8). Say so in one line; it changes the hand-off in section 5. A repo with a remote is never local-only: if `gh` isn't installed, push the branch and open the PR on the website or through a GitHub connector.
3. Read the build path in `docs/build-path.md` (and the `Build path:` line in `CLAUDE.md`). If there is none, recommend running `/greenfield:build-path` first. If the user prefers to go on without it:
   - **project already being built** (some feature has `passes: true`, or `docs/superpowers/plans/` exists; it was set up before build paths existed) → keep `guided`, the flow it was using;
   - **new project** → use `lean`.

   Say which one you're using, and never switch paths without the user's explicit choice.
4. Run `./init.sh`. If it fails, **stop**: this session's task becomes fixing the environment.
5. Regression: re-verify 1–2 features with `passes: true` (the ones most related to the next feature) using their `verify_cmd`. If none has passed yet, the regression is the `init.sh` smoke test; note that in the progress log.

If the argument is `fixes`, skip sections 2 and 3 and run a **fix session** (guide §7.10) on a branch `fixes/<YYYY-MM-DD>`:
1. List what the human reported, in their words, and triage it (§7.9).
2. Adjust the plan only if a contract changes; otherwise fix directly.
3. One fresh reviewer per fix, on a different model; one full gate and `verify_cmd` at the end.
4. Then sections 4 and 5 apply as for a feature: extra reviews, hand-off (PR, or local merge after the user's OK), progress log, end the session.
5. Finish with a short checklist telling the human what to re-check, where and how.

## 2. Pick the feature
- Read the active release in `CLAUDE.md` (no line there = `mvp`). Features of other releases are out of the build path.
- If the user passed an ID, use it (check that its `depends_on` pass). If it belongs to another release, say so and ask before going on.
- Otherwise, take the first one of the active release with `status: "pending"` whose dependencies have `passes: true`.
- If the only blocker is a dependency still `in_review` (waiting for the person), ask whether to build on it anyway. If they agree, record it in the feature's `built_on_unapproved`. When that dependency is approved or changes, re-run this feature's `verify_cmd` and clear the entry.
- If a feature has `built_on_unapproved` entries whose dependencies are now approved or changed, re-verify it first (that's this session's regression).
- If a pending feature of the active release depends on a feature of a later release, it can never be built: don't skip it silently. Tell the user and propose `/greenfield:initializer --resync` to move the dependency into the active release or remove it.
- **Starting a new group of features?** On the lean paths, that's when no approved plan in `docs/plans/` lists this feature in its `Covers:` line, or when it's the first unfinished feature of its plan. On `guided`, it's when the feature's `category` differs from the last one built. Then check the re-evaluation signals in `../build-path/SKILL.md`, using `docs/build-log.md` if it exists. If one shows up, suggest re-running `/greenfield:build-path` before going on. Also review `docs/backlog.md`: propose any backlog items worth folding into this group's plan.
- Tell the user in 2–3 plain lines: which feature it is, why it's next and how it will be verified.
- Set `status: "in_progress"`.
- Scratch space: each agent (this session included) uses its own subfolder of the session's scratch directory, named after the feature and role (`<F-ID>-implementer/`, `<F-ID>-reviewer/`), and deletes only what it created.

## 3. Build it — by `mode`, then by build path
Modes `spike`, `human`, `inline` and `ultracode` are exceptions and work the same on every path:

| `mode` | What to do |
|---|---|
| `spike` | Research session: options, trade-offs and a recommendation in `docs/decisions/NNNN-<topic>.md`. **Don't write production code.** End by asking the human for the decision. Until they decide, the spike is `in_review`; the approved ADR is its evidence (record the decision in `history`, then `done` and `passes: true`). Commit the ADR on a branch and hand it off like any feature |
| `human` | Prepare the evidence (demo, screenshots, transcripts) and a guide to what to look at. The human approves or requests changes |
| `inline` | A short plan, approval, then build in this session with a single review at the end |
| `ultracode` | Plan → approval → ask the user to turn on `/effort ultracode` |

For `sdd` features (the usual case), follow the build path:

### `lean` and `lean-fast`
1. **Plan check.** Look in `docs/plans/` for a plan with `Status: approved` whose `Covers:` line lists this feature. If there is one, build against it. If not, this session is the **plan session**:
   - choose the group: this feature plus related pending features of the active release (same area or dependency chain, usually 3–8);
   - write `docs/plans/<group>.md` from `references/plan-template.md` (on `lean-fast`, the project's planner agent can do it). It covers contracts, external constants with source and date, thresholds measured against approved artifacts, steps that wait for a person, tasks that each end green, and the reviewer checklist. Superpowers `writing-plans` is fine if you ask for contracts instead of full code;
   - if several group plans are being written at once, add the coherence pass (template §9) before approval;
   - summarize it in plain language and ask for approval (**checkpoint 1**). On approval, add `Status: approved <date>`;
   - commit it and end the session. Building starts in a fresh one.
2. **Build** following `references/agents/implementer.md`:
   - On `lean`, this session is the implementer.
   - On `lean-fast`, delegate to the project's implementer agent. Quote the plan's contracts in the brief **literally**: never paraphrase them, never add rules. While it works, create `.claude/subagent-active` so the Stop hook doesn't flag its red tests, and remove the marker when it reports. Then run `./scripts/gate.sh` yourself.
   - Pass the **Contracts changed** section of each report on to the briefs of later tasks.
3. **Review:**
   - First run the full `verify_cmd` (every width or variant). If the feature has end-to-end tests, run it twice in a row.
   - Then launch one fresh, read-only reviewer on a **different model from the implementer**, set explicitly: the project's reviewer agent, or a subagent with an explicit model option using `references/agents/reviewer.md` as its instructions. A plain subagent inherits this session's model and doesn't count.
   - Give it the diff, the plan and its checklist (with the security items for `extra_review: security` or high risk).
   - Note which model reviewed; if only one model is available, say so.
4. **Triage** (guide §7.9): fix S1 and S2; fix S3 only if cheap; send the rest to `docs/backlog.md` (template `../build-path/templates/backlog.md`). Re-review only if an S1 or S2 was fixed.
5. Go to section 5.

On `lean-fast`, if the one-time setup feature isn't done yet, build it first: it's in the list as a regular `infra` feature. Besides speeding up tests, it copies `references/agents/*.md` into the project's `.claude/agents/` (adjusting models and tools if needed). Agents added mid-session may only show up in a new session.

### `lanes`
This session is the **coordinator**. It doesn't write code.
- Pick two features from independent chains whose plans are approved.
- Give each lane its own worktree, port and local data, and its own implementer agent. Pass contracts literally (never paraphrase or add rules) and forward each report's **Contracts changed** to the other lane.
- One fresh reviewer per feature, on a different model, as in the lean paths.
- Merge each finished lane into the integration branch `integration/<group>` (created from the main branch; never merge lanes straight into the main branch). Run the full gate and `verify_cmd` yourself after each merge.
- Hand-off of the integration branch (checkpoint 2): with a remote, push it and open one PR to the main branch; local-only, merge it into the main branch after the user's OK.
- Follow the coordinator rules in guide §7.0: freeze the integration branch while a lane catches up, quote contracts literally, give each agent its own scratch subfolder.
- After each feature: update `feature_list.json` and `claude-progress.txt` and commit, so a usage-limit cut never loses state.
- If a subagent is cut off (network, usage limit): check `git status` and `git log` in its worktree, then resume **the same** subagent with a message saying what's done and what's left, rather than starting a new one without context.
- If merges get slow, or cost per feature climbs above the reference, say so and suggest going back to `lean-fast`.

### `guided`
1. Invoke Superpowers `writing-plans`. When done, **summarize the plan in plain language** (what changes, what could go wrong, how we'll know it works) and ask for approval (**checkpoint 1**). Recommend *subagent-driven* execution.
2. After checkpoint 1, show this block **for the user to paste** (Claude can't type `/` commands for the user), with the values filled in:

```
/goal Feature <ID> is complete per the approved plan in docs/superpowers/plans/:
all its tasks are closed in the ledger with an approved review (spec and quality);
`<verify_cmd>`, build, lint and test exit 0 with the output visible in the conversation;
<CLOSE>; claude-progress.txt updated; <HANDOFF>.
Only <ID>. If one of the 4 Superpowers stop cases comes up or you need a decision
from me, stop and ask me. Or stop after 40 turns.
```
Fill in `<CLOSE>` (depends on `human_review`) and `<HANDOFF>` (depends on the hand-off mode from step 1.2) with the exact texts in the table of guide §7.3, before showing the block. A goal that can never be met keeps the session running for nothing. Remind them to have **auto mode** on so it runs unattended.

3. When `subagent-driven-development` finishes, add one fresh reviewer on a **different model** for the whole feature diff (its per-task reviewers share this session's model), set explicitly as in the lean paths. Triage all findings the same way (§7.9).

## 4. Extra reviews
If the feature has `extra_review`:
- `security`: run `/security-review`. In a local-only project it doesn't work (it needs a remote): have a fresh read-only reviewer check `git diff <main-branch>...feature/<ID>` against `references/local-security-checklist.md`, and list its findings. A high finding blocks the merge.
- `code`: run `/code-review`.
- `accessibility`: run the `design` plugin's accessibility review.

## 5. Before wrapping up
- Apply `verification-before-completion`: no fresh `verify_cmd` output means it's not done.
- If the feature has `requires_human_action`, or a step from the plan's "steps that wait for a person": run its closing check (`verify/close-<ID>.sh`) with the output visible, or record the person's confirmation in `history`. Otherwise the feature stays `in_review`.
- If it has an interface: attach screenshots of the normal, empty, error and mobile states.
- Hand-off (**checkpoint 2**):
  - With a remote: recommend **"open a PR"** (`finishing-a-development-branch` on `guided`).
  - Local-only: show the summary and evidence, and merge the branch into the main branch only after the user approves. Never commit features straight to the main branch.
- Show:
  - the **Rulings** (decisions made on the user's behalf);
  - findings fixed by severity;
  - what went to the backlog.
- Update `feature_list.json`:
  - `done` + `passes: true` only with the evidence;
  - `in_review` while a person's approval or action is pending, with a `history` note saying what it waits for.

  Add an entry at the top of `claude-progress.txt`. If `docs/build-log.md` exists, add the session's row (path, minutes, usage, models, findings).
- If the session is cut short (usage limit, error), write a provisional progress entry first: what's done, what's committed, what's left.
- End the session. The next feature goes in a new session.
- If the feature now waits for a human (review, approval, an external step), say so and end the session now rather than waiting in it.
