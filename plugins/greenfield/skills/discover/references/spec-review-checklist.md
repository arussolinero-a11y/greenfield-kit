# Spec review checklist (0D builder review)

For a **fresh, read-only reviewer**. Answer each item **OK**, **Finding** (section, what's wrong, proposed fix, and whether it's **blocking**) or **N/A**. Don't rewrite the spec, and skip style and wording.

A finding is **blocking** when it would make the spec impossible or wrong to build: a rule that can't be computed, a missing starting value, a contradiction, a missing contract, unhandled sensitive data. Only blocking findings start another round with a new reviewer. Stop when a round has none, and after 3 rounds the person decides what's still open.

| # | Check |
|---|---|
| 1 | **Inputs respected:** the spec follows the PRD's MVP scope, core and roadmap, `DESIGN.md`, the design handoff and the integration check. It references them instead of copying them. |
| 2 | **Every rule is computable:** each business rule can be calculated with fields the data model actually defines. No rule depends on data nobody stores. |
| 3 | **Every parameter has a starting value:** thresholds, limits and defaults all have an initial value and a stated owner who can change it. |
| 4 | **The first run can comply:** with the starting values and an empty or fresh state, every rule can be met. No rule fails by construction on day one. |
| 5 | **Integrations:** each external call has its contract (inputs, outputs, errors), its limits and its failure behavior. Unknowns are marked as spikes. |
| 6 | **Sensitive data:** what's stored, what leaves the system and to whom, what must never be inferred or logged. |
| 7 | **Non-negotiable rules** are listed, and each says how it will be verified (a test, a hook, an eval, a human check). |
| 8 | **Non-goals and "done":** explicit non-goals; "done" criteria a person can check. |
| 9 | **No contradictions:** between sections, and with the PRD and design. Check again after each fix: fixes introduce new ones. |
| 10 | **Buildable in slices:** the spec can be cut into features that each fit in one session, with the walking skeleton first. |
