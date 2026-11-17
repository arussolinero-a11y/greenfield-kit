---
name: discover
description: Guides Phase 0 of the greenfield guide (product, UX/UI and spec) one sub-phase per session - 0A market research or product/UX benchmark, 0B PRD with MVP and roadmap, 0C UX/UI with the prototype gate and design handoff, an integration check, and 0D technical spec with a builder review loop. Keeps a hand-off file (docs/phase0-status.md) so each session starts fresh, records language decisions, and handles going back to an earlier sub-phase. Use at the very start of a greenfield project or to continue Phase 0 ("start a new project", "phase 0", "discover", "next sub-phase", "reopen the PRD").
argument-hint: "[0A | 0B | 0C | integrations | 0D | status | reopen <sub-phase>]"
---

# /greenfield:discover

Phase 0 orchestrator. The human decides; Claude asks, researches, drafts and checks. **One sub-phase per session.**
The greenfield guide ships with this plugin: `../../claude-code-greenfield-guide.md` (relative to this skill's folder). Phase 0 is guide §5.

## Rules
1. **Plain language.** The person may not be technical.
2. **One sub-phase per session.** End each one by updating `docs/phase0-status.md`, committing with the person's OK, and telling them to continue in a fresh session. Delegate heavy reading (long research, many pages) to subagents and keep only their summaries in this session.
3. **No implementation, no `/goal`, no implementation ultracode** in Phase 0 (`/deep-research` is fine).
4. **Sensitive inputs stay in `private/`** (git-ignored), never at the repo root, and are never copied into deliverables (guide §5).
5. **Never edit an approved deliverable silently.** Changes to an earlier sub-phase go through "reopen" (below).

## Start: read the status
Read `docs/phase0-status.md` (template: `templates/phase0-status.md`). If it doesn't exist, this is the **first session**: run "Set-up". Otherwise continue with the sub-phase it says is next, or the one passed as argument. `status` only summarizes where Phase 0 stands.

## Set-up (first session only)
1. Create `private/` and make sure `.gitignore` lists it before the first commit. Research notes go in `docs/product/research/`.
2. **Languages.** Ask and record four decisions in `CLAUDE.md`, under a "Languages" section:
   - the conversation;
   - the documentation;
   - names in the code;
   - the product's interface copy.

   Explain the cost of each choice in one line. For example, docs in a different language from the interface means quoting interface text and keeping a glossary. The same language as the people who will read it is usually best.
   - Note in the same section: plans keep task headings as `Task N` in English, because tools parse them, even if the rest is in another language.
3. **Will the product be sold?**
   - Yes → 0A market research.
   - No → offer the 0A **product and UX benchmark** (optional; useful to borrow structure and patterns from existing apps) or skip to 0B.
4. Create `docs/phase0-status.md` and commit.

## 0A — Market research or product/UX benchmark
- **Sold:** follow guide §5.1 (market landscape, competition, customer, differentiation, go/no-go). Output: `docs/product/market-research.md`.
- **Not sold (benchmark):** study 3–6 existing products for structure, flows, UX patterns, look and feel, and anti-patterns to avoid. No market size, no pricing, no go/no-go. Output: `docs/product/benchmark.md` (template `templates/benchmark.md`).
- Record every decision the person makes here (visual references, patterns to copy or avoid) under "Decisions carried forward" in the status file. 0C reuses them.

## 0B — Product (PRD)
Follow guide §5.2: full or lite, always with **the core** and a **roadmap** that assigns each requirement to MVP, next release or later. Apply the MVP rule. Output: `docs/product/PRD.md`.

## 0C — UX/UI
1. **Prefill** the mandatory questions (guide §5.3) with the answers already given in 0A and 0B. Show them as "already decided: … — confirm or change", and ask only what's still open.
2. **Tools.** Before designing, check which recommended tools are installed (guide §5.5), say which ones you'll use, and record them in the status file ("used" / "not installed → alternative used"). Don't skip a quality step silently because a tool is missing.
3. Deliverables: `docs/design/PRODUCT.md`, `docs/design/DESIGN.md`, the key flows and, if applicable, a prototype.
4. **Prototype gate** (guide §5.3) before asking for approval: the coverage matrix, the design and accessibility reviews, and the minimum criteria.
5. **Design handoff:** after approval, write `docs/design/handoff.md` with the `design` plugin's `/handoff` or equivalent: behavior per screen, states, interactions, edge cases. 0D reads it.

## Integration check (between 0C and 0D)
If the product talks to external systems (APIs, data providers, payment, auth, AI services), check each one before the spec. Use `templates/integrations.md` and write `docs/product/integrations.md`. For each integration, record:
- how access works and what auth it needs;
- limits, quotas and costs, with the source and the date checked;
- what's still unknown.

If a provider's docs can't be read automatically, ask the person to save the pages into `private/` and read them from there. Unknowns become `spike` features in Phase 1.

## 0D — Technical spec
1. Superpowers `brainstorming` (or the interview prompt in guide §5.4) reads:
   - `docs/product/*`, including the integration check;
   - `docs/design/*`, including the handoff.

   The spec references those documents; it doesn't repeat them.
2. **Builder review loop.** A fresh read-only reviewer subagent checks the spec against `references/spec-review-checklist.md`. If Superpowers ships a spec-reviewer template, use it together with the checklist. Fix, then review again with a **fresh** reviewer. Repeat until it approves: fixes often introduce new contradictions, and the second pass catches them.
3. The person approves the spec. Phase 0 is done: tell them to run `/greenfield:initializer` in a fresh session.

## Reopen an earlier sub-phase (`reopen <sub-phase>`)
When a later sub-phase changes something already approved (for example, 0D shows the PRD must change):
1. Write the change and its reason under "Pending cascades" in the status file.
2. Update the documents **in order**, each re-approved by the person before moving on:
   - PRD;
   - DESIGN and flows;
   - prototype (the gate runs again);
   - integration check (if affected);
   - spec (with the review loop again).
3. Clear the cascade entry when the last affected document is re-approved.

After Phase 1 has started, scope changes go through `/greenfield:initializer --resync` instead (guide §10).

## What this skill does NOT do
- It doesn't initialize the project or build anything. That's `/greenfield:initializer` and Phase 2.
