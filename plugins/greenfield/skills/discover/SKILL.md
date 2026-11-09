---
name: discover
description: Orchestrates Phase 0 of the greenfield guide end to end — market research and a go/no-go gate (only if the product will be sold), the product PRD (full or lite), UX/UI definition (always), and the technical spec — using the installed plugins (/deep-research, product-management, design, Impeccable, Superpowers) and falling back to built-in steps when one is missing. Detects which stage you are in and resumes from there. Use when starting a new product or project idea, before /greenfield:initializer ("I have an idea", "start a new project", "phase 0", "discovery", "market research", "write the PRD", "define the UX").
argument-hint: "[market | product | ux | spec | status]"
---

# /greenfield:discover

Runs Phase 0 as one guided flow with a human checkpoint at the end of every stage. The output is the set of documents that `/greenfield:initializer` reads.

```
Intake ─► 0A Market research ─► GO/NO-GO ─► 0B Product ─► 0C UX/UI ─► 0D Spec ─► next: /greenfield:initializer
          (only if it will be sold)          (full|lite)   (ALWAYS)
```

## Inviolable rules
1. **The human decides.** Never close a stage, pass the go/no-go gate or approve a document on the user's behalf.
2. **No code.** Phase 0 produces documents only. No implementation ultracode and no `/goal` (research workflows such as `/deep-research` are fine).
3. **Plain language.** The user may not be technical: summarize every document in 5–8 simple lines before asking for approval.
4. **One stage at a time.** Finish, get approval, record it, then move on.
5. **Later documents reference earlier ones; they don't repeat them.**

## Files this skill owns
| File | Stage |
|---|---|
| `docs/product/discovery-log.md` | All: state, decisions, approvals (template: `references/discovery-log.md`) |
| `docs/product/market-research.md` | 0A |
| `docs/product/PRD.md` | 0B (template: `references/prd-template.md`) |
| `docs/design/PRODUCT.md`, `docs/design/DESIGN.md` | 0C (questions: `references/ux-questions.md`) |
| `docs/superpowers/specs/*-design.md` or `spec.md` | 0D |

## Step 0 — Detect state
1. If `docs/product/discovery-log.md` exists, read it and resume at the first stage not marked `approved` (or `skipped` with a reason).
2. Otherwise, infer from the files above which stages already exist and confirm with the user.
3. If an argument was passed (`market`, `product`, `ux`, `spec`), jump to that stage; warn if an earlier stage is missing, since later stages get weaker without it.
4. `status` → show the log as a table and stop.
5. **Detect available tools**: check which of these skills/commands are available in the session and note them in the log: `/deep-research`, `product-management` (`/competitive-brief`, `/write-spec`, `/brainstorm`), `design` (`/ux-copy`, `/design-system`, `/accessibility`), Impeccable (`init`, `shape`, `document`), Superpowers (`brainstorming`). Missing tools are not a blocker: use the fallback listed in each stage.

## Intake (first run only)
Ask, one short block:
- What is the idea, in one sentence, and who is it for?
- **Will it be sold** (commercial product) or is it internal/personal?
- Where will it run for now: **local only**, or a GitHub repo with CI?
- Any hard constraints already known (budget, deadline, platform, regulations, data you must protect)?

Create `docs/product/discovery-log.md` from the template with these answers.

## 0A — Market research (only if it will be sold; otherwise mark `skipped: not commercial`)
- **With `/deep-research`:** ask the user to run it (or run it if you can invoke it) with this prompt, filled in:
  > Research the market for <product> for <segment> in <country>. Cover current alternatives (including doing it by hand), pricing, reviews, gaps, market size with explicit assumptions (TAM/SAM/SOM) and willingness to pay. Cite sources.
- **Then** structure the result with `/competitive-brief` if available, plus a SWOT.
- **Fallback:** do the web research yourself with the same coverage and cite every source.
- Write `docs/product/market-research.md` with: landscape, 5–10 competitors/alternatives, customer (problem, JTBD, objections, willingness to pay), differentiation, and a **go/no-go recommendation with the 3 hypotheses to validate first**.
- **GO/NO-GO gate:** present the recommendation and ask the user to decide. Record the decision and the reason in the log. On NO-GO, stop the flow.

## 0B — Product PRD (full if commercial; lite otherwise)
- Use `references/prd-template.md` (it marks which sections are lite).
- **With `product-management`:** use `/brainstorm` for positioning and `/write-spec` to draft, then reshape into the template.
- **Fallback:** interview the user section by section.
- The PRD is a **business** document: no frameworks, tables or APIs. Make the **MVP non-goals** explicit.
- Write `docs/product/PRD.md`, summarize it, get approval, record it.

## 0C — UX/UI (always)
- Ask **every** question in `references/ux-questions.md`. Mark any that don't apply as `N/A` with the reason. For conversational products (chat, WhatsApp, voice), use the conversation-design variants.
- **With Impeccable:** run `init` (it writes `PRODUCT.md`), then `shape`, then `document` (`DESIGN.md`). Check the result against the questions and fill any gaps. Remind the user to set `DO_NOT_TRACK=1` and never use `live` mode.
- **With the `design` plugin:** use `/design-system` to structure tokens and components and `/ux-copy` for microcopy.
- **Fallback:** write both files yourself from the answers.
- `docs/design/PRODUCT.md`: users, context, key tasks, tone, constraints.
- `docs/design/DESIGN.md`: principles, visual direction, tokens, components, states (empty, loading, error, success), accessibility target (default WCAG 2.1 AA), key flows.
- Show the visual direction (a short description, a style tile, or a quick prototype if `frontend-design` is available) and get approval.

## 0D — Technical spec
- **With Superpowers:** invoke `brainstorming` and tell it first:
  > Before starting, read docs/product/PRD.md, docs/product/market-research.md (if it exists), docs/design/PRODUCT.md and docs/design/DESIGN.md. The technical spec must respect the MVP scope, metrics and design system defined there, and reference those files instead of repeating them. The project runs <local only | on GitHub with CI>.
- **Fallback:** interview the user until you can write the spec, then save it as `spec.md`.
- Minimum content: goal, users, main flows, external integrations, sensitive data, non-negotiable rules, non-goals, "done" criteria, references to the PRD and DESIGN.
- Get approval and record it.

## Close
- Mark Phase 0 `complete` in the log and show the final table of stages, decisions and files.
- Tell the user the next step in one line: **run `/greenfield:initializer`** (it reads these documents).
- If the log says **local only**, remind them that later checkpoints use "merge locally" instead of "open a PR".
