# Developer Workflow — Other Languages

End-to-end workflow for non-Java projects (Node.js, Python, Go, Rust, etc.) using the dev-toolkit plugin stack.

The structure is identical to the [Java workflow](./java.md). The main difference: `java-code-standards` is Java-specific (ICP measurement, JaCoCo, Mockito). For other languages, code quality is enforced through the `intent-ops` review gates and TDD discipline instead.

---

## Plugins Required

| Plugin | Purpose |
|--------|---------|
| [`project-setup`](../../plugins/project-setup/) | Codebase mapping, CLAUDE.md initialization, conventional commits |
| [`intent-ops`](../../plugins/intent-ops/) | Spec → Plan → Execute → Ship pipeline |

> **java-code-standards** is Java-only. Do not install it for non-Java projects.

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
/plugin install intent-ops@dev-toolkit
```

### Step 2: Initialize CLAUDE.md

```
/project-init
```

Creates (or syncs) `CLAUDE.md` with the Document Map and skill references. Restart the session after this completes.

### Step 3: Map the codebase

**Brownfield project** (existing codebase):

```
/project-setup:codebase-mapping
```

Produces 7 Markdown files in `docs/codebase/`: stack, architecture, conventions, structure, testing, integrations, and concerns. Claude reads these on-demand instead of re-exploring the whole project each session.

Supported stacks detected automatically:
- **Node.js / TypeScript** — `package.json`, `tsconfig.json`
- **Python** — `requirements.txt`, `pyproject.toml`, `Pipfile`
- **Go** — `go.mod`
- **Rust** — `Cargo.toml`

**Greenfield project** (starting from scratch):

Scaffold the project first, then run:

```
/project-setup:codebase-mapping
```

Run it again after any major structural change (new module, new service boundary).

### Step 4: Restart Claude Code

Restart the session once after setup. Rules and skills become active.

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
- If a Jira key was given, fetches the ticket, linked issues, and 90 days of org history; otherwise works from your description plus a codebase scan
- Bootstraps a ubiquitous language glossary (available sources: Jira content if any + conversation + codebase)
- Runs a Socratic DDD interview (one question at a time) until ≥ 95% confidence
- Maps bounded contexts and classifies relationships (U/D, ACL, OHS, Shared Kernel, etc.)
- Presents 2–3 design approaches before writing anything
- Produces a `SPEC.md` with EARS/GEARS requirements and acceptance criteria
- **Hard-gate:** no code until you explicitly approve the spec

> **Already wrote the code first?** Use `retro-spec` instead (the Jira key is optional here too):
> ```
> /intent-ops:retro-spec PROJ-1234
> ```
> `intent-ops:retro-spec` reads the implementation, validates intent, and produces a spec documenting what was built — Section 12 (Decisions and Deviations) records intentional deviations, Section 13 flags behavioral gaps.

### Step 2: Write the Plan

After spec approval, run `plan-writer` with the saved spec path:

```
/intent-ops:plan-writer docs/specs/PROJ-1234-tenant-self-signup.md
```

`intent-ops:plan-writer` takes over:
- **Phase 0.7:** reads the codebase before asking any questions — only asks the user what the code cannot answer
- Runs an architecture interview for anything the codebase didn't resolve
- Proposes the file structure (one responsibility per file)
- Produces a `PLAN.md` decomposed into behavior-sized test-first tasks with exact file paths, fixed contracts, and per-task acceptance criteria
- **Hard-gate:** no execution until you explicitly approve the plan

### Step 3: Execute

**Task Runner (recommended):**

```
/intent-ops:task-runner
```

For each task, `intent-ops:task-runner`:
1. Dispatches a fresh **implementer subagent** following `tdd-guide`:
   - Write the test → verify RED (right reason) → implement the behavior → verify GREEN → refactor, at the step size set by the task's test-first tier
   - Test commands auto-detected: `pytest`, `npm test`, `go test ./...`, `cargo test`
2. Runs **spec compliance review** — verifies the task output matches the spec
3. Runs **code quality review** — checks design, edge cases, and correctness
4. Re-dispatches with specific fix instructions if either review fails
5. Advances to the next task only when both reviews pass

**Inline Execution (no subagents):**

```
/intent-ops:plan-executor
```

`intent-ops:plan-executor` runs the same red-green cycle in the current session. Use when subagents are unavailable.

### Step 4: Commit

```
/commit
```

Prompts for a Jira issue ID and generates a conventional commit in the format `[PROJ-1234] feat(scope): description`. Commits automatically.

### Step 5: Ship the Branch

```
/intent-ops:branch-shipper
```

`intent-ops:branch-shipper`:
1. Runs the full test suite — stops if anything fails
2. Detects workspace state (normal repo, git worktree, detached HEAD)
3. Presents the integration menu:
   - **Merge locally** — pulls base branch, merges, runs tests, cleans up
   - **Push + create PR** — pushes branch, opens a GitHub PR
   - **Keep as-is** — preserves branch for later
   - **Discard** — deletes branch after typed confirmation

---

## Phase 2 — Ongoing Operations

### Addressing review feedback

```
/intent-ops:review-receiver
```

`intent-ops:review-receiver` reads all feedback before touching code, verifies each item against the codebase, applies YAGNI to suggestions with no callers, and implements one item at a time with tests after each fix.

### Updating documentation

```
Update the docs for the new UserService
```

`project-setup:docs-writer` reads the source code, follows the project style guide from `references/style-guide.md`, and produces or edits accurate Markdown. Verifies all links.

---

## Language-Specific Notes

### Node.js / TypeScript

- Test command: `npm test` or `npx jest`
- `tdd-guide` uses `npm test -- --testNamePattern="test name"` for single-test runs
- `branch-shipper` runs `npm test` before presenting integration options
- Prefer `jest` with `--coverage` for coverage visibility; no automated coverage skill for non-Java

### Python

- Test command: `pytest`
- `tdd-guide` uses `pytest tests/path/test_file.py::test_name -v`
- `branch-shipper` runs `pytest` before presenting integration options
- For coverage, run `pytest --cov` manually — no automated coverage skill for non-Java

### Go

- Test command: `go test ./...`
- `tdd-guide` uses `go test -run TestName ./...`
- `branch-shipper` runs `go test ./...` before presenting integration options
- Built-in coverage: `go test -cover ./...`

### Rust

- Test command: `cargo test`
- `tdd-guide` uses `cargo test test_name`
- `branch-shipper` runs `cargo test` before presenting integration options

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
            └── task-runner (or plan-executor)
                    ├── worktree-setup      (isolation)
                    ├── tdd-guide           (observed red → green → refactor, tiered)
                    ├── code-reviewer       (spec compliance + quality gates)
                    └── branch-shipper ───► PR / merge
                            └── review-receiver  (feedback loop)
```
