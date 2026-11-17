# Local security review checklist

Use it when `/security-review` can't run because the repo has no remote (guide §7.8). Give it to a **fresh, read-only reviewer** (Read, Grep, Glob, and `git diff`), together with the diff to review:
- one feature: `git diff <main-branch>...feature/<ID>`;
- a release (preflight B1): `git diff <last-release-tag-or-commit>...HEAD`.

For each item, the reviewer answers **OK**, **Finding** (file, line, what's wrong, severity high/medium/low) or **N/A** (with the reason). It doesn't fix anything.

| # | Check |
|---|---|
| 1 | **Secrets:** no keys, tokens, passwords or connection strings in code, config, tests, fixtures or docs. `.env` and `private/` stay git-ignored. |
| 2 | **Personal data in logs and errors:** nothing logs or returns message bodies, emails, phone numbers, tokens or other personal data. |
| 3 | **Access control:** every new endpoint, action or query checks who is asking and whether they may do it; no reliance on the interface hiding a button. |
| 4 | **Input:** everything coming from users or external services is validated and size-limited; queries are parameterized; output is escaped where it's rendered. |
| 5 | **External calls:** timeouts, error handling, and no secrets or personal data sent where the spec doesn't allow it. |
| 6 | **Files and permissions:** files the app writes have the narrowest permissions needed; no paths built from user input without checks. |
| 7 | **Dependencies:** new or upgraded packages are needed, maintained and pinned; no install scripts from unknown sources. |
| 8 | **Non-negotiable rules:** each rule in `CLAUDE.md` that this diff touches still holds, with a test that would fail if it broke. |

A **high** finding blocks the merge (feature) or the release (preflight) until it's fixed or the human explicitly accepts the risk.
