# dev-toolkit

[![Claude Code Marketplace](https://img.shields.io/badge/Claude%20Code-Marketplace-6C3EF5?logo=anthropic&logoColor=white)](https://github.com/osamucamarques/dev-toolkit)

A plugin marketplace for Claude Code. Each plugin is a self-contained directory under `plugins/` with a `plugin.json` manifest, one or more skills, and optional rules and settings.

> **Third-party skills.** Some skills here are derived from other open-source projects — [obra/superpowers](https://github.com/obra/superpowers) (MIT) and the [Tech Leads Club agent-skills](https://github.com/tech-leads-club/agent-skills) catalog (CC BY 4.0). Their licenses are respected: each derived file carries an inline attribution and `derived_from` / `source_url` frontmatter, and the full notices are in [NOTICE](NOTICE). See [License](#license) for details.

---

## Developer Workflows

Step-by-step guides for using the plugin stack from first setup through shipping:

| Language / Stack | Workflow |
|-----------------|---------|
| Java / Spring Boot | [docs/workflows/java.md](docs/workflows/java.md) |
| Node.js, Python, Go, Rust | [docs/workflows/other-languages.md](docs/workflows/other-languages.md) |

**At a glance — Java:**
1. Add marketplace (one-time): `/plugin marketplace add https://github.com/osamucamarques/dev-toolkit.git`
2. Install plugins: `/plugin install project-setup@dev-toolkit` + `java-code-standards` + `intent-ops`
3. `/project-init` — create or sync `CLAUDE.md`
4. `/project-setup:codebase-mapping` — map the codebase into `docs/codebase/`, restart session
5. `Spec out PROJ-1234` → approve → `Write the implementation plan` → approve → `Execute the plan with task-runner`
6. `/commit` → `Ship this`

**At a glance — Other languages:**
1. Add marketplace (one-time): `/plugin marketplace add https://github.com/osamucamarques/dev-toolkit.git`
2. Install plugins: `/plugin install project-setup@dev-toolkit` + `intent-ops`
3. `/project-init` → `/project-setup:codebase-mapping` → restart
4. Same spec → plan → execute → ship cycle, without java-code-standards

---

## Available Plugins

| Plugin | Category | Skills | Description |
|--------|----------|--------|-------------|
| [`intent-ops`](plugins/intent-ops/) | product-engineering | `spec-writer` `retro-spec` `plan-writer` `plan-executor` `task-runner` `tdd-guide` `code-reviewer` `worktree-setup` `branch-shipper` `review-receiver` | Full Spec → Plan → Execute → Ship pipeline. Produces SPEC.md from a plain description or a Jira ticket (or from existing code via `retro-spec`), PLAN.md from specs, and drives TDD execution with per-task subagent isolation and two-stage review gates. Atlassian MCP is optional (enables Jira/Confluence sync). |
| [`project-setup`](plugins/project-setup/) | workspace | `codebase-mapping` `docs-writer` | Language-agnostic workspace tools: codebase documentation, project initialization, and conventional commit generation. |
| [`java-code-standards`](plugins/java-code-standards/) | code-quality | `coding-guidelines` `cognitive-driven-development` `coupling-analysis` `coverage-driven-test-generation` | Coordinated set of four skills + one rule enforcing a consistent Java coding standard: ICP ≤ 7, balanced coupling, MC/DC JaCoCo coverage. |

---

## Plugin Structure

```
.claude-plugin/
└── marketplace.json             # marketplace index (required)
LICENSE                          # MIT
NOTICE                           # third-party attributions (see License below)
plugins/
└── <plugin-name>/
    ├── .claude-plugin/
    │   └── plugin.json          # manifest (required)
    ├── skills/
    │   └── <skill-name>/
    │       ├── SKILL.md         # skill instructions + frontmatter
    │       └── references/      # files the skill loads on demand
    │           └── <name>.md    # prompt templates, checklists, output templates
    ├── commands/
    │   └── <command>.md         # slash command; filename is the command name
    ├── rules/
    │   └── <rule-name>.md       # auto-loaded rule (path-scoped)
    └── settings/
        └── settings.json        # permission allowlist for this plugin
```

Skills, commands, and rules are auto-discovered from directory structure — do not list them in the manifest. A `references/` file is never auto-loaded; the `SKILL.md` names it and the agent reads it only when the workflow reaches that point.

### .claude-plugin/plugin.json fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Unique plugin identifier (kebab-case) |
| `version` | yes | SemVer string |
| `description` | yes | What the plugin does and when to use it |
| `author` | yes | Object with a `name` field (`email` optional) |

### SKILL.md frontmatter fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Must match the skill's directory name |
| `description` | yes | When to use and when *not* to use — this is what triggers the skill |
| `license` | yes | `MIT`, or the upstream license when the skill is derived |
| `disable-model-invocation` | no | `true` makes the skill user-invoked only, via `/<plugin>:<skill>` |
| `derived_from`, `source_url` | when derived | Upstream identifier and a permanent link to the exact file |
| `metadata.author`, `metadata.version` | yes | Author name and the skill's own SemVer |

---

## Installing Plugins

### Step 1 — add or update the marketplace

First time (one-time per machine):

```
/plugin marketplace add https://github.com/osamucamarques/dev-toolkit.git
```

Already added — pull the latest:

```
/plugin marketplace update dev-toolkit
```

### Step 2 — install plugins into your project

```
/plugin install project-setup@dev-toolkit
/plugin install java-code-standards@dev-toolkit
/plugin install intent-ops@dev-toolkit
```

Run these commands inside the target project's Claude Code session. For non-Java projects, skip `java-code-standards`.

### Skill activation

Skills activate automatically when Claude detects a matching user prompt. See each skill's `description` frontmatter for trigger conditions.

Rules in `.claude/rules/` are auto-loaded for every conversation matching the rule's `paths` glob.

---

## Plugin Catalogue

### intent-ops

Full Spec → Plan → Execute → Ship pipeline. Works from a plain feature description; a Jira story is optional and enriches the flow when present.

**`spec-writer`** — produces a formal `SPEC.md` from a plain description or a Jira ticket:
- Phase 0.1 — checks for an existing spec (`revise` / `rewrite` / `view`); detects code-first scenarios and redirects to `retro-spec`
- Phase 0–0.6 — context harvest (optional Jira harvest when a key is given, otherwise from the description + codebase), spec language selection, ubiquitous language glossary
- Phase 1–2.5 — scope assessment, Socratic DDD interview (one question at a time, ≥ 95% confidence), bounded context map
- Phase 3 — 2–3 design approaches, presented only after context, outcomes, constraints, and out-of-scope are fully understood
- Phase 4–5.5 — EARS/GEARS SPEC.md authoring (includes explicit Out of Scope section and optional Decisions and Deviations); self-review gate checks AC verifiability; sub-agent spec review
- Phase 6 — HARD-GATE: no implementation until explicit approval
- Phase 7 — saves to `docs/specs/` (key-prefixed filename when a Jira key is present, plain slug otherwise), optional Confluence sync when a ticket is linked

**`retro-spec`** — produces a `SPEC.md` from *existing code* (code-first or retroactive documentation):
- Discovers changed files from the feature branch diff
- Validates intent through a focused interview ("is this right?" not "what should it do?")
- Flags idempotency gaps and backward compat risks in Section 13
- Section 12 (Decisions and Deviations) documents intentional deviations separately from gaps
- Offers to generate a gap-fix plan if deviations are found

**`plan-writer`** — produces a `PLAN.md` from an approved `SPEC.md`:
- Phase 0.1 — checks for an existing plan before starting
- Phase 0.7 — codebase pre-read before the architecture interview: answers questions from code, only asks the user what the code cannot answer
- Architecture interview → file structure proposal → bite-sized TDD tasks with exact code
- HARD-GATE: no execution until explicit approval; optional Jira subtask creation

**`task-runner`** — executes the plan with fresh subagents per task:
- Detects already-completed tasks before dispatching
- Per task: implementer → spec compliance review → code quality review, loop until both pass
- Final review across the full implementation, then hands off to `branch-shipper`

**`plan-executor`** — inline single-session alternative to `task-runner`

**`tdd-guide`**, **`code-reviewer`**, **`worktree-setup`**, **`branch-shipper`**, **`review-receiver`** — supporting skills. All `intent-ops` skills are user-invoked (`disable-model-invocation`), so the pipeline never auto-triggers them: `worktree-setup`, `branch-shipper`, and `review-receiver` are run by you via `/intent-ops:<skill>` when a skill suggests the handoff, while `tdd-guide` and `code-reviewer` contribute by having their `references/` prompts loaded directly into the task subagents.

**Optional:** Atlassian MCP — only needed for Jira harvest, subtask creation, and Confluence sync. The full pipeline runs without it.

---

### java-code-standard

Four coordinated skills + one rule. The three code skills must always be used together when writing or changing Java code:

| Skill | Purpose |
|-------|---------|
| `coding-guidelines` | Behavioral rules: think before coding, simplicity first, surgical changes, goal-driven execution |
| `cognitive-driven-development` | Measures ICP per class; enforces ≤ 7 hard limit; guides refactoring strategies |
| `coupling-analysis` | Three-dimensional coupling model (strength × distance × volatility); classifies Intrusive / Functional / Model / Contract coupling |
| `coverage-driven-test-generation` | JaCoCo XML analysis → MC/DC JUnit 5 + Mockito test generation; prioritizes partial branches first |

The `code-standard.md` rule (auto-loaded for `src/**/*.java`) summarizes the Definition of Done, testing enforcement checklist, and **Contracts & Compatibility** requirements: idempotency (state-mutating ops must be retry-safe) and backward compatibility (no breaking API changes without a version bump).

---

## Contributing

1. Create a new directory under `plugins/<plugin-name>/`
2. Add `.claude-plugin/plugin.json` with `name`, `version`, `description`, and `author` (object)
3. Add skills under `plugins/<plugin-name>/skills/<skill-name>/SKILL.md`
4. Add rules under `plugins/<plugin-name>/rules/` if needed
5. Add `settings/settings.json` with any permission allowlist entries the skill needs
6. Register the plugin in `.claude-plugin/marketplace.json`
7. Update this README's plugin table

### If a skill is adapted from someone else's work

Adapting an existing skill is welcome — reinventing a good prompt is waste. Attribution is not optional, though, and it is easy to lose track of once a file has been edited a few times. When any part of a skill comes from another project:

1. Add `derived_from` and `source_url` to the `SKILL.md` frontmatter — `source_url` must link the exact upstream file, pinned to a tag or commit if the path is unstable.
2. Add an attribution blockquote directly under the file's H1, naming the upstream author, its license, and **what you changed**. Several licenses require the "indicate changes" part, so write it even when it feels obvious.
3. Set `license` to the upstream license if it is more restrictive than MIT. A CC BY 4.0 upstream stays CC BY 4.0 — it does not become MIT because it now lives here.
4. Add the file to [NOTICE](NOTICE), under the existing entry for that upstream or a new one.

The same applies to `references/` files, which is where derivation is easiest to miss — a prompt template copied into `references/` needs the same treatment as a `SKILL.md`.

---

## License

[MIT](LICENSE) © Samuel Marques — with the third-party attributions below. See [NOTICE](NOTICE) for the full notices and the complete file-by-file list.

Every derived file carries an inline attribution blockquote plus `derived_from` / `source_url` frontmatter naming its upstream and the changes made.

### `intent-ops` — derived from obra/superpowers (MIT)

Eight files across six `intent-ops` skills are derived from the [superpowers](https://github.com/obra/superpowers) skills library by **Jesse Vincent**, MIT licensed — `branch-shipper`, `worktree-setup`, `plan-writer`, `task-runner`, `code-reviewer`, and `tdd-guide` retain upstream logic or scaffolding with substantial additions. Jesse Vincent's copyright notice is reproduced in [NOTICE](NOTICE) as the MIT License requires.

The three reviewer-prompt templates in `plan-writer`, `spec-writer`, and `retro-spec` were rewritten from scratch and are no longer derived.

### Three skills under CC BY 4.0, not MIT

| Skill | Upstream |
|-------|----------|
| `java-code-standards/coding-guidelines` | [`(development)/coding-guidelines`](https://github.com/tech-leads-club/agent-skills/blob/main/packages/skills-catalog/skills/%28development%29/coding-guidelines/SKILL.md) by **ale** |
| `java-code-standards/coupling-analysis` | [`(architecture)/coupling-analysis`](https://github.com/tech-leads-club/agent-skills/blob/main/packages/skills-catalog/skills/%28architecture%29/coupling-analysis/SKILL.md) |
| `project-setup/docs-writer` | [`(development)/docs-writer`](https://github.com/tech-leads-club/agent-skills/blob/main/packages/skills-catalog/skills/%28development%29/docs-writer/SKILL.md) |

`java-code-standards` also builds on published methodology: Cognitive-Driven Development (ICP) and the three-dimensional coupling model from *Balancing Coupling in Software Design* by Vlad Khononov. Those are cited in the skills that use them.
