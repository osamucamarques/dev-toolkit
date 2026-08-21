# Java Developer Workflow

End-to-end workflow for Java/Spring Boot projects using the dev-toolkit plugin stack.

---

## Plugins Required

| Plugin | Purpose |
|--------|---------|
| [`project-setup`](../../plugins/project-setup/) | Codebase mapping, CLAUDE.md initialization, conventional commits |
| [`java-code-standards`](../../plugins/java-code-standards/) | ICP enforcement, coupling analysis, JaCoCo coverage generation |
| [`intent-ops`](../../plugins/intent-ops/) | Spec → Plan → Execute → Ship pipeline |

---

## Phase 0 — Project Setup *(one-time per project)*

### Step 1: Add the marketplace and install plugins

Add the marketplace once (skip if already done):

```
/plugin marketplace add https://github.com/osamucamarques/dev-toolkit.git
```

If already added, update to get the latest plugins:

```
/plugin marketplace update dev-toolkit
```

Then install the plugins into the current project:

```
/plugin install project-setup@dev-toolkit
/plugin install java-code-standards@dev-toolkit
/plugin install intent-ops@dev-toolkit
```

### Step 2: Initialize CLAUDE.md

```
/project-init
```

Creates (or syncs) `CLAUDE.md` with the Document Map, code standards, security rules, and skill/rule references. The file tells Claude what to load and when — so it doesn't flood context on every session.

### Step 3: Map the codebase

**Brownfield project** (existing codebase):

```
/project-setup:codebase-mapping
```

This produces 7 Markdown files in `docs/codebase/` — stack, architecture, conventions, structure, testing, integrations, and concerns. Claude reads these on-demand instead of re-exploring the whole project each session.

**Greenfield project** (starting from scratch):

Scaffold the project first (Spring Initializr, `./gradlew init`, etc.), then run:

```
/project-setup:codebase-mapping
```

Run it again after any major structural change (new module, architecture shift).

### Step 4: Restart Claude Code

After `/project-init` completes, restart the session. The new `CLAUDE.md`, rules, and skills become active. You only need to do this once per setup or after adding new plugins.

---

## Phase 1 — Implementing a User Story *(repeat per story)*

> **Invoke `intent-ops` skills by slash command.** Every skill in this pipeline is user-invoked only (`disable-model-invocation`), so natural-language phrases like "spec this out" will **not** trigger them — you must call `/intent-ops:<skill>`. Each skill hands off to the next by telling you which command to run. Pass the Jira key or a plain description as arguments after the command.

### Step 1: Write the Spec

Run `spec-writer`, passing a Jira ticket key or URL — or just a plain description. Jira is optional:

```
/intent-ops:spec-writer PROJ-1234
```
```
/intent-ops:spec-writer the new tenant self-signup flow, before we code
```

`intent-ops:spec-writer` takes over:
- Checks for an existing spec — if one is found, offers to **revise**, **rewrite**, or **view** it
- If a Jira key was given, fetches the ticket, linked issues, and 90 days of org history from Atlassian; otherwise works from your description plus a codebase scan
- Bootstraps a ubiquitous language glossary from the available sources (ticket if any, conversation, and codebase)
- Runs a Socratic DDD interview (one question at a time) until ≥ 95% confidence
- Maps bounded contexts and classifies relationships (U/D, ACL, OHS, Shared Kernel)
- Presents 2–3 design approaches before writing anything
- Produces a `SPEC.md` with EARS/GEARS requirements and acceptance criteria
- **Hard-gate:** no code until you explicitly approve the spec

Approve, request changes, or ask for further decomposition. Once approved, the spec is saved to `docs/specs/` and optionally synced to Confluence.

> **Already wrote the code first?** Use `retro-spec` instead (the Jira key is optional here too):
> ```
> /intent-ops:retro-spec PROJ-1234
> ```
> `intent-ops:retro-spec` reads the implementation, validates intent through a focused interview, and produces a spec that documents what was built — Section 12 (Decisions and Deviations) records intentional deviations, Section 13 flags idempotency gaps and backward compat risks.

### Step 2: Write the Plan

After spec approval, run `plan-writer` with the saved spec path:

```
/intent-ops:plan-writer docs/specs/PROJ-1234-tenant-self-signup.md
```

`intent-ops:plan-writer` takes over:
- **Phase 0.7:** reads the codebase before asking any questions — identifies relevant files, answers architecture questions from code, only asks the user what the code cannot answer
- Runs an architecture interview (one question at a time) for anything the codebase didn't resolve
- Proposes the file structure (every file mapped to a single responsibility)
- Produces a `PLAN.md` decomposed into bite-sized TDD tasks — each with exact file paths, complete code, and expected test output
- **Hard-gate:** no execution until you explicitly approve the plan

Optionally, Claude will offer to create the plan tasks as Jira subtasks.

### Step 3: Execute

After plan approval, choose your execution mode:

**Task Runner (recommended — higher quality):**

```
/intent-ops:task-runner
```

`intent-ops:task-runner` dispatches a fresh subagent per task:
1. **Implementer subagent** — executes the task following `tdd-guide` (failing test → verify RED → minimal code → verify GREEN → refactor)
2. **Spec compliance review** — verifies the implementation matches the spec before advancing
3. **Code quality review** — checks ICP limits, coupling, and code quality
4. Repeats until both reviews pass, then advances to the next task

Java code quality is enforced automatically on every task via the `java-code-standards` trio:
- `coding-guidelines` — simplicity, surgical changes, no speculation
- `cognitive-driven-development` — ICP ≤ 7 per class; Abstraction Gate before any extraction
- `coupling-analysis` — strength × distance × volatility classification

After all tasks pass, a final review runs across the full implementation.

**Inline Execution (single session, no subagents):**

```
/intent-ops:plan-executor
```

`intent-ops:plan-executor` runs the same TDD cycle in the current session. Use this when subagents are unavailable or you prefer full visibility.

### Step 4: Generate Coverage

After each task (or at the end):

```
Complete coverage for the changes
```

`java-code-standards:coverage-driven-test-generation` reads the JaCoCo XML report, identifies missed branches and partially-covered lines, and generates JUnit 5 + Mockito tests using MC/DC strategy to close the gaps. No production code changes.

### Step 5: Commit

```
/commit
```

Prompts for a Jira issue ID and generates a conventional commit message in the format `[PROJ-1234] feat(scope): description`. Commits automatically.

### Step 6: Ship the Branch

When all tasks are complete and tests are green:

```
/intent-ops:branch-shipper
```

`intent-ops:branch-shipper` takes over:
1. Runs the full test suite — stops if anything fails
2. Detects workspace state (normal repo, git worktree, detached HEAD)
3. Presents the integration menu:
   - **Merge locally** — pulls base branch, merges, runs tests, cleans up worktree
   - **Push + create PR** — pushes branch, opens a GitHub PR with summary and test plan
   - **Keep as-is** — preserves branch and worktree for later
   - **Discard** — deletes branch and worktree after typed confirmation

---

## Phase 2 — Ongoing Operations

### Addressing review feedback

When a PR receives comments or a subagent review returns issues:

```
/intent-ops:review-receiver
```

`intent-ops:review-receiver` reads all feedback before touching code, verifies each item against the actual codebase, applies YAGNI to suggestions that have no callers, and implements one item at a time with tests after each fix. No performative agreement — technical reasoning only.

### Updating documentation

```
Update the docs for the new TenantService
```

`project-setup:docs-writer` reads the source code, follows the project style guide, and produces or edits accurate Markdown. Verifies all links before finishing.

---

## Quick Reference

| What you want | What to say |
|---------------|------------|
| Map the codebase | `/project-setup:codebase-mapping` |
| Initialize CLAUDE.md | `/project-init` |
| Write a spec (Jira key optional) | `/intent-ops:spec-writer PROJ-1234` |
| Write spec from existing code | `/intent-ops:retro-spec PROJ-1234` |
| Write the implementation plan | `/intent-ops:plan-writer <spec-path>` |
| Execute with subagents (recommended) | `/intent-ops:task-runner` |
| Execute inline | `/intent-ops:plan-executor` |
| Generate test coverage | `Complete coverage for the changes` |
| Commit with Jira prefix | `/commit` |
| Ship / create PR | `/intent-ops:branch-shipper` |
| Address review comments | `/intent-ops:review-receiver` |
| Update documentation | `Update the docs for X` |

---

## Skill Interaction Map

```
Feature intent (plain description — or an optional Jira ticket)
    └── spec-writer ──────────────────────────────► SPEC.md
    │       └── (existing spec detected → revise/rewrite/view)
    │       └── (code already exists → retro-spec)
    │
    existing code
    └── retro-spec ───────────────────────────────► SPEC.md + alignment gaps
    │
    SPEC.md
    └── plan-writer ──────────────────────────────► PLAN.md
            └── (existing plan detected → revise/rewrite/view)
            └── task-runner (or plan-executor)
                    ├── worktree-setup      (isolation)
                    ├── tdd-guide           (red → green → refactor, per task)
                    ├── coding-guidelines   (DoD checklist)
                    ├── cognitive-driven-development  (ICP ≤ 7)
                    ├── coupling-analysis   (dependency balance)
                    ├── code-reviewer       (spec + quality gates)
                    └── branch-shipper ───► PR / merge
                            └── review-receiver  (feedback loop)
```
