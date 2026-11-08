---
name: next
description: Starts a build session (Phase 2 of the greenfield guide). Runs the start routine, picks the next feature from feature_list.json, routes it by mode (Superpowers writing-plans → subagent-driven-development / executing-plans, ultracode, spike or human), and hands over a ready-to-paste /goal once the human approves the plan. Use at the start of every build session ("next feature", "let's keep building", "continue the build").
argument-hint: "[optional F-ID]"
---

# /greenfield:next

One session = one feature. This skill **orchestrates** Superpowers; it doesn't replace it.

## 1. Start routine (always)
1. Read `claude-progress.txt` and `git log --oneline -10`.
2. Run `./init.sh`. If it fails, **stop**: this session's task becomes fixing the environment.
3. Regression: re-verify 1–2 features with `passes: true` (the ones most related to the next feature) using their `verify_cmd`.

## 2. Pick the feature
- If the user passed an ID, use it (check that its `depends_on` pass).
- Otherwise, take the first one with `status: "pending"` whose dependencies have `passes: true`.
- Tell the user in 2–3 plain lines: which feature it is, why it's next and how it will be verified.
- Set `status: "in_progress"`.

## 3. Route by `mode`
| `mode` | What to do |
|---|---|
| `sdd` | Invoke Superpowers `writing-plans`. When done, **summarize the plan in plain language** (what changes, what could go wrong, how we'll know it works) and ask for approval (**checkpoint 1**). Recommend *subagent-driven* execution |
| `inline` | Same, but recommend *inline* execution (`executing-plans`) |
| `ultracode` | `writing-plans` → approval → ask the user to turn on `/effort ultracode` |
| `spike` | Research session: options, trade-offs and a recommendation in `docs/decisions/NNNN-<topic>.md`. **Don't write production code.** End by asking the human for the decision |
| `human` | Prepare the evidence (demo, screenshots, transcripts) and a guide to what to look at. The human approves or requests changes |

## 4. Hand over the `/goal` (for `sdd`, `inline` and `ultracode`)
After checkpoint 1, show this block **for the user to paste** (Claude can't type `/` commands for the user), with the values filled in:

```
/goal Feature <ID> is complete per the approved plan in docs/superpowers/plans/:
all its tasks are closed in the ledger with an approved review (spec and quality);
`<verify_cmd>`, build, lint and test exit 0 with the output visible in the conversation;
passes: true in feature_list.json; claude-progress.txt updated; PR opened.
Only <ID>. If one of the 4 Superpowers stop cases comes up or you need a decision
from me, stop and ask me. Or stop after 40 turns.
```
Remind them to have **auto mode** on so it runs unattended.

## 5. Before wrapping up
- Apply `verification-before-completion`: no fresh `verify_cmd` output means it's not done.
- If the feature has `extra_review`: run `/security-review` (security), `/code-review` (code) or the `design` plugin's accessibility review (accessibility).
- If it has an interface: attach screenshots of the normal, empty, error and mobile states.
- `finishing-a-development-branch` → recommend **"open a PR"** (**checkpoint 2**).
- Show the list of **Rulings** (decisions made on the user's behalf) and **Deferred minors**.
- Update `feature_list.json` (`passes`, `status`) and add an entry at the top of `claude-progress.txt`.
- End the session. The next feature goes in a new session.
