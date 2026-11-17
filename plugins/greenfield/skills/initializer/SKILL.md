---
name: initializer
description: Adaptive initializer session (Phase 1 of the greenfield guide). Reads the spec plus the product and design docs, profiles the project, and generates the project's memory (feature_list.json, init.sh, claude-progress.txt, CLAUDE.md, hooks, verify/) WITHOUT implementing features. With --resync, reconciles a changed spec with feature_list.json. Use when starting a greenfield project after the spec is approved, or when the spec changed ("initialize the project", "run the initializer", "resync", "the spec changed").
argument-hint: "[--resync]"
---

# /greenfield:initializer

Implements Anthropic's *initializer agent* pattern ("Effective harnesses for long-running agents"), adapted to the spec instead of assuming a web app with 200 features.

The greenfield guide ships with this plugin: `../../claude-code-greenfield-guide.md` (relative to this skill's folder). Section numbers below (§) refer to it.

## Inviolable rules
1. **Do not implement any feature.** Only a minimal skeleton, verification tooling and memory files.
2. **Do not commit until the human approves** the profile and the list.
3. Explain everything to the human **in plain language**: they may not be technical.
4. If the spec is missing, stop and recommend completing Phase 0 with `/greenfield:discover` (guide §5).
5. **Never overwrite a file that already exists** (`.claude/settings.json`, `CLAUDE.md`, `.gitignore`, `init.sh`, anything else). Merge instead: keep every existing permission, hook, rule and line; add only what's missing; show the human the diff and wait for their OK. If a clean merge isn't possible, ask.

## Default mode (initialize)

### Step 0 — Read the inputs
Find and read, in this order (whatever exists):
- Technical spec: `docs/superpowers/specs/*-design.md` (Superpowers) or `spec.md`
- `docs/product/PRD.md` (including its core and roadmap), `docs/product/market-research.md` or `docs/product/benchmark.md`
- `docs/product/integrations.md`: every entry marked `spike: yes` becomes a `spike` feature, and its limits and costs go into the profile's risks
- `docs/design/PRODUCT.md`, `docs/design/DESIGN.md`, `docs/design/handoff.md`: per-screen states and edge cases become feature steps

If there are several candidate specs, ask which one to use.
**Languages:** check that `CLAUDE.md` has a "Languages" section with all four decisions (conversation, documentation, code names, interface copy; guide §5). If it's missing or incomplete, ask the human before generating anything and record the answers there. If the section already exists, it wins over the template's placeholder section when merging: never add a second one.
Write prose (descriptions, steps, docs, the progress log) in the documentation language. Keep the machine-read parts exactly as the schema and templates define them: JSON keys, enum values (`pending`, `in_review`, `mvp`…), file and folder names, and `Task N` headings.
The MVP cut comes before the list (guide §5.2). Never turn the whole PRD or spec into one build list:
- PRD with a roadmap that assigns each requirement to a release (MVP → next → later): use it.
- PRD without a roadmap: stop and help the human add one first.
- No PRD (spec only): before profiling, list the spec's capabilities in plain language and ask the human which ones are in the MVP and what the core is. Record the answer in `docs/product/roadmap.md` and use it as the roadmap.

### Step 1 — Profile → `docs/project-profile.md`
Answer: project type (web, API, conversational bot, CLI, library, data pipeline, mobile; can be mixed), external interfaces, risks (money, personal data, security, legal), non-deterministic AI behavior, technical unknowns, approximate size, and non-negotiable rules.

### Step 2 — Apply the decision matrix
Follow `references/decision-matrix.md` to decide:
- the verification strategy (which tooling goes in `verify/`);
- the `release` of each feature, from the PRD roadmap (`mvp`, `v2`…); only the MVP is the build path. No feature may depend on a feature of a later release: move the dependency into the earlier release or ask the human;
- the size and order of the MVP list (walking skeleton → spikes → design system → risks → value, starting with the core → instrumentation → polish);
- each feature's `mode` (`sdd`, `inline`, `ultracode`, `spike`, `human`);
- which non-negotiable rules become deterministic controls (hooks and deny rules) and which become judgment (`CLAUDE.md` + a verification feature).

### Step 3 — Generate the artifacts
Use the templates in `templates/` and adapt them to the spec's stack:

| File | Template | Notes |
|---|---|---|
| Minimal skeleton | — | build, lint and test green with an empty test |
| `init.sh` | `templates/init.sh` | installs dependencies, validates `.env`, starts the environment, smoke test |
| `feature_list.json` | `templates/feature_list.example.json` | schema in `references/feature-schema.md`; every feature has a `release` |
| `claude-progress.txt` | `templates/claude-progress.txt` | first entry = this session |
| `CLAUDE.md` | `templates/CLAUDE.md` | short; includes the session routine and the active release (`mvp`) |
| `scripts/gate.sh` | `templates/gate.sh` | the single gate (typecheck + lint + tests; `--affected` for the quick per-task run). Adapt the commands to the stack |
| `.claude/settings.json` | `templates/settings.json` | Stop hook running `gate.sh --hook` (skipped while a subagent works); deny rules for secrets. **If the file exists, merge** (rule 5) |
| `.gitignore` | — | must include `.env`, `private/` (sensitive inputs, guide §5) and `.claude/subagent-active`; merge if it exists |
| `verify/` | — | per the matrix (simulator, e2e, evals…) |
| `docs/decisions/` | — | empty; spike ADRs go here |

If the project has an interface: add design-system features early (tokens and base components from `DESIGN.md`). For every feature with UI, add a visual-evidence step, an empty/error-state step, and an end-to-end step without intercepted or mocked responses (against the real local backend, if the project has one) that checks what the user sees after each main action.
If a feature needs something only a person can do or authorize (deploy, a live migration, a real call with their credential, writing to an external service), list it in `requires_human_action` and keep `verify_cmd` local.
If the PRD defines metrics: add instrumentation features.

### Step 4 — Human checkpoint
Show:
1. The profile, in 5–8 plain lines.
2. The MVP feature list as a table: id, description, `mode`, `risk`, `depends_on`, `human_review`. Below it, a short count of the features recorded for later releases.
3. Any merge diffs for files that already existed (rule 5).
4. Questions that help the review: *Could the user start using the product after the MVP? Is the core in it? Is anything in the MVP that could wait? Does each feature fit in one session? Do the steps test real behavior? Does the order make sense? Did subjective items end up as `human`?*

Wait for approval or changes. On approval: `git add` + commit `"chore: initialize project memory (greenfield initializer)"`.
Then tell the human the next step: run `/greenfield:build-path` to choose how to build (guide §7.0), and start building in a fresh session with `/greenfield:next`.

## `--resync` mode (the spec or the scope changed)
Use it when the spec changes, when the scope changes (features moved between releases, or a later release promoted to active), and to add a **process feature** the human approved that doesn't come from the spec, such as the `lean-fast` setup proposed by `/greenfield:build-path`.

It also brings the project's **controls** up to date with the plugin version. If `scripts/gate.sh` is missing, add it from `templates/gate.sh`. If the Stop hook doesn't run `gate.sh --hook`, update it. If `.gitignore` lacks `private/` or `.claude/subagent-active`, add them. All of this follows rule 5: merge, show the diff, ask.
1. Read the current spec, PRD (with its roadmap) and DESIGN, and `feature_list.json`.
2. Compute the diff:
   - **New** → add them with `status: "pending"` and `passes: false`.
   - **Obsolete** → `status: "deprecated"`. **Never delete them.**
   - **Affected** (their behavior changed) → `passes: false`, `status: "pending"` and updated steps, with a note in `history`.
   - **Moved to another release** → update `release`, with a note in `history`. This is not deprecation. Then check dependencies: a feature can't depend on one of a later release; move the dependency too or ask.
   - **Approved process feature** (not from the spec) → add it with `category: "infra"`, the active release, `status: "pending"`, `passes: false`, and a `history` note saying who proposed it and why.
   - **Unchanged** → don't touch them.
3. Show the diff in plain language and wait for approval. If the active release changed, update it in `CLAUDE.md`. Then commit and add an entry to `claude-progress.txt`.

## What this skill does NOT do
- It doesn't write the spec. That's Phase 0: `/greenfield:discover`, with Superpowers `brainstorming`, `product-management`, Impeccable.
- It doesn't choose how to build. That's `/greenfield:build-path`.
- It doesn't build features. That's Phase 2: `/greenfield:next`.
