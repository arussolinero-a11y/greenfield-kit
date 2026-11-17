---
name: build-path
description: Build-path assessment (Phase 2 of the greenfield guide). Measures the project (features left in the active release, independent dependency chains, test-suite duration, risk, remote or not), asks the person 4 plain-language questions, and recommends how to build - lean, lean-fast, lanes or guided - explaining why in non-technical terms. The person chooses; the choice is written to docs/build-path.md and /greenfield:next follows it. Use right after the initializer, before the first build session, or whenever the build feels too slow or expensive ("how should we build?", "choose a build path", "build path", "re-evaluate the build method").
argument-hint: ""
---

# /greenfield:build-path

Helps a person (often non-technical) choose **how** Phase 2 builds the product. It recommends; **the person decides**.
The greenfield guide ships with this plugin: `../../claude-code-greenfield-guide.md` (relative to this skill's folder). The build paths are described in guide §7.0.

## Rules
1. **Plain language.** No jargon in what you show the person. If you must use a technical word, explain it in the same sentence.
2. **Recommend, don't impose.** Always show the recommended path, one alternative, and why. The person picks.
3. **Don't build anything** and don't change `feature_list.json`. If a path needs a one-time setup feature, propose it; it's added through `/greenfield:initializer --resync` after the person agrees.
4. **Reference numbers are not promises.** They come from one pilot project; say so whenever you show them.

## Step 1 — Measure (on your own, no questions)
Read `feature_list.json`, `CLAUDE.md` (active release), `docs/project-profile.md`, `docs/build-path.md` and `docs/build-log.md` if they exist, then work out:

| Signal | How | Used for |
|---|---|---|
| Features left | `pending` + `in_progress` in the active release | Is a one-time setup worth it? (break-even ≈ 6 features) |
| Independent chains | From `depends_on` among the remaining features: how many groups don't depend on each other, and the longest chain | Can two features be built at once? |
| Test-suite time | Time one full run of the project's full test command (E2E included) if it exists; otherwise "not measurable yet" | Is waiting for tests a big part of each session? |
| Risk | Profile: money, personal data, security, legal | Reviewer checklist; when the guided path is worth it |
| Hand-off mode | `git remote` empty → local-only (guide §7.8) | Wording of the plan |
| Plugins in use | How many plugins are enabled for this project | Fixed cost added to every call |
| History | `docs/build-log.md`, if any: cost and time per feature, serious issues found later | Re-evaluation |

## Step 2 — Ask (4 questions, one block, plain words)
Ask them together, with short options:
1. **What matters most right now?** Spend less · Finish sooner · Control every step.
2. **How often can you approve things?** Several times a day · Once or twice a day · A few times a week.
3. **Does your Claude plan's usage limit worry you?** Yes, I hit it · Sometimes · No.
4. **Are you comfortable with two features being built at the same time?** It's faster but a bit harder to follow. Yes · Not yet.

## Step 3 — Recommend
Start from **lean** and move only when a rule below applies (first match wins for the main recommendation):

| If… | Recommend | Why, in one line |
|---|---|---|
| The person chose "Control every step" | **guided** | Most checkpoints. Warn: in the pilot it cost 3.5–6× the lean path without better quality |
| Remaining features ≥ 10 **or** the full test run takes more than ~5 minutes, **and** the person answered "Finish sooner" **and** "Yes" to Q4 **and** there are ≥ 2 independent chains | **lanes** (after the lean-fast setup) | Two features at a time; the setup pays for itself |
| Remaining features ≥ 10 **or** the full test run takes more than ~5 minutes | **lean-fast** | A one-time setup makes every later session faster and cheaper |
| Anything else | **lean** | Short sessions, one fresh reviewer per feature: the cheapest path that kept quality in the pilot |

Then adjust the advice (not the path):
- Approves only a few times a week → plan sessions to end with evidence ready, and keep building features that don't depend on pending approvals.
- Usage limit is a worry → avoid guided; with lanes, two lanes use the limit about twice as fast per hour.
- High risk in the profile → the reviewer's security checklist is mandatory on those features, whatever the path.
- Local-only project → mention that hand-offs are local merges (guide §7.8).

## Step 4 — Show and let the person choose
Show, in plain language (max ~15 lines):
1. The recommended path and one alternative, each in one sentence: what a session looks like and what the person will see.
2. Three reasons, tied to their answers and to what you measured.
3. Reference numbers from guide §7.0, labeled "from one pilot project, for comparison only".
4. What would make you recommend something else later (the re-evaluation signals below).

Ask the person to choose. Don't proceed without an answer.

## Step 5 — Record
1. Write `docs/build-path.md` from `templates/build-path.md`: chosen path, date, measured signals, answers, reasons, roles and models, setup needed, re-evaluation signals.
2. Update the `Build path:` line in `CLAUDE.md` (add it under "Scope" if missing).
3. If the path is lean-fast or lanes and the setup isn't done: propose the one-time setup feature (guide §7.0) and offer to add it with `/greenfield:initializer --resync`.
4. Offer the optional build log (`templates/build-log.md` → `docs/build-log.md`) so later re-evaluations use real numbers.
5. Commit `docs/build-path.md` and `CLAUDE.md` with the person's OK. Tell them the next step: a new session with `/greenfield:next`.

## Re-evaluation signals (checked by `/greenfield:next` at the start of each group of features)
Suggest running this skill again when any of these shows up:
- Cost or time per feature is well above the reference for the chosen path, for 2+ features in a row (compare with the same models: a pricier model is not a path problem).
- A serious issue (S1/S2) reached the person's own review or real use.
- The remaining features or their dependencies changed a lot (after `--resync`).
- The full test run got slow (more than ~5 minutes).
- The person's answers changed (time, budget, availability).

## What this skill does NOT do
- It doesn't build features or add them. That's `/greenfield:next` and `/greenfield:initializer --resync`.
- It doesn't run the setup for lean-fast or lanes; that's a regular feature.
