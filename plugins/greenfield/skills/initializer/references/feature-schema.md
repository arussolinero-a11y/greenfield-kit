# `feature_list.json` schema

A JSON array of objects:

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | `F-001`, `F-002`… (never reused) |
| `category` | string | yes | infra, security, design, product, instrumentation, spike, finding… |
| `description` | string | yes | Observable behavior, in one line |
| `depends_on` | string[] | yes | IDs that must pass first |
| `mode` | enum | yes | `sdd` \| `inline` \| `ultracode` \| `spike` \| `human` |
| `risk` | enum | yes | `low` \| `medium` \| `high` |
| `extra_review` | string[] | no | `security`, `code`, `accessibility` |
| `steps` | string[] | yes | Observable end-to-end verification steps |
| `verify_cmd` | string | yes, except `spike` and `human` | Command that must exit 0 |
| `human_review` | boolean | yes | `true` if a person approves it |
| `requires_human_action` | string[] | no | Steps only a person can do or authorize (deploy, a migration on the live database, a real call with their credential, writing to an external service). `verify_cmd` covers only the local part; each of these steps is closed explicitly (a closing check `verify/close-<ID>.sh`, or the person's confirmation recorded in `history`) |
| `parallel_safe` | boolean | yes | `true` if it can be built in parallel with others |
| `release` | string | yes | Roadmap release: `mvp`, `v2`, `v3`… Only the active release (in `CLAUDE.md`) is built. A feature can't depend on one of a later release |
| `status` | enum | yes | `pending` \| `in_progress` \| `in_review` \| `done` \| `deprecated`. `in_review` = built and verified, waiting for a person (`human_review` or `requires_human_action`) |
| `built_on_unapproved` | string[] | no | Dependencies that were still `in_review` when this feature was built (only with the person's OK). While it isn't empty, the feature stays `in_review`. When a dependency is approved or changes, re-run this feature's `verify_cmd` and clear the entry |
| `passes` | boolean | yes | `false` until verified with evidence |
| `history` | string[] | no | `--resync` notes (date + reason), including release moves |

Lists created before v1.1 have no `release`: until the next `--resync` adds it, read a missing `release` as `mvp`. New lists always include it.

## Rules for coding sessions
- They may only change `passes`, `status`, `built_on_unapproved` and `history`. Moving a feature to another release is a scope change: it goes through `--resync`.
- They **never** delete features or edit or water down `steps`. If a step is wrong, report it to the human and fix it with `--resync`.
- `passes: true` only with the `verify_cmd` output visible in the conversation, plus human approval if `human_review`, every `requires_human_action` step closed, and `built_on_unapproved` empty. Until then the feature is `in_review`, with a `history` note saying since when and what it waits for.
- A `spike` is `in_review` until the person approves its ADR. The approved ADR is its evidence: record the approval (date, decision) in `history`, then `done` and `passes: true`.
