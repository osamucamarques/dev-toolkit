---
name: worktree-setup
description: 'Set up an isolated git workspace before feature implementation. Use when starting work that needs branch isolation — plan-executor and task-runner will prompt you to run this before dispatching any work. Not when already in an isolated worktree.'
license: MIT
disable-model-invocation: true
derived_from: 'obra/superpowers — using-git-worktrees'
source_url: 'https://github.com/obra/superpowers/blob/main/skills/using-git-worktrees/SKILL.md'
metadata:
  author: Samuel Marques
  version: 1.0.0
---

# Worktree Setup Skill

> **Attribution.** Derived from [`using-git-worktrees`](https://github.com/obra/superpowers/blob/main/skills/using-git-worktrees/SKILL.md) in [obra/superpowers](https://github.com/obra/superpowers) by **Jesse Vincent**, licensed under [MIT](https://github.com/obra/superpowers/blob/main/LICENSE).
> **Changes made:** Adds Jira-keyed branch naming; retains upstream's isolation-detection logic and directory-selection priority.


Ensure implementation work happens in an isolated workspace: detect existing isolation,
use native tools first, fall back to git worktrees, run project setup, and verify a clean
baseline before any code is written.

**Core principle:** Detect existing isolation first. Use native tools. Fall back to git.
Never fight the harness.

---

## Activation

**Use this skill** when starting feature work that needs branch isolation:

| Signal phrase | Example |
|---------------|---------|
| Explicit setup | "set up a worktree", "create an isolated workspace" |
| Suggested handoff | `intent-ops:plan-executor` or `intent-ops:task-runner` will suggest running this before execution — model-invocation is disabled, so run it via `/intent-ops:worktree-setup` |

**Do not activate** when already confirmed to be in an isolated worktree (Phase 0 will detect this).

---

## Phases

### Phase 0 — Detect Existing Isolation

Before creating anything, check current workspace state:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard** — `GIT_DIR != GIT_COMMON` is also true inside git submodules. Verify:
```bash
git rev-parse --show-superproject-working-tree 2>/dev/null
```
If this returns a path, you are inside a submodule — treat as a normal repo.

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** Already in an isolated worktree.
Skip to Phase 2. Report:
- Named branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD)."

**If `GIT_DIR == GIT_COMMON`:** Normal repo checkout. Ask for consent if not already given:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

If the user declines, skip to Phase 2 and work in place.

---

### Phase 1 — Create Workspace

Two mechanisms in priority order:

#### Step 1a — Native Platform Tools (preferred)

If your platform provides a native worktree tool (e.g., `EnterWorktree`, `/worktree`,
`--worktree` flag), use it. Native tools handle directory placement, branch creation, and
cleanup automatically.

If you have a native tool, use it and skip to Phase 2. Only proceed to Step 1b if no
native tool is available.

#### Step 1b — Git Worktree Fallback

Only when no native tool is available.

**Directory selection (priority order):**
1. Explicit user preference in instructions — use it, do not ask.
2. Existing project-local directory: check `.worktrees/` then `worktrees/` — use the first found.
3. Fallback: `.worktrees/` at the project root.

**Safety verification for project-local directories:**
```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```
If NOT ignored: add to `.gitignore`, commit the change, then proceed.

**Branch naming convention:**
Use `feature/<JIRA-ID>` when a Jira story key is available (e.g. `feature/PROJ-1234`).
Fall back to a kebab-case feature name if no Jira key was provided.

**Create the worktree:**
```bash
project=$(basename "$(git rev-parse --show-toplevel)")
git worktree add "<chosen-path>/feature/<JIRA-ID>" -b "feature/<JIRA-ID>"
cd "<chosen-path>/feature/<JIRA-ID>"
```

If `git worktree add` fails with a permission error: report the sandbox restriction and
continue working in the current directory.

---

### Phase 2 — Project Setup

Auto-detect and run the appropriate dependency setup:

```bash
if [ -f gradlew ]; then ./gradlew dependencies --quiet; fi   # Java / Spring Boot
if [ -f package.json ]; then npm install; fi                  # Node.js
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi  # Python
if [ -f pyproject.toml ]; then poetry install; fi
if [ -f go.mod ]; then go mod download; fi                    # Go
if [ -f Cargo.toml ]; then cargo build; fi                    # Rust
```

Skip silently if no matching file is found.

---

### Phase 3 — Baseline Verification

Run the full test suite to confirm the workspace starts clean:

```bash
./gradlew test        # Java / Spring Boot
npm test              # Node.js
pytest                # Python
go test ./...         # Go
cargo test            # Rust
```

**If tests fail:** Report each failure. Ask whether to investigate before proceeding.
Do not let implementation begin on a broken baseline without explicit user consent.

**If tests pass:** Report:
```
Worktree ready at <full-path>
Branch: <name>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

---

## Key Principles

- **Detect before creating.** Never create a nested worktree inside an existing one.
- **Native tools first.** Using `git worktree add` when a native tool exists creates phantom state.
- **Verify ignore before creating.** Project-local worktree directories must be git-ignored.
- **Clean baseline required.** A broken baseline makes it impossible to distinguish new bugs.

