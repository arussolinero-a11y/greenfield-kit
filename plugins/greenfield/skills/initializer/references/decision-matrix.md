# Initializer decision matrix

## a) Verification by project type
| Profile | Tooling generated in `verify/` |
|---|---|
| Web UI | E2E with Playwright + screenshots (normal, empty, error, mobile) + check against `DESIGN.md` |
| API / webhooks | Contract tests + a script that simulates requests (signed, if applicable) |
| Conversational bot | Conversation simulator + "golden" transcripts |
| AI outputs (tone, judgment) | Evals: cases + LLM judge + human-reviewed sample (`human_review`) |
| CLI | Comparison against expected outputs |
| Library | Unit tests + property tests |
| Data pipeline | Fixtures + per-stage counts and invariants |

## b) Size and order
- Each feature fits in **one session**, roughly one reviewable commit. The count scales with the spec (no fixed number).
- Order:
  1. Walking skeleton (a trivial end-to-end path, deployed).
  2. Spikes for unknowns (their deliverable is an ADR).
  3. Design system (if there's a UI).
  4. Risks: security, payments, integrations.
  5. Core value (the PRD's MVP scope).
  6. Metrics instrumentation.
  7. Polish.

## c) Execution mode (`mode`)
| `mode` | When | How it runs in Phase 2 |
|---|---|---|
| `sdd` (default) | Binary verification | Superpowers `writing-plans` → `subagent-driven-development` → PR, with `/goal` as a safety net |
| `inline` | Small and low-risk | `writing-plans` → `executing-plans` |
| `ultracode` | Broad and mechanical | `writing-plans` → `/goal` with ultracode on |
| `spike` | Technical unknown | Regular session → ADR in `docs/decisions/` → the human decides |
| `human` | Subjective criteria (tone, UX, copy) | Claude prepares the evidence; a person approves |

Add `extra_review: ["security"]` to features with `risk: "high"` (and `["code"]` if they're complex).

## d) Non-negotiable rules → controls
- **Deterministic** (`.claude/settings.json`): Stop hook running typecheck and tests (`<cmd> 1>&2 || exit 2`); `deny` rules for `.env`, keys and secrets.
- **Judgment-based**: a line in `CLAUDE.md` + a dedicated verification feature (e.g., an eval).
