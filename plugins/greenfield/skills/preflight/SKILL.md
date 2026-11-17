---
name: preflight
description: Pre-deploy checklist from the greenfield guide. Runs the automatable checks (build/lint/test, feature_list.json status, placeholders, secrets, logs with personal data), orchestrates /security-review, /code-review, the engineering plugin's /deploy-checklist and the design plugin's accessibility review, and produces a GO/NO-GO report with the items a person must sign off. Use before any production deploy or launch ("preflight", "are we ready to ship?", "pre-deploy checklist", "go-live").
argument-hint: "[release name]"
---

# /greenfield:preflight

Produces `docs/releases/<YYYY-MM-DD>-preflight.md` with a **GO / NO-GO** verdict. A single red blocking item = NO-GO.
Explain the result in plain language: the user may not be technical.
The greenfield guide ships with this plugin: `../../claude-code-greenfield-guide.md` (relative to this skill's folder). Section numbers below (§) refer to it.

## A. Automatable (Claude runs them and shows the output)
| # | Check | How | Blocking |
|---|---|---|---|
| A1 | Build, lint, typecheck and tests green | Commands from `CLAUDE.md` + CI status of the latest commit, if there's CI | Yes |
| A2 | Release scope complete | Every feature whose `release` is the one being shipped has `passes: true`; none `in_progress` | Yes |
| A3 | Human reviews closed | Every feature with `human_review: true` approved (recorded in the progress log or PR) | Yes |
| A4 | No placeholders | Search for `TODO`, `FIXME`, `[PLACEHOLDER]`, `lorem ipsum`, `XXX` and project-specific markers | Yes (in production code) |
| A5 | No secrets in the repo | `.env` in `.gitignore`; search recent history for keys and tokens; `.env.example` exists | Yes |
| A6 | Environment validation | The app fails fast with a clear message if a variable is missing | Yes |
| A7 | Logs free of personal data | Search for logs that print message bodies, emails, phone numbers or tokens | Yes, if there's personal data |
| A8 | Health check | The health endpoint responds without exposing internal state | Yes (if there's a service) |
| A9 | Migrations | Tested from scratch (reset + apply all); no already-applied migration was edited | Yes (if there's a DB) |
| A10 | Metrics | The PRD's instrumentation events are emitted (local test) | No |

## B. Orchestrated reviews (invoke the skills or ask the user to run them)
| # | Review | Tool | Blocking |
|---|---|---|---|
| B1 | Security of the release diff | `/security-review`; in a local-only project (no remote), a fresh read-only reviewer with `../next/references/local-security-checklist.md` on the release diff | Yes, if there are high findings |
| B2 | Correctness of the release diff | `/code-review` | Yes, if there are high findings |
| B3 | Operational checklist (staging, smoke tests, monitoring, rollback) | `/deploy-checklist` (Anthropic's `engineering` plugin) | Yes |
| B4 | Accessibility (if there's a UI) | `/accessibility` (`design` plugin) or Impeccable `audit` | Yes, if there are P0/P1 findings |
| B5 | Broad pre-launch audit (first go-live) | `ultracode:` with the pre-production review template (guide §9.2) | Depends on findings |

## C. Human sign-offs (Claude prepares the evidence; the person checks the box)
- [ ] **Rollback plan** written and understood (how to roll back in under 15 minutes).
- [ ] **Monitoring and alerts**: who finds out if something fails (e.g., a daily cloud task + platform alerts).
- [ ] **Legal and privacy**: consent, data policy, deletion mechanism (per country).
- [ ] **Spend limits**: caps on AI, cloud and payment providers.
- [ ] **Support**: a channel for users and an owner on launch day.
- [ ] **Final go/no-go** from the product owner.

## The deploy itself (after GO)
The preflight doesn't deploy. When the user moves on to deploy, remind them (guide §13):
- Production steps (deploy, migrations on the live database, writing secrets) run in an **attended session** with the user approving each command. In auto mode the safety classifier blocks them one by one even if the user authorized them together; that's expected.
- For release steps that repeat, a narrow allow rule in `.claude/settings.local.json` for the exact commands is optional (no wildcards), and the release is still approved in the session.

## Report format
```markdown
# Preflight — <release> — <date>
**Verdict:** GO | NO-GO
## Red blockers
- <item> — <evidence> — <what to do>
## Results
| # | Status | Evidence |
## Pending human sign-offs
## Non-blocking findings → proposed new features (category: "finding")
```
**RULE:** the preflight **doesn't fix anything**. Each finding is proposed as a new feature (guide §9.3) and built with `/greenfield:next`.
