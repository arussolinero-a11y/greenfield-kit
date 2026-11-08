# Practical Guide: Greenfield Projects with Claude Code

> Following Anthropic's best practices · **v1.0** · 2026-11-08
>
> **Audience:** people and agents. If you are an agent: sections marked **RULE** are mandatory, decision tables tell you what to do in each context, and templates are meant to be copied as-is.
>
> **Status:** v1.0, ready to publish. Ships with the `greenfield` plugin (`/greenfield:initializer`, `/greenfield:next` and `/greenfield:preflight` skills) in this same kit. Version history in §16.

---

## 0. Summary in 30 seconds

1. **Phase 0 — Product, UX/UI and spec:** (0A) market research + go/no-go if the product will be sold → (0B) product PRD → (0C) UX/UI, **always** → (0D) technical spec with Superpowers `brainstorming`. The human decides.
2. **Phase 1 — Adaptive initializer:** a session that **builds no features**. It reads the spec, profiles the project and generates the project's "memory" (`feature_list.json`, `init.sh`, progress log, `CLAUDE.md`, hooks, verification tooling). The human approves the list.
3. **Phase 2 — Build:** one feature per session with Superpowers: `writing-plans` (you approve the plan) → `subagent-driven-development` (each task gets an implementer and a reviewer) → `finishing-a-development-branch` (PR). `/goal` acts as a safety net so the session doesn't stop halfway. Each feature's mode (`sdd`, `inline`, `ultracode`, `spike`, `human`) was set in Phase 1.
4. **Phase 3 — Maintenance:** `/loop` to watch something during the session; cloud tasks for daily jobs and event-triggered jobs.
5. **Phase 4 — Audits and large-scale changes:** ultracode once there is code: security audit, test coverage, pre-production review, migrations. Findings go back into `feature_list.json`.
6. **When the spec changes:** `/greenfield:initializer --resync` adds and deprecates features; it never deletes.
7. **Before every deploy:** `/greenfield:preflight` → GO / NO-GO (§13). Avoid the anti-patterns in §12. Full example in §14.

---

## 1. Principles (from Anthropic)

| # | Principle | In practice |
|---|---|---|
| P1 | **Give Claude a way to verify its work** | Every feature has a verification command or evidence. Ask for the *output*, not "tests pass now". |
| P2 | **Separate research/planning from implementation** | Explore → Plan → Code → Commit. Plan mode for the first two. |
| P3 | **The agent has no memory between sessions** | Memory lives in files: feature list, progress log, git log, `init.sh`. |
| P4 | **One feature per session** | Avoids running out of context halfway and declaring victory too early. |
| P5 | **Deterministic vs. judgment** | What must never break → hooks and `deny` rules. Preferences → `CLAUDE.md`. Writing "IMPORTANT" doesn't make it mandatory. |
| P6 | **Short `CLAUDE.md`** | Only what Claude can't discover by reading the repo: commands, undocumented decisions, known gotchas. |
| P7 | **Correct little, restart early** | After 2 failed corrections: `/clear` and a better prompt, instead of a third correction. |
| P8 | **A human at the checkpoints** | Spec, feature list, subjective criteria and merges are approved by a person. |

These principles come from the official practices detailed in §2.

---

## 2. Related official Anthropic practices

What Anthropic has published on this topic and where this guide applies it. Quotes in §2.2 were checked verbatim against the source page on 2026-11-08.

### 2.1 *Effective harnesses for long-running agents* (Anthropic Engineering)
The most direct reference for long greenfield projects.
- **Problem:** the agent works in discrete sessions with no memory of earlier ones. Two typical failures:
  - It tries to build the whole app at once, runs out of context mid-feature, and the next session has to guess what happened.
  - A later session sees progress and declares the job done.
- **Solution:** two prompts on the same harness.
  - An **initializer agent** (first session) creates `init.sh`, `claude-progress.txt`, an initial commit and a JSON **feature list**, with every feature marked as failing.
  - A **coding agent** (every later session) makes incremental progress and leaves the code clean.
- **Key rules:**
  - Coding sessions **may only change the `passes` field**: *"It is unacceptable to remove or edit tests"*.
  - JSON is used because the model is less likely to rewrite it than Markdown.
  - **One feature per session** (they call it "critical"), with a commit and a progress update at the end.
  - **At the start of every session:** `pwd`, read the git log and progress file, pick the highest-priority pending feature, run `init.sh` and a basic end-to-end test **before** building anything new. Starting a feature on a broken app "would likely make the problem worse".
  - **Test like a user would:** unit tests and `curl` missed end-to-end failures; browser automation "dramatically improved" results.
- **Failure → fix table:**

| Observed failure | Fix |
|---|---|
| Declares victory too early | Feature list + one feature per session |
| Leaves bugs or undocumented progress | Git repo + progress file; test at start, commit and progress update at end |
| Marks features done prematurely | Self-verification; mark as passing only after careful testing |
| Wastes time figuring out how to run the app | `init.sh`, read at the start of every session |

- **Reference implementation:** [`claude-quickstarts/autonomous-coding`](https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding), with `initializer_prompt.md` and `coding_prompt.md`.
- **In this guide:** Phase 1 (§6) and the Phase 2 session routine (§7.6).

### 2.2 *Claude Code Best Practices* (code.claude.com/docs/en/best-practices)
| Practice | What it says | In this guide |
|---|---|---|
| **Give it a check** | Give Claude a check it can run (test, linter, build exit code, screenshot) and **ask for evidence** instead of "all tests pass". Options range from a prompt to `/goal`, a Stop hook or `/code-review` | P1 · `verify_cmd` (§6.3) · §7.3 |
| **Interview first** | *"Interview me until you could write the spec, then write it to SPEC.md"*, then a **fresh session** to build from the spec | Phase 0 (§5) |
| **Specific prompts** | Name the file, the symptom and what "fixed" means, instead of "fix the login bug" | `/goal` templates |
| **Short `CLAUDE.md`** | Only what Claude can't find by reading the repo. Test: *Could it find this by reading the code?* and *Would it actually go and look?* If both are yes, leave it out. Don't describe the architecture | P6 · §6.3 |
| **Deterministic vs. judgment** | Hooks, `deny` rules and managed settings for zero-exception rules; preferences in `CLAUDE.md`. Adding IMPORTANT to a line usually doesn't help | P5 · §6.2d |
| **Stop hook** | Example `pnpm tsc --noEmit 1>&2 \|\| exit 2` in `.claude/settings.json`: exit code 2 blocks Claude from stopping. Claude Code overrides it after 8 consecutive blocks with no tool use | §6.2d |
| **Course-correct** | `Esc` stops and keeps the work done so far. After **2 failed corrections**: `/clear` and a better prompt | P7 |
| **Separate reviewer** | A read-only subagent (Read, Grep, Glob) that reviews against the spec. Include "skip style" or it will find something to fix in everything | Superpowers per-task reviewer (§7.2) |
| **Writer/reviewer and parallel work** | "A second session is also the easiest independent reviewer you can get": one session writes, another reviews, and you paste the findings back. `claude -w feature-auth` starts a session in a new worktree. `/batch` splits a task into 5 to 30 units; after you approve the plan, each unit gets its own worktree and opens a PR | `parallel_safe` (§6.3) · §7.6 |
| **Before running unattended** | Go through five questions: *Does it know what done looks like? Can it check its own work? What's it allowed to touch? What stops it?* (`--max-turns`, `--max-budget-usd`, a spend limit) *Where does the result go, and who signs off?* For scripted runs: "Try it on three files first" | `/goal` templates with a cap · §9.4 |
| **`/goal` and `/loop`** | `/goal`: "a condition that a separate model checks after every turn". `/loop`: background work that keeps sending requests; don't leave it running in a long conversation | §3 · §8.1 |
| **What you can stop doing** | IMPORTANT/ALL CAPS ("piling on emphasis mostly makes Claude over-apply the rule"; use a hook or deny rule instead). `think hard` / `be thorough` (ordinary text, not effort keywords; `ultrathink` still works). Generic "keep going" lines (current models carry on through an agreed task). A concrete check to pass is different and still worth doing | Template style · P5 |

### 2.3 Explore → Plan → Code → Commit (Anthropic's classic workflow)
1. **Explore:** Claude reads the relevant code without editing.
2. **Plan:** it proposes an approach (in plan mode); you review it.
3. **Code:** it implements in normal mode, verifying as it goes.
4. **Commit:** commit with a descriptive message and a PR.

Separating the first two phases from implementation avoids "code that solves the wrong problem".
- **In this guide:** Phase 0 + `writing-plans` (Explore/Plan, checkpoint 1) → SDD (Code) → `finishing-a-development-branch` (Commit/PR).

### 2.4 Official guidance for each tool
| Source | Official recommendation | In this guide |
|---|---|---|
| `/goal` docs | Use it for "substantial work with a verifiable end state". The condition needs a measurable end state + an explicit check + constraints. Bound it with "or stop after N turns". Combine it with **auto mode** | §3.1 · §7.3 |
| Scheduled tasks docs | `/loop` for "quick polling during a session"; cloud tasks for work that must run without your machine; Desktop tasks for local files; Channels to react to events live | §3.2 · §8 |
| Workflows docs | Use a workflow when a task needs more agents than one conversation can coordinate, or when you want the orchestration as a rerunnable script. A workflow "can use meaningfully more tokens" | §3.3 · §9 |

---

## 3. The tools, according to the official documentation

They don't compete: they control different axes. **`/goal` = when it ends**, **`/loop` = when it repeats**, **ultracode = how it runs** (in parallel). Where the `/goal` name came from: when asked about the feature, Boris Cherny (creator of Claude Code) replied "/loop until"; `/goal` shipped the next day (v2.1.139).

### 3.1 `/goal`: work until a condition is met
- **What it is:** sets a completion condition. Claude chains turns without you typing until the condition is met.
- **Mechanism:** a prompt-based Stop hook. At the end of each turn, a small, fast model (the evaluator) reads the conversation and answers *not met* (Claude continues, using the reason as guidance), *met* or *impossible*. The last two clear the goal.
- **Usage:** `/goal <condition>` · `/goal` (status) · `/goal clear` (aliases: `stop`, `off`, `reset`, `cancel`) · `claude -p "/goal …"`.
- **Limits:**
  - One goal per session, up to 4,000 characters.
  - **No turn, time or budget cap by default.**
  - The evaluator **doesn't run commands or read files**: it only sees what Claude surfaced.
  - If Claude goes several turns without using tools, the loop stops with a warning.
  - `/clear` removes the goal; `--resume` restores it.
  - It doesn't change the permission mode: to run unattended, use it with **auto mode**.
- **A good condition:** a measurable end state + an explicit check ("`npm test` exits 0") + constraints. To bound it, add "or stop after N turns". That's a soft cap the evaluator interprets; with `-p`, also use `--max-turns` / `--max-budget-usd`.
- **Anthropic recommends it for:** "substantial work with a verifiable end state": migrating a module until it compiles and tests pass, implementing a design doc until the acceptance criteria hold, emptying a backlog.

### 3.2 `/loop`: repeat on a clock
- **What it is:** reruns a prompt every X amount of time, or at a pace Claude chooses, **inside the open session**. Technically a bundled skill (alias `/proactive`).
- **Mechanism:**
  - Intervals are converted to cron.
  - With no interval, Claude self-schedules with `ScheduleWakeup`, between 1 minute and 1 hour.
  - It fires between turns, never mid-response.
- **Usage:** `/loop 10m <prompt>` · `/loop <prompt>` (dynamic pace) · `/loop` alone (built-in maintenance prompt or `.claude/loop.md`) · `/loop 20m /<skill>`.
- **Limits:**
  - Recurring tasks expire after 7 days; max 50 per session; minimum interval 1 minute.
  - Runs only while the session is open and idle; missed runs are not caught up.
  - Every run adds context to the conversation.
  - `Esc` stops a dynamic loop; a fixed-interval loop is cancelled by asking Claude.
- **Anthropic recommends it for:** "quick polling during a session", i.e., periodically checking something that changes on its own: waiting for a deploy, babysitting a PR, checking CI, reminders.

### 3.3 Ultracode and dynamic workflows: run in parallel
- **Workflow:** a JavaScript script that orchestrates many subagents (`agent()`, `parallel()`, `pipeline()`). Claude writes it and a runtime executes it in the background. It can be saved in `.claude/workflows/` and rerun as `/<name>`. `/deep-research` is bundled.
- **Ultracode:** a session *setting*, not a model. With it on, Claude plans a workflow for every substantive task; one request can produce several in a row (understand → change → verify).
- **Usage:**
  - `/effort ultracode` / `/effort ultracode off`.
  - `claude --effort ultracode` (also sets effort to `xhigh`).
  - `"ultracode": true` in settings.
  - **Keyword:** typing `ultracode:` in a prompt turns it on for that task only. **It only works when typed in the interactive session**: not in `-p`, `/loop` or scheduled-task prompts, or webhook/PR-comment payloads.
- **Limits:**
  - 16 concurrent agents by default (configurable up to 256) and 1,000 per run.
  - "Large workflow" warning above 25 agents or 1.5 million projected tokens.
  - A workflow can't ask you for input midway.
  - **Uses meaningfully more tokens:** you reach session and weekly limits sooner.
  - Disabled with `CLAUDE_CODE_DISABLE_WORKFLOWS=1`.
- **Anthropic recommends it for:** tasks that need more agents than one conversation can coordinate (codebase-wide bug sweeps, migrations across hundreds of files, cross-checked research), or when you want the orchestration as a readable, rerunnable script.

### 3.4 Quick reference table

| Tool | What it is | Use it for | Don't use it for |
|---|---|---|---|
| `/goal <condition>` | Claude chains turns until an evaluator (small model) judges the condition met | Features with binary verification; migrations; emptying a backlog | Subjective criteria ("make it sound warm"); vague conditions ("production-ready") |
| `/loop [interval] <prompt>` | Reruns a prompt on a clock, inside the open session | Watching CI, a deploy or a PR while you work | Building ("keep coding"); anything that must survive closing the session |
| Ultracode (`/effort ultracode` or `ultracode:` in the prompt) | Claude orchestrates *workflows* of many parallel subagents | Codebase-wide audits, large migrations, test coverage | Empty repo or scaffolding; architecture decisions; small fixes |
| Workflows (`/workflows`, `.claude/workflows/`) | JS script orchestrating subagents; can be saved and rerun | Repeatable verifications (e2e, security audit) | Tasks that need your input midway |
| Cloud tasks (`/schedule`, claude.ai/code/routines) | Cloud sessions triggered by cron, API or GitHub event | Daily report + reacting to events | Intervals under 1 hour |
| Channels | Events (Telegram, Discord, webhooks) delivered to your local session | Reacting live while you work | Anything that must run 24/7 |
| GitHub Actions (`claude-code-action`) | Claude on GitHub runners for any event | `@claude` in PRs and issues, CI | When you don't use GitHub |

> Versions change fast: check `claude --version`. Ultracode `on|off` requires v2.1.284 or later.

---

## 4. Setup: install the kit (once per machine or environment)

This guide relies on plugins and skills from Anthropic and third parties. The kit's own `greenfield` plugin **only orchestrates**: it ties the pieces together and adds what none of them provide (adaptive initializer, session starter, preflight).

| Plugin / skill | Purpose | Install |
|---|---|---|
| **greenfield** (this kit) | Phase 1 (`/greenfield:initializer`), Phase 2 (`/greenfield:next`), pre-deploy (`/greenfield:preflight`) | `/plugin marketplace add arussolinero-a11y/greenfield-kit` → `/plugin install greenfield@greenfield-kit` |
| **Superpowers** | Phase 0D (`brainstorming`) and Phase 2 (`writing-plans`, `subagent-driven-development`, TDD) | `/plugin install superpowers@claude-plugins-official` |
| **product-management** (Anthropic) | Phases 0A, 0B and 3 | `/plugin marketplace add anthropics/knowledge-work-plugins` → `/plugin install product-management@knowledge-work-plugins` |
| **design** (Anthropic) | Phases 0C and 4 (`/ux-copy`, `/accessibility`, `/critique`) | `/plugin install design@knowledge-work-plugins` |
| **engineering** (Anthropic) | `/deploy-checklist` (used by the preflight) | `/plugin install engineering@knowledge-work-plugins` |
| **frontend-design** (Anthropic) | Phase 2, features with UI | `/plugin install frontend-design@claude-plugins-official` |
| **playwright** (official marketplace) | Visual evidence (screenshots, e2e) | `/plugin install playwright@claude-plugins-official` |
| Impeccable *(optional)* | Phase 0C (`init`, `shape`, `document`) and Phase 4 (`audit`, `critique`) | `/plugin marketplace add pbakaus/impeccable` → install from `/plugin`. Then set `DO_NOT_TRACK=1`; **don't use `live` mode** |
| Built into Claude Code | `/goal`, `/loop`, `/deep-research`, `/security-review`, `/code-review`, workflows | — |

**"Anthropic-only" route:** skip Impeccable and use `design` + `frontend-design`.
**Context hygiene:** every plugin adds instructions and tools to the context. Check the cost with `claude plugin details <plugin>` and disable what you don't need in the current phase (`/plugin` → disable).

---

## 5. Phase 0 — Product, UX/UI and spec (the human decides)

Phase 0 has four sub-phases. The **technical spec (0D)** is written last, fed by the others.

```
Will it be sold?
   ├─ Yes ─► 0A Market research ─► GO/NO-GO GATE ─► 0B Product (full)
   └─ No ──────────────────────────────────────────► 0B Product (lite)
                                                        │
                              0C UX/UI (ALWAYS) ◄───────┘
                                                        │
                              0D Technical spec (Superpowers brainstorming)
```

**RULE:** no implementation ultracode and no `/goal` in this phase. Product and architecture decisions are sequential and made by the human. The only exception is research: `/deep-research` uses workflows and is fine here.

### 5.1 0A — Market research (only if the product will be sold)
**Goal:** decide, with evidence, whether it's worth building and for whom.

| Deliverable | Content |
|---|---|
| Market landscape | Segments, trends, size (TAM/SAM/SOM with explicit assumptions) |
| Competition | 5–10 competitors or alternatives (including "do nothing" or doing it by hand): offering, price, positioning, reviews, gaps |
| Customer | Problem, *jobs to be done*, objections, willingness to pay (hypothesis) |
| Differentiation | Why us; what we won't do |
| **Go/no-go gate** | Recommendation + risks + what to validate first (interviews, test landing page) |

**File:** `docs/product/market-research.md` (with cited sources).
**Recommended tools:**
1. `/deep-research <question>`: official Claude Code workflow; cross-checked research with sources.
2. `/competitive-brief` from Anthropic's `product-management` plugin.
3. Third-party frameworks for structure: `market-landscape-scan`, `competitive-research-snapshot`, `tam-sam-som-calculator`, `swot-analysis` and `positioning-statement` (deanpeters), or `competitive-analysis`, `market-sizing` and `lean-canvas` (product-on-purpose). See §5.5.

**Template:**
```
Use /deep-research to research the market for <product> for <segment> in <country>.
Cover: current alternatives (including doing it by hand), pricing, reviews, gaps,
market size with explicit assumptions, and willingness to pay. Cite sources.
Then structure the result with a competitive analysis and a SWOT, and finish with
a go/no-go recommendation and the 3 hypotheses we should validate first.
Save it to docs/product/market-research.md. Explain it to me in plain language.
```

### 5.2 0B — Product (full if it will be sold; lite if not)
| Deliverable | Full | Lite |
|---|---|---|
| Problem and users (personas, JTBD) | ✅ | ✅ |
| Value proposition and positioning | ✅ | — |
| MVP scope: what's in and what's **out** | ✅ | ✅ |
| Success metric (North Star) + 2–3 supporting metrics | ✅ | ✅ (1 metric) |
| Pricing and packaging hypothesis | ✅ | — |
| Roadmap: MVP → v1 → later | ✅ | — |
| Risks and assumptions to validate | ✅ | ✅ |

**File:** `docs/product/PRD.md` (a business document, not a technical one).
**Recommended tools:** Anthropic's `product-management` plugin (`/brainstorm`, `/write-spec` for the PRD, `/roadmap-update`, `/metrics-review`) + third-party frameworks for what it doesn't cover: positioning, pricing, *opportunity solution tree*. See §5.5.

### 5.3 0C — UX/UI (ALWAYS)
**RULE:** every greenfield product gets its own UX/UI definition **before** the technical spec, even an internal tool or a bot. In a conversational interface (chat, WhatsApp, voice), UX/UI means **conversation design**: tone, message length, buttons and menus, error handling and handoff to a human.

**Mandatory questions** (Claude must ask all of them; if one doesn't apply, it marks it "N/A" with the reason):

| Topic | Questions |
|---|---|
| User and context | Who uses it, on what device and in what situation (in a hurry, on the street, at a desk)? Digital literacy? Language and register (formal/informal)? |
| Key tasks | What are the 3 tasks the user **must** accomplish? What's the "aha moment"? |
| Platform | Web, mobile, desktop, chat or voice? Responsive? Offline? |
| Brand | Is there an existing brand (logo, colors, typography)? 3 personality adjectives? References they like and **anti-references**? |
| Content and tone | Brand voice? Who writes the copy? Microcopy for errors and empty states? |
| Flows | Onboarding? Happy path for each key task? What happens when something fails? |
| States | Empty, loading, error, success, no permission? |
| Accessibility | Target level (default **WCAG 2.1 AA**): contrast, keyboard, screen readers, reduced motion |
| Design system | Existing component library (e.g., shadcn/ui)? Tokens (colors, spacing, typography)? Dark mode? |
| Measurement | Which UX metric shows it works (completion rate, time on task, drop-off)? |
| Constraints | Technical or platform limits? (e.g., WhatsApp: max 3 buttons per message, 24-hour window) |

**Deliverables:**
- `docs/design/PRODUCT.md`: users, tasks, tone, constraints.
- `docs/design/DESIGN.md`: principles, visual direction, tokens, components, states, accessibility.
- Key flows (text or diagram) and, if applicable, a prototype or wireframe that **you approve**.

**Recommended tools:** Impeccable `/impeccable init` (asks what it can't infer and writes `PRODUCT.md`) → `shape` (plans the UX before code) → `document` (`DESIGN.md`). UI UX Pro Max works as a library of styles, palettes and industry rules for proposing the design system. And `/ux-copy` from Anthropic's `design` plugin for microcopy. See §5.5.

### 5.4 0D — Technical spec
**Tool:** Superpowers `brainstorming`, which produces the spec (in `docs/superpowers/specs/`).
**RULE:** brainstorming **reads** `docs/product/*` and `docs/design/*` **first**, and the spec references them; it doesn't repeat them.
```
Before starting, read docs/product/PRD.md, docs/product/market-research.md (if it exists),
docs/design/PRODUCT.md and docs/design/DESIGN.md. The technical spec must respect the
MVP scope, metrics and design system defined there.
```
**Without the plugin:**
```
Interview me until you could write the technical specification for <project>.
Ask about users, flows, integrations, sensitive data, rules that must never
break, and what "done" means. Then write it to spec.md.
```
**Minimum spec output:** goal, users, main flows, external integrations, sensitive data, non-negotiable rules, non-goals, "done" criteria, and references to the PRD and DESIGN.

### 5.5 Tools for Phase 0 (scored for greenfield)

**Market research (0A)**
| Option | Score | Pros | Cons |
|---|---|---|---|
| **`/deep-research` (Claude Code, official) + `/competitive-brief` (`product-management` plugin, Anthropic)** | **85** | Official, no extra dependencies, sourced and cross-checked | Generic frameworks; public web sources only; `/deep-research` uses a lot of tokens |
| deanpeters/Product-Manager-Skills (market landscape → competitive snapshot → SWOT, TAM/SAM/SOM, battle cards) | 72 | Most complete market-research chain; asks 3–5 questions, then recommends | **CC BY-NC-SA 4.0 license (non-commercial)**: a gray area if the product is sold. Review it before use |
| product-on-purpose/pm-skills (competitive-analysis, market-sizing, lean-canvas) | 70 | Apache 2.0; Triple Diamond framework | No dedicated pricing or positioning skill |
| Data connectors (Similarweb, Ahrefs via the `marketing` plugin) | 60 | Real traffic and SEO data | Paid; optional add-on |

**Product management (0B, and in Phase 3)**
| Option | Score | Pros | Cons |
|---|---|---|---|
| **`product-management` plugin (Anthropic, knowledge-work-plugins)** | **85** | Apache 2.0; `/brainstorm`, `/write-spec`, `/roadmap-update`, `/metrics-review`, `/synthesize-research`, `/stakeholder-update`; works without connectors | "Generic starting point" (built for Cowork); `/write-spec` overlaps with Superpowers: use it for the business PRD and Superpowers for the technical spec |
| product-on-purpose/pm-skills (68 skills, Triple Diamond, workflows) | 78 | Apache 2.0, very complete, subagents | Large; installing only part of it breaks routing; its MCP server is in maintenance mode |
| deanpeters/Product-Manager-Skills (77 skills: discovery, positioning, PRD, roadmap) | 72 | Very didactic, asks before recommending | Non-commercial license |

**UX/UI (0C, and in Phases 2 and 4)**
| Option | Score | Pros | Cons |
|---|---|---|---|
| **Impeccable (pbakaus, Apache 2.0)** | **85** | `init` asks the questions and writes `PRODUCT.md`; `shape` and `document` (`DESIGN.md`); `critique` and `audit` (P0–P3); deterministic detector of generic AI design ("AI slop"). Grew out of the official `frontend-design` skill | **Telemetry on by default** (turn off with `DO_NOT_TRACK=1`). **Don't use `live` mode**: it can run Claude with permissions bypassed. Strongest on existing interfaces |
| `design` plugin (Anthropic, knowledge-work-plugins) | 82 | `/critique`, `/design-system`, `/handoff`, `/ux-copy`, `/accessibility` (WCAG 2.1 AA); works without Figma | Reviews and documents; doesn't generate UI |
| `frontend-design` (official Anthropic skill/plugin) | 80 | Aesthetic direction, design plan before code, and a quality floor (responsive, keyboard focus, reduced motion) | No discovery questions or audit |
| UI UX Pro Max (nextlevelbuilder, MIT) | 78 | Huge library of styles, palettes, fonts, industry rules and a pre-delivery checklist | Requires Python; asks no questions; generator-first; has a paid tier. Pick this **or** Impeccable as your main style engine, not both |
| Playwright (official marketplace, external plugin) | add-on | Screenshots and visual tests as evidence | Verifies only; doesn't design |

**Recommended combination** (with an Anthropic-only alternative if you prefer not to install third-party plugins):

| Moment | Recommended | Anthropic only |
|---|---|---|
| 0A Market research | `/deep-research` + `/competitive-brief` (+ third-party frameworks if needed) | `/deep-research` + `/competitive-brief` |
| 0B Product | `product-management` plugin + pm-skills for positioning and pricing | `product-management` plugin |
| 0C UX/UI | Impeccable `init`/`shape`/`document` + `/ux-copy` | `design` plugin (`/design-system`, `/ux-copy`) + `frontend-design` |
| Phase 2 (UI) | `frontend-design` + Playwright screenshots | Same |
| Phase 3 (product) | `/metrics-review`, `/synthesize-research`, `/roadmap-update` | Same |
| Phase 4 (UX) | `/accessibility` + Impeccable `audit`/`critique` | `/accessibility` + `/critique` |

---

## 6. Phase 1 — Adaptive initializer

Based on Anthropic's *initializer + coding agent* pattern (the *Effective harnesses for long-running agents* post and `claude-quickstarts/autonomous-coding`), with one difference: **it adapts to the spec** instead of assuming a web app with 200 features.

**RULE:** the initializer session **implements no features**.

### 6.1 Step 1 — Profile the spec → `docs/project-profile.md`

| Dimension | Question |
|---|---|
| Type | Web, API, conversational bot, CLI, library, data pipeline, mobile? (can be mixed) |
| External interfaces | Which systems does it talk to? |
| Risks | Money, personal data, security, legal compliance? |
| AI behavior | Are there non-deterministic outputs to evaluate? |
| Unknowns | What don't we know how to solve yet? |
| Size | How many distinct capabilities does it have? |
| Non-negotiable rules | What must never break? |

### 6.2 Step 2 — Decision matrix

**a) Verification by project type**

| Profile | Verification tooling generated in `verify/` |
|---|---|
| Web UI | E2E with Playwright + screenshots as evidence + check against `docs/design/DESIGN.md` (tokens, states, accessibility) |
| API / webhooks | Contract tests + a script that simulates requests (signed, if applicable) |
| Conversational bot | Conversation simulator + "golden" transcripts |
| AI outputs (tone, judgment) | Evals: test cases + LLM judge + human-reviewed sample |
| CLI | Comparison against expected outputs |
| Library | Unit tests + property tests |
| Data pipeline | Fixtures + per-stage counts and invariants |

**b) Size and order**
- Each feature fits in **one session**, roughly one reviewable commit. The count scales with the spec.
- Order:
  1. **Walking skeleton**: a trivial end-to-end path, deployed.
  2. **Spikes** for unknowns: their deliverable is an ADR.
  3. **Risks**: security, payments, integrations.
  4. **Core value**.
  5. **Polish**.

**c) Execution mode per feature (`mode`)**

| `mode` | When | How (details in §7) |
|---|---|---|
| `sdd` (default) | Any feature with binary verification | Superpowers `writing-plans` → `subagent-driven-development` (implementer + reviewer per task) → PR, with `/goal` as a safety net |
| `inline` | Small and low-risk (copy, config, minor tweak) | `writing-plans` → `executing-plans` (single review at the end; cheaper) |
| `ultracode` | Broad and mechanical (one pattern across many files, mass test coverage) | `writing-plans` → `/goal` with ultracode on |
| `spike` | Technical unknown | Regular session → ADR in `docs/decisions/` → the human decides |
| `human` | Subjective criteria (tone, UX, copy) | Claude prepares the evidence (demo, transcripts, screenshots); a person approves |

Add `"extra_review": ["security"]` to features with `risk: "high"` (payments, auth, personal data): `/security-review` and/or `/code-review` run before merge.

**d) Non-negotiable rules → controls**
- **Deterministic**, in `.claude/settings.json`: Stop hook running typecheck and tests (`<cmd> 1>&2 || exit 2`), `deny` rules for `.env` and secrets.
- **Judgment-based**: a line in `CLAUDE.md` + a dedicated verification feature (e.g., an eval).

### 6.3 Step 3 — Artifacts

```
feature_list.json      feature list (schema below)
init.sh                installs dependencies, validates .env, starts the environment, smoke test
claude-progress.txt    work log: what was done, what's next, blockers
CLAUDE.md              commands, rules, session-start routine (short)
.claude/settings.json  hooks and deny rules
docs/project-profile.md
docs/decisions/        ADRs from spikes
verify/                verification tooling for the profile
```

**`feature_list.json` schema**
```json
{
  "id": "F-007",
  "category": "security",
  "description": "Webhook rejects invalid HMAC signatures without calling the AI",
  "depends_on": ["F-002"],
  "mode": "sdd",
  "risk": "high",
  "extra_review": ["security"],
  "steps": ["valid signature → 200", "tampered signature → 401", "0 AI calls in the test log"],
  "verify_cmd": "npm test -- webhook.hmac",
  "human_review": false,
  "parallel_safe": true,
  "status": "pending",
  "passes": false
}
```
**RULES for coding sessions:**
- They may only change `passes`, `status` and `history`.
- They never delete or water down `steps`. Anthropic uses JSON instead of Markdown because the model is less likely to rewrite it.
- `status` can be `pending | in_progress | done | deprecated`.

### 6.4 Step 4 — Human checkpoint
**Product and design inputs:** the initializer also reads `docs/product/PRD.md` and `docs/design/DESIGN.md`. They drive:
- the **order** (MVP scope first);
- early **design system** features (tokens and base components, right after the walking skeleton);
- for every feature with an interface, a visual-evidence step (screenshot or transcript) and its empty/error state;
- **instrumentation** features for the PRD metrics;
- and `human_review: true` wherever the criteria are design-related.

The initializer shows the **profile** and the **list**, and commits only with your approval. Check:
- **Size:** does each feature fit in one session?
- **Steps:** do they test real behavior, not just that it compiles?
- **Order:** walking skeleton → risks → value → polish?
- **Modes:** did subjective items end up as `human`?

### 6.5 How to run it
```
/greenfield:initializer
```
The skill implements steps 6.1–6.4. It reads the spec, PRD and DESIGN; uses the kit's templates (`init.sh`, `CLAUDE.md`, `settings.json`, `feature_list.example.json`) and the decision matrix; and stops at the checkpoint. With `--resync` it applies §10.

**Without the plugin** (equivalent prompt):
```
Read the spec. You are the initializer session: do NOT implement features.
1. Profile the project in docs/project-profile.md (type, interfaces, risks,
   AI, unknowns, size, non-negotiable rules).
2. Apply the decision matrix from the greenfield guide §6.2.
3. Generate: minimal skeleton (build/lint/test green with an empty test),
   init.sh, feature_list.json (schema §6.3), claude-progress.txt, a short
   CLAUDE.md with the session routine, .claude/settings.json with hooks and deny rules, verify/.
4. Show me the profile and the full list. Don't commit until I approve.
```

---

## 7. Phase 2 — Build (one feature per session, with Superpowers)

**Chosen option (90/100):** Superpowers `writing-plans` → `subagent-driven-development` → `finishing-a-development-branch`, inside the Phase 1 framework (`feature_list.json` + progress log) and with `/goal` as a safety net. Comparison with the alternatives in §7.7.

> **In short, one session:**
> 1. Automatic routine: progress log → `./init.sh` → regression check → next feature.
> 2. `writing-plans` → **checkpoint 1: you approve the plan** (ask for it in plain language).
> 3. `/goal` + auto mode, *after* the plan and with a stop clause.
> 4. `subagent-driven-development`: fresh implementer + reviewer (spec and quality) per task.
> 5. `verification-before-completion`: nothing is done without fresh evidence.
> 6. High risk → `/security-review` or `/code-review`.
> 7. `finishing-a-development-branch` → **checkpoint 2: you choose "open a PR"**.
> 8. Wrap-up: `passes: true` + progress log.
>
> **`inline` variant** (small, low-risk features): `executing-plans` instead of SDD; cheaper, with a single review at the end.

### 7.1 Two levels of memory (don't mix them up)

| Level | File | What it holds | Who writes it |
|---|---|---|---|
| **Macro**: project features | `feature_list.json` + `claude-progress.txt` | Which features exist, which pass and what's next | Initializer (Phase 1) + the wrap-up of each session |
| **Micro**: a feature's tasks | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` + ledger in `.superpowers/sdd/progress.md` | 2–5 minute steps (test → implement → test → commit) and decisions ("Rulings") | Superpowers, during the session |

### 7.2 One session's flow (non-technical user)

```
1. Start routine (automatic)
   Read progress log and git log → ./init.sh → regression on 1–2 features → pick the next feature
2. writing-plans                                         ◄── CHECKPOINT 1: you approve the plan
   Ask: "Explain the plan in plain language: what will change,
         what could go wrong, and how we'll know it works."
   Choose execution: subagent-driven (recommended) | inline (`inline` features only)
3. /goal  (see template §7.3) + auto mode
4. subagent-driven-development (runs on its own)
   Per task: fresh implementer → tests → commit → reviewer (spec + quality) → fix if it fails
   Stops only in 4 cases: irreversible action, security-sensitive action,
   action outside the worktree (merge, push to a shared branch, publish) or an unworkable plan
5. verification-before-completion (rule): no "done" without fresh command output
6. If risk = high: /security-review and/or /code-review
7. finishing-a-development-branch                       ◄── CHECKPOINT 2: you choose "open a PR"
8. Wrap-up: passes: true → update progress log → end the session
```

### 7.3 `/goal` template (after approving the plan)
```
/goal Feature <ID> is complete per the approved plan in docs/superpowers/plans/:
all its tasks are closed in the ledger with an approved review (spec and quality);
`<verify_cmd>`, build, lint and test exit 0 with the output visible in the conversation;
passes: true in feature_list.json; claude-progress.txt updated; PR opened.
Only <ID>. If one of the 4 Superpowers stop cases comes up or you need a decision
from me, stop and ask me. Or stop after 40 turns.
```
**Why `/goal` comes after the plan:** the plan needs your approval; execution doesn't. This way the goal doesn't push Claude past checkpoint 1.
**Why the stop clause:** without it, the goal could push on exactly when Superpowers stopped for a good reason (e.g., an irreversible action).

### 7.4 What you review for each feature (without reading code)

| Moment | What to look at | Useful question |
|---|---|---|
| Checkpoint 1: plan | Does the plan do what the spec says? Is anything extra or missing? | "Which part of the spec does each task cover?" |
| End of execution | The list of **"Rulings"** (decisions Claude made for you) and **"Deferred minors"** | "Does any of these decisions change what the user will see?" |
| Evidence | Test output, demo, screenshots or transcripts | "Show me it works the way a user would see it." |
| Checkpoint 2: PR | PR summary and green CI checks | "Explain in 3 lines what changes for the user." |
| `human` features | Try it yourself (or the business owner does) | — |

**RULE:** always choose **"open a PR"**, not "merge locally". A PR keeps history, runs CI and can be reverted.

**Features with an interface:**
- Claude uses the `frontend-design` skill (or Impeccable) and follows `docs/design/DESIGN.md`.
- Checkpoint 2 evidence includes Playwright screenshots of the main states: normal, empty, error and mobile.
- For a bot, the evidence is conversation transcripts.
- If the feature is `human_review`, you approve it by looking at it, not by reading code.

### 7.5 Start with a single command
```
/greenfield:next            ← or /greenfield:next F-012 to pick a specific feature
```
It runs the start routine, picks the feature, routes it by `mode` (invoking Superpowers `writing-plans`), asks you to approve the plan and hands you the complete `/goal` to paste.

### 7.6 Session-start routine (goes in `CLAUDE.md`)
```
1. Read claude-progress.txt and `git log --oneline -10`
2. Run ./init.sh. If anything fails, fix it BEFORE touching features
3. Regression: re-verify 1–2 features that already passed
4. Pick the first pending feature with no open dependencies and no pending human_review
5. Run it according to its "mode" (§6.2c) using the §7.2 flow
6. Wrap-up: passes: true only with evidence → update progress log → end
```
- Features with `parallel_safe: true` can be spread across parallel sessions or worktrees; Superpowers already works in an isolated worktree.

### 7.7 Why this option (scored for greenfield, non-technical profile)

| Option | Score | In one line |
|---|---|---|
| **Superpowers `writing-plans` + `subagent-driven-development` + `/goal`** | **90** | Few checkpoints, in business language; automatic per-task review; mandatory TDD and verification; continues the Phase 0 spec |
| Superpowers `executing-plans` (inline) | 76 | Cheaper and faster, but a single review at the end. Use it only for `inline` features |
| Native: plan mode + `/goal` + auto mode (no plugin) | 66 | Fewer moving parts, but you have to supply the discipline (TDD, review) yourself |
| Anthropic `feature-dev` (official plugin, 7 phases) | 62 | Good for an existing codebase, but asks you to choose between architectures with technical trade-offs |
| Spec Kit `/speckit-implement` + `converge` | 55 | Requires its own spec/plan/tasks: duplicates the Superpowers Phase 0 |
| Anthropic `autonomous-coding` (Python loop) | 50 | Fully autonomous, but needs an API key and Python, with no checkpoints for you |

---

## 8. Phase 3 — Maintenance and automation

| I need… | Mechanism |
|---|---|
| To watch something during the session (CI, deploy, PR) | `/loop 10m <prompt>` |
| Something to run every day without my computer | Cloud task with a *Schedule* trigger (at most once per hour) |
| It to react to an event X | The same task + an *API* trigger (`POST …/routines/{id}/fire`) or a *GitHub* trigger |
| It to run on my machine without an open session | Desktop scheduled task |
| To react live while I work | Channels |

### 8.1 `/loop`: watch something during the session
```
/loop 10m check the open PR's CI; if it failed, diagnose and fix it; if there are
new review comments, address them. Tell me when everything is green.

/loop 5m check whether the deploy on <platform> finished and whether there are errors in the logs.

/loop check whether the long build finished          ← no interval: Claude sets the pace (1 min–1 h)
```
- `/loop` with no prompt runs the built-in maintenance prompt, or yours in `.claude/loop.md`: it continues pending work, tends the branch's PR and does cleanup, without starting new work.
- **Stopping it:** a dynamic-pace loop stops with `Esc`. A fixed-interval loop is cancelled by asking Claude ("cancel the CI loop").
- **RULE:** don't leave it running for days in a long conversation, since every run adds context. For anything permanent, use a cloud task.
- Better in a different session from the one building the feature: one session builds, the other watches.

### 8.2 Cloud tasks: daily + on event
**Daily prompt example:**
```
If you receive a payload, handle only that event.
Otherwise, daily review: (1) dependencies with known vulnerabilities, (2) new errors
in production logs over the last 24 hours, (3) open PRs without review.
Summarize in 5 plain-language lines, with severity, and open an issue for each
high-severity problem. Don't make code changes in this task.
```

**Setting up a cloud task with a daily trigger + an event trigger:**
1. claude.ai/code/routines → *New task*: prompt, repo, environment (network and secrets), connectors (only the ones needed).
2. *Schedule* trigger: avoid minute :00 (e.g., 7:07).
3. *API* trigger → *Generate token*. The token is shown only once: store it in a secrets manager.
4. Event source → **relay** (Edge Function, your own endpoint or Zapier) → POST with the `Authorization`, `anthropic-beta: experimental-cc-routine-2026-04-01` and `anthropic-version` headers.
5. The prompt covers both cases ("if a payload arrives, handle it; otherwise do the daily review").
   - The payload is **untrusted**.
   - Send IDs, not personal data.

**Limits:**
- API fires: 30 per hour per task and 100 per hour per account.
- GitHub events: hourly caps, number not published.
- In *research preview*: format and limits may change.

### 8.3 Product loop (once there are users)
| Cadence | What | Tool |
|---|---|---|
| Weekly | Review the PRD metrics (North Star and supporting) | `/metrics-review` (`product-management` plugin) |
| Weekly or biweekly | Synthesize feedback (support, interviews, reviews) | `/synthesize-research` |
| Monthly | Watch the competition | `/competitive-brief`, or a monthly cloud task with `/deep-research` |
| Per milestone | Update and communicate the roadmap | `/roadmap-update` + `/stakeholder-update` |

**RULE:** whatever comes out of this (new features, scope changes) is updated **first** in `docs/product/PRD.md` and in the spec, then `/greenfield:initializer --resync` runs (§10). Never straight to code.

---

## 9. Phase 4 — Audits and large-scale changes (ultracode)

**When:** once **there is code**. Never on an empty repo or for architecture decisions.

| Typical moment | Example |
|---|---|
| Every milestone (e.g., every ~10 features) | Security audit against the non-negotiable rules |
| Before going to production | Full readiness review (security, errors, logs, configuration) |
| Every milestone with an interface | UX/UI audit: `/accessibility` (WCAG 2.1 AA) + Impeccable `audit` (P0–P3) and `critique`, against `docs/design/DESIGN.md` |
| Accumulated debt | Test coverage sweep; inconsistencies across modules |
| Broad mechanical change | Library or API migration; applying a pattern across every file |
| Cross-checked research | `/deep-research <question>` (bundled workflow) |

### 9.1 How to turn it on
- **One task:** type `ultracode:` at the start of the prompt, in the interactive session.
- **Whole session:** `/effort ultracode` (`/effort ultracode off` to turn it off), or start with `claude --effort ultracode`.
- `/workflows` shows progress: `p` pauses, `x` stops. Press `s` to save a useful workflow in `.claude/workflows/` and rerun it as `/<name>`.

### 9.2 Templates
```
ultracode: audit the entire codebase against the non-negotiable rules in the spec and CLAUDE.md
(security, payments, personal data, logs). For each finding: file, evidence,
severity (high/medium/low) and how to verify the fix. Do NOT fix anything.
Give me a plain-language summary and the list in docs/audits/YYYY-MM-DD-security.md.
```
```
ultracode: identify modules with no tests or low coverage and propose the missing
test cases, prioritized by risk. Do NOT write code yet.
```
```
ultracode: pre-production review. Check configuration, environment variables,
error handling, logs free of personal data, exposed endpoints, usage limits
and the deploy checklist in CLAUDE.md. Report what blocks the launch and what doesn't.
```

### 9.3 From finding to feature
**RULE:** the audit session **reports; it doesn't fix**. Every high or medium finding becomes a new feature in `feature_list.json` (`category: "finding"`, with `steps` and `verify_cmd`) and is built in Phase 2 like any other. This keeps the one-feature-per-session rule and leaves a history.

**Exception:** a mechanical change with binary verification (e.g., "migrate every call to API v2 until `tsc --noEmit` and the tests exit 0") can run directly as a `mode: ultracode` feature:
```
/goal Every call uses API v2; `tsc --noEmit` and `npm test` exit 0 with the
output visible; commit made and PR opened. Or stop after 15 turns.
```
(with ultracode on in the session)

### 9.4 Cost control
- Ultracode uses meaningfully more tokens: one request can produce several workflows in a row (understand → change → verify).
- Use it **during the day and supervised** the first few times; check usage after each run.
- Configurable limits:
  - `workflowSizeGuideline`: `small` (under 5 agents), `medium` (under 10, the default) or `large` (under 50). On Pro the default is `small`.
  - `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS`.
  - Automatic "Large workflow" warning above 25 agents or 1.5 million projected tokens.
- The `ultracode:` keyword doesn't trigger in `-p`, `/loop` prompts or scheduled tasks. There, use `/effort ultracode` or a saved workflow (whether a cloud task can launch a saved workflow is not confirmed in the docs).

---

## 10. When the spec changes — `/greenfield:initializer --resync`
1. Compares the spec with `feature_list.json`.
2. **Adds** new features with `passes: false`.
3. Marks features that no longer apply as `deprecated`. **Never deletes them.**
4. Resets `passes: false` on affected features, and only those.
5. Shows the diff and waits for approval.

---

## 11. Does it make sense to combine them?

Yes, in some cases, because they control different axes (§3). In others, the combination gets expensive or confusing.

**What the official docs say:**
- **Recommended:** `/goal` + auto mode, because "auto mode removes per-tool prompts, and `/goal` removes per-turn prompts".
- **Alternatives, not complements:** `/goal` and `/loop` (condition vs. clock).
- **Not mentioned:** ultracode + `/goal` and ultracode + `/loop`. Blogs recommend these, not Anthropic.
- **Unconfirmed:** whether a running workflow counts as "background work" that defers the goal evaluation.

### 11.1 ✅ When yes

| Combination | Example | Why it works |
|---|---|---|
| `/goal` + auto mode | Any unattended run | Official combination: no per-tool prompts and no per-turn "should I continue?" |
| `/goal` + Superpowers SDD | Building a feature after approving its plan (§7.3) | Superpowers provides the discipline; `/goal` keeps the session from stopping halfway. Includes the stop clause |
| `/goal` + ultracode | Migrating 200 files to TypeScript strict until `tsc --noEmit` exits 0; raising test coverage to ≥80% | Large, parallelizable task with binary verification. Each turn launches a workflow and the goal decides when to stop |
| `/goal` in one session + `/loop` in another (or another worktree) | One session builds F-008 while another watches F-007's PR CI | Each does its own job. The docs don't describe how they interact in the same session: better to keep them apart |
| `/goal` + a saved verification workflow | A `/verify-e2e` in `.claude/workflows/` that the goal requires to pass | Reproducible evidence |

### 11.2 ❌ When no

| Misuse | Why it fails | Alternative |
|---|---|---|
| Ultracode on an empty repo or for initial scaffolding | Parallel agents make contradictory architecture decisions | Regular session + plan mode + spec |
| `/goal the system is production-ready` | Unverifiable condition: the evaluator has nothing to judge | Exit codes, counts, clean `git status` |
| `/goal` for tone, UX or a bot's prompt | "Make it sound warm" can't be verified by a machine | `mode: human` |
| `/loop 5m keep building the app` | Uses a clock for something that depends on a condition; accumulates context, expires after 7 days and needs the session open | `/goal` |
| `/goal` + ultracode overnight with no cap | No cap by default: 15 turns × a dozen agents means hundreds of instances. There are reports of a 14-hour session that exhausted the weekly limit of a USD 200 plan | Turn and budget caps; try 30 minutes during the day first |
| `ultracode:` inside `/loop`, `-p` or scheduled tasks | The keyword doesn't trigger there | `/effort ultracode` in the session, or a saved workflow |
| `/goal` without a stop clause on top of Superpowers | The goal may push on exactly when Superpowers stopped for a good reason (irreversible action) | "If you need a decision from me, stop" clause (§7.3) |

---

## 12. Anti-patterns (by phase)

Each anti-pattern comes with its symptom and its antidote. If you are an agent and spot one, **tell the human** before continuing.

| Phase | Anti-pattern | Symptom | Antidote |
|---|---|---|---|
| 0A | Building a product that will be sold without researching | "I already know what the market needs" | 0A + go/no-go gate (§5.1) |
| 0B | A PRD full of technical decisions | The PRD talks about frameworks and tables | The PRD is a business document; technical content goes in the spec (0D) |
| 0B | An MVP with no "non-goals" | Scope grows every session | An explicit list of what's **out** |
| 0C | Skipping UX/UI because "it's an MVP" or "it's a bot" | Generic interface; robotic conversation | 0C always (§5.3); for bots, conversation design |
| 0C | Installing two style engines (Impeccable + UI UX Pro Max) | Contradictory design guidance | Pick one (§5.5) |
| 0D | A spec that repeats the PRD and DESIGN | Three documents that contradict each other | The spec references, it doesn't copy (§5.4) |
| 1 | Giant features ("the whole checkout") | Sessions that run out of context | One feature = one session = one reviewable commit |
| 1 | Steps that only test that it compiles | "Passing" features that don't work | Observable steps, as a user would see them |
| 1 | Subjective items without `human_review` | `/goal` "approves" tone or design | `mode: human` |
| 1 | The initializer writes feature code | Scaffolding mixed with unreviewed logic | Rule 1 of `/greenfield:initializer` |
| 2 | Several features per session | Huge commits, exhausted context | `/greenfield:next` takes only one |
| 2 | `/goal` before approving the plan | The plan was never reviewed | The goal goes after checkpoint 1 (§7.3) |
| 2 | `/goal` without a stop clause | It pushes on when Superpowers stopped for a reason | "If you need a decision from me, stop" clause |
| 2 | Vague condition ("make it look good") | The evaluator can't judge | Exit codes, visible output, counts |
| 2 | Believing "tests pass now" without seeing the output | Hidden regressions | `verification-before-completion` |
| 2 | Editing or deleting `steps` so something "passes" | The list stops being trustworthy | Only change `passes`/`status`; fix with `--resync` |
| 2 | Merging locally instead of opening a PR | No history, no CI, hard to revert | Always "open a PR" |
| 2 | A third correction in the same conversation | Claude goes in circles | `/clear` + a better prompt after 2 attempts |
| 3 | `/loop` to build | It expires and accumulates context | `/goal` |
| 3 | `/loop` running for days in a long conversation | Bloated, slow context | Cloud task |
| 3 | Payloads with personal data sent to cloud tasks | Legal risk | Send IDs; the payload is untrusted |
| 3 | The task token committed to the repo | Anyone can trigger it | Secrets manager; rotate if leaked |
| 4 | Ultracode on an empty repo | Contradictory architecture decisions | Ultracode only on existing code |
| 4 | The audit fixes everything at once | Massive unreviewed changes | Report → `finding` features (§9.3) |
| 4 | `/goal` + ultracode overnight with no cap | Weekly limit exhausted | Turn and budget caps; try during the day |
| All | Long `CLAUDE.md` with ALL CAPS and IMPORTANT | Claude ignores key rules | Keep it short; mandatory rules go in hooks |
| All | Too many plugins enabled at once | Expensive context, slower responses | Enable per phase (§4) |
| All | Third-party skills without checking the license | Risk if the product is sold | Check the license (e.g., CC BY-NC-SA is non-commercial) |
| All | Impeccable `live` mode or telemetry on without knowing | Permissions bypassed; data sent out | Don't use `live`; `DO_NOT_TRACK=1` |
| All | Secrets in cloud environment variables or in the chat | Stored in plain text | The environment's credential manager |

---

## 13. Pre-deploy checklist

**Command:** `/greenfield:preflight [release]`. It writes `docs/releases/<date>-preflight.md` with a **GO / NO-GO** verdict. A single red blocker = NO-GO. The preflight **doesn't fix anything**: findings become features.

**A. Automatable** (Claude runs them and shows the output)
- [ ] A1 Build, lint, typecheck and tests green (local + CI on the latest commit)
- [ ] A2 MVP scope complete: all its features `passes: true`, none `in_progress`
- [ ] A3 Human reviews (`human_review`) closed
- [ ] A4 No placeholders (`TODO`, `FIXME`, `[PLACEHOLDER]`, lorem ipsum, project-specific markers)
- [ ] A5 No secrets in the repo; `.env` ignored; `.env.example` up to date
- [ ] A6 The app validates environment variables at startup and fails with a clear message
- [ ] A7 Logs free of personal data
- [ ] A8 Health check that doesn't expose internal state
- [ ] A9 Migrations tested from scratch; no already-applied migration was edited
- [ ] A10 PRD metric events being emitted *(non-blocking)*

**B. Orchestrated reviews** (existing skills)
- [ ] B1 `/security-review` of the release diff (no high findings)
- [ ] B2 `/code-review` of the release diff (no high findings)
- [ ] B3 `/deploy-checklist` (`engineering` plugin): staging, smoke tests, monitoring, rollback
- [ ] B4 Accessibility if there's a UI: `/accessibility` (`design` plugin) or Impeccable `audit` (no P0/P1)
- [ ] B5 First go-live: `ultracode:` pre-production review audit (§9.2)

**C. Human sign-offs**
- [ ] C1 Rollback plan (roll back in under 15 minutes)
- [ ] C2 Monitoring and alerts: who finds out and how
- [ ] C3 Legal and privacy: consent, data policy, deletion
- [ ] C4 Spend limits on AI, cloud and payments
- [ ] C5 Support and an owner on launch day
- [ ] C6 Final go/no-go from the product owner

---

## 14. End-to-end example

**Fictional product:** "CalmSlots", a web app for small wellness studios to manage bookings and payments. It will be sold. User: a studio owner, non-technical, using Claude Code with this kit.

| Step | Phase | What she does | What Claude produces | Her decision |
|---|---|---|---|---|
| 1 | Setup (§4) | Installs the kit's plugins | — | — |
| 2 | 0A | `Use /deep-research to research the market for booking software for wellness studios in Colombia…` (template §5.1) | `docs/product/market-research.md`: 7 alternatives (including WhatsApp + spreadsheets), pricing, gaps (local payments, no-shows), TAM with assumptions, recommendation | **GO**, with the hypothesis "no-shows cost more than the subscription" to validate |
| 3 | 0B | `/write-spec` for the PRD + `/brainstorm` for positioning | `docs/product/PRD.md`: MVP = bookings + reminders + prepayment; **out**: mobile app, multiple locations. North Star: paid bookings per week | Approves and cuts "coupons" from the MVP |
| 4 | 0C | `/impeccable init` → answers: users on mobile, "warm, simple, trustworthy", references and anti-references | `docs/design/PRODUCT.md` + `DESIGN.md` (tokens, states, WCAG AA) and booking and payment flows | Approves the visual direction after seeing the proposal |
| 5 | 0D | Superpowers `brainstorming` (reads PRD and DESIGN) | `docs/superpowers/specs/…-design.md` | Approves the spec |
| 6 | 1 | `/greenfield:initializer` | Profile "web + payments + personal data"; 28 features: F-001 skeleton, F-002 payments spike (ADR), F-003 tokens, … F-024 metric events; `init.sh`, `CLAUDE.md`, hooks, `verify/` with Playwright | Splits F-011 ("checkout") in two; approves |
| 7 | 2 | `/greenfield:next` | Picks F-001; plan in plain language | Approves the plan → pastes the `/goal` |
| 8 | 2 | (waits) | SDD: implements, reviews, tests green, PR opened, Rulings | Reviews the Rulings, chooses "open a PR", merges with green CI |
| 9 | 2 | `/greenfield:next` (new session) | F-002 is a `spike`: ADR with 3 payment gateways and a recommendation | **Decides** on the gateway |
| 10 | 2 | Repeats `/greenfield:next`, one feature per session | F-003 (`human_review`) arrives with styleguide screenshots | Approves by looking at it |
| 11 | 3 | In another session: `/loop 10m check the PR's CI…` | Fixes a flaky test | — |
| 12 | 4 | After ~10 features: `ultracode: audit the entire codebase against the non-negotiable rules…` | Report with 4 findings → F-029…F-032 (`category: finding`) | Prioritizes 2 before launch |
| 13 | Pre-deploy | `/greenfield:preflight v1` | NO-GO: missing rollback plan (C1) and a high finding from `/security-review` | Resolves both → new preflight: **GO** |
| 14 | Deploy + 3 | Launches; creates a daily cloud task (§8.2) | Daily review of errors and vulnerabilities | — |
| 15 | 3 | Weekly `/metrics-review` + `/synthesize-research` on feedback | "Customers are asking for a waitlist" | Updates PRD and spec → `/greenfield:initializer --resync` → F-033 waitlist |

**What this example shows:**
- She decided at **10 checkpoints** (go/no-go, PRD, visual direction, spec, feature list, plans, spike, visual approvals, preflight, scope change) **without reading code**.
- Claude did the rest, with verification and PRs.
- Every scope change went through PRD → spec → `--resync`, never straight to code.

---

## 15. Costs (reference, Nov 2026)

- **Plans:** Pro USD 20/month · Max USD 100 (5× Pro) · Ultra USD 200 (10× Pro). Cloud tasks are included and draw on plan usage; there's no separate charge for the cloud machine.
- **API:** Sonnet 5.5 at USD 2 per million input tokens / USD 10 per million output tokens (cache reads at USD 0.10). Haiku 5.5 at USD 0.10 / 0.50.
- **Our own per-run estimate** (not an official figure):
  - Light: USD 0.10–0.30.
  - Medium (code + tests + PR): USD 0.50–1.50.
  - Heavy or with ultracode: USD 3–10 or more.
- **Spend control:**
  - Use Sonnet by default.
  - Add turn and budget caps.
  - Turn on ultracode only when justified.
  - Review usage during the first week.

---

## 16. Version history and maintenance

| Version | Changes |
|---|---|
| v0.1 | Draft: Phases 0–3, initializer, tools, costs |
| v0.2 | Phase 2 with Superpowers SDD + `/goal` as a safety net |
| v0.3 | Phase 3 (`/loop` + cloud tasks) and Phase 4 (ultracode) |
| v0.4 | Tools according to the official docs; combinations with examples; Phase 2 summary |
| v0.5 | Related official Anthropic practices |
| v0.6 | Expanded Phase 0: market research, product, UX/UI, spec; scored tools |
| **v1.0** | Kit setup; `greenfield` plugin (`initializer`, `next`, `preflight`); anti-patterns; pre-deploy checklist; end-to-end example; published in English |
| v1.0.1 | §2.2 rows verified verbatim against the Best Practices page; *(summary)* markers removed |

**Maintenance:**
- Claude Code tooling changes fast. Review §3, §4 and §15 against the official docs every quarter.
- Before commercial use, check the licenses of third-party skills (deanpeters: CC BY-NC-SA 4.0).
- §2.2 quotes were verified against the source on 2026-11-08; re-check them during the quarterly review.

---

## 17. Sources
- Community: [Boris Cherny "/loop until" → /goal (Threads)](https://www.threads.com/@aabyzov/post/DYOc5I1CDvH/may-boris-cherny-at-anthropic-gets-asked-about-goal-for-claude-code-replies) · [findskill.ai – /goal overnight](https://findskill.ai/blog/claude-code-goal-command/) · [zenn.dev – soft turn cap](https://zenn.dev/zaico/articles/e0678bd81d198c)
- Anthropic, Claude Code docs: [/goal](https://code.claude.com/docs/en/goal) · [Scheduled tasks /loop](https://code.claude.com/docs/en/scheduled-tasks) · [Workflows and ultracode](https://code.claude.com/docs/en/workflows) · [Best practices](https://code.claude.com/docs/en/best-practices) · [Cloud tasks (routines)](https://code.claude.com/docs/en/routines) · [Channels](https://code.claude.com/docs/en/channels) · [GitHub Actions](https://code.claude.com/docs/en/github-actions) · [Headless](https://code.claude.com/docs/en/headless)
- Anthropic Engineering: [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) · [claude-quickstarts/autonomous-coding](https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding)
- Third party: [obra/superpowers](https://github.com/obra/superpowers) ([writing-plans](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md), [subagent-driven-development](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md), [executing-plans](https://github.com/obra/superpowers/blob/main/skills/executing-plans/SKILL.md), [verification-before-completion](https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md), [finishing-a-development-branch](https://github.com/obra/superpowers/blob/main/skills/finishing-a-development-branch/SKILL.md)) · [feature-dev (directory)](https://www.claudedirectory.org/plugins/feature-dev) · [github/spec-kit](https://github.com/github/spec-kit) · [claude-task-master](https://github.com/eyaltoledano/claude-task-master)
- Product and UX (Anthropic): [knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) ([product-management](https://github.com/anthropics/knowledge-work-plugins/tree/main/product-management), [design](https://github.com/anthropics/knowledge-work-plugins/tree/main/design), [marketing](https://github.com/anthropics/knowledge-work-plugins/tree/main/marketing)) · [frontend-design](https://github.com/anthropics/skills/tree/main/skills/frontend-design) · [claude-plugins-official](https://github.com/anthropics/claude-plugins-official)
- Product and UX (third party): [deanpeters/Product-Manager-Skills](https://github.com/deanpeters/Product-Manager-Skills) · [product-on-purpose/pm-skills](https://github.com/product-on-purpose/pm-skills) · [pbakaus/impeccable](https://github.com/pbakaus/impeccable) · [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
- Pricing: [claude.com/pricing](https://claude.com/pricing) · [API pricing](https://platform.claude.com/docs/en/about-claude/pricing)
