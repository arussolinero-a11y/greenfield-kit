# greenfield-kit

A practical guide + Claude Code plugin for building greenfield products **end to end**, from market research to deploy and operations, following Anthropic's best practices.

- 📘 **Guide:** [`plugins/greenfield/claude-code-greenfield-guide.md`](plugins/greenfield/claude-code-greenfield-guide.md). Written to be read by people and agents. It ships inside the plugin, so the skills can always read it.
- 🧩 **`greenfield` plugin:** five skills that orchestrate Superpowers and Anthropic's plugins.

| Skill | Phase | What it does |
|---|---|---|
| `/greenfield:discover [sub-phase]` | 0 | Guides product, UX/UI and spec one sub-phase per session: market research or benchmark, PRD with MVP roadmap, UX/UI with prototype gate, integration check, spec with a review loop |
| `/greenfield:initializer [--resync]` | 1 | Reads spec + PRD + DESIGN, profiles the project and generates `feature_list.json`, `init.sh`, `CLAUDE.md`, hooks and `verify/`, **without implementing features** |
| `/greenfield:build-path` | 2 | Measures the project, asks you 4 plain questions and recommends how to build (`lean`, `lean-fast`, `lanes` or `guided`). You choose |
| `/greenfield:next [F-ID \| fixes]` | 2 | Start routine → picks the next feature → builds it on your chosen path, with a fresh reviewer and severity triage. `fixes` runs a fix session for what you found |
| `/greenfield:preflight [release]` | Pre-deploy | Automated checks + `/security-review`, `/code-review`, `/deploy-checklist`, accessibility → GO / NO-GO |

## Install
```
/plugin marketplace add arussolinero-a11y/greenfield-kit
/plugin install greenfield@greenfield-kit
```
The companion plugins (Superpowers, product-management, design, engineering, frontend-design, playwright and, optionally, Impeccable) are listed in §4 of the guide.

Works with or without GitHub: local-only projects are supported (§7.8 of the guide).

## The flow in one line
`/greenfield:discover` (Phase 0: research or benchmark → PRD → UX/UI → integrations → spec) → `/greenfield:initializer` → `/greenfield:build-path` → `/greenfield:next` × N → `/greenfield:preflight` → deploy → Phase 3 (`/loop`, cloud tasks, metrics) → `--resync` when the spec changes.

## Layout
```
.claude-plugin/marketplace.json
plugins/greenfield/
  .claude-plugin/plugin.json
  claude-code-greenfield-guide.md   the guide
  skills/discover/      SKILL.md, templates/ (phase 0 status, benchmark, integrations), references/ (spec checklist)
  skills/initializer/   SKILL.md, references/ (matrix, schema), templates/ (incl. gate.sh)
  skills/build-path/    SKILL.md, templates/ (build path, backlog, build log)
  skills/next/          SKILL.md, references/ (plan template, planner/implementer/reviewer agents, local security checklist)
  skills/preflight/     SKILL.md
claude-code-greenfield-guide.md     pointer to the guide's new location
```

## License
[Apache 2.0](LICENSE). Third-party plugins referenced in the guide keep their own licenses. Check them before commercial use (see §5.5 and §16 of the guide).
