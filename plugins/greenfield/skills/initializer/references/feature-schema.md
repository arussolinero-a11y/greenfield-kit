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
| `parallel_safe` | boolean | yes | `true` if it can be built in parallel with others |
| `status` | enum | yes | `pending` \| `in_progress` \| `done` \| `deprecated` |
| `passes` | boolean | yes | `false` until verified with evidence |
| `history` | string[] | no | `--resync` notes (date + reason) |

## Rules for coding sessions
- They may only change `passes`, `status` and `history`.
- They **never** delete features or edit or water down `steps`. If a step is wrong, report it to the human and fix it with `--resync`.
- `passes: true` only with the `verify_cmd` output visible in the conversation (and human approval if `human_review`).
