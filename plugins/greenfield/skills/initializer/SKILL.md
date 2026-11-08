---
name: initializer
description: Adaptive initializer session (Phase 1 of the greenfield guide). Reads the spec plus the product and design docs, profiles the project, and generates the project's memory (feature_list.json, init.sh, claude-progress.txt, CLAUDE.md, hooks, verify/) WITHOUT implementing features. With --resync, reconciles a changed spec with feature_list.json. Use when starting a greenfield project after the spec is approved, or when the spec changed ("initialize the project", "run the initializer", "resync", "the spec changed").
argument-hint: "[--resync]"
---

# /greenfield:initializer

Implements Anthropic's *initializer agent* pattern ("Effective harnesses for long-running agents"), adapted to the spec instead of assuming a web app with 200 features.

## Inviolable rules
1. **Do not implement any feature.** Only a minimal skeleton, verification tooling and memory files.
2. **Do not commit until the human approves** the profile and the list.
3. Explain everything to the human **in plain language**: they may not be technical.
4. If the spec is missing, stop and recommend completing Phase 0 (guide §5).

## Default mode (initialize)

### Step 0 — Read the inputs
Find and read, in this order (whatever exists):
- Technical spec: `docs/superpowers/specs/*-design.md` (Superpowers) or `spec.md`
- `docs/product/PRD.md`, `docs/product/market-research.md`
- `docs/design/PRODUCT.md`, `docs/design/DESIGN.md`

If there are several candidate specs, ask which one to use.

### Step 1 — Profile → `docs/project-profile.md`
Answer: project type (web, API, conversational bot, CLI, library, data pipeline, mobile; can be mixed), external interfaces, risks (money, personal data, security, legal), non-deterministic AI behavior, technical unknowns, approximate size, and non-negotiable rules.

### Step 2 — Apply the decision matrix
Follow `references/decision-matrix.md` to decide:
- the verification strategy (which tooling goes in `verify/`);
- the size and order of the list (walking skeleton → spikes → design system → risks → value → instrumentation → polish);
- each feature's `mode` (`sdd`, `inline`, `ultracode`, `spike`, `human`);
- which non-negotiable rules become deterministic controls (hooks and deny rules) and which become judgment (`CLAUDE.md` + a verification feature).

### Step 3 — Generate the artifacts
Use the templates in `templates/` and adapt them to the spec's stack:

| File | Template | Notes |
|---|---|---|
| Minimal skeleton | — | build, lint and test green with an empty test |
| `init.sh` | `templates/init.sh` | installs dependencies, validates `.env`, starts the environment, smoke test |
| `feature_list.json` | `templates/feature_list.example.json` | schema in `references/feature-schema.md` |
| `claude-progress.txt` | `templates/claude-progress.txt` | first entry = this session |
| `CLAUDE.md` | `templates/CLAUDE.md` | short; includes the session routine |
| `.claude/settings.json` | `templates/settings.json` | Stop hook with typecheck/test; deny rules for secrets |
| `verify/` | — | per the matrix (simulator, e2e, evals…) |
| `docs/decisions/` | — | empty; spike ADRs go here |

If the project has an interface: add design-system features early (tokens and base components from `DESIGN.md`). For every feature with UI, add a visual-evidence step and an empty/error-state step.
If the PRD defines metrics: add instrumentation features.

### Step 4 — Human checkpoint
Show:
1. The profile, in 5–8 plain lines.
2. The feature list as a table: id, description, `mode`, `risk`, `depends_on`, `human_review`.
3. Questions that help the review: *Does each feature fit in one session? Do the steps test real behavior? Does the order make sense? Did subjective items end up as `human`?*

Wait for approval or changes. On approval: `git add` + commit `"chore: initialize project memory (greenfield initializer)"`.

## `--resync` mode (the spec changed)
1. Read the current spec, PRD and DESIGN, and `feature_list.json`.
2. Compute the diff:
   - **New** → add them with `status: "pending"` and `passes: false`.
   - **Obsolete** → `status: "deprecated"`. **Never delete them.**
   - **Affected** (their behavior changed) → `passes: false`, `status: "pending"` and updated steps, with a note in `history`.
   - **Unchanged** → don't touch them.
3. Show the diff in plain language and wait for approval. Then commit and add an entry to `claude-progress.txt`.

## What this skill does NOT do
- It doesn't write the spec. That's Phase 0: Superpowers `brainstorming`, `product-management`, Impeccable.
- It doesn't build features. That's Phase 2: `/greenfield:next`.
