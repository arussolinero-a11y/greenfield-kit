# greenfield-kit

A practical guide + Claude Code plugin for building greenfield products **end to end**, from market research to deploy and operations, following Anthropic's best practices.

- 📘 **Guide:** [`claude-code-greenfield-guide.md`](claude-code-greenfield-guide.md). Written to be read by people and agents.
- 🧩 **`greenfield` plugin:** three skills that orchestrate Superpowers and Anthropic's plugins.

| Skill | Phase | What it does |
|---|---|---|
| `/greenfield:initializer [--resync]` | 1 | Reads spec + PRD + DESIGN, profiles the project and generates `feature_list.json`, `init.sh`, `CLAUDE.md`, hooks and `verify/`, **without implementing features** |
| `/greenfield:next [F-ID]` | 2 | Start routine → picks the next feature → plan with Superpowers → hands you the `/goal` to paste |
| `/greenfield:preflight [release]` | Pre-deploy | Automated checks + `/security-review`, `/code-review`, `/deploy-checklist`, accessibility → GO / NO-GO |

## Install
```
/plugin marketplace add arussolinero-a11y/greenfield-kit
/plugin install greenfield@greenfield-kit
```
The companion plugins (Superpowers, product-management, design, engineering, frontend-design, playwright and, optionally, Impeccable) are listed in §4 of the guide.

## The flow in one line
`Phase 0` (market research → PRD → UX/UI → spec) → `/greenfield:initializer` → `/greenfield:next` × N → `/greenfield:preflight` → deploy → Phase 3 (`/loop`, cloud tasks, metrics) → `--resync` when the spec changes.

## Layout
```
.claude-plugin/marketplace.json
plugins/greenfield/
  .claude-plugin/plugin.json
  skills/initializer/   SKILL.md, references/ (matrix, schema), templates/
  skills/next/          SKILL.md
  skills/preflight/     SKILL.md
claude-code-greenfield-guide.md
```

## License
[Apache 2.0](LICENSE). Third-party plugins referenced in the guide keep their own licenses. Check them before commercial use (see §5.5 and §16 of the guide).
