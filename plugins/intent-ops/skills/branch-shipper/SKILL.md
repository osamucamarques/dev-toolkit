---
name: branch-shipper
description: 'Complete and integrate a development branch: runs tests, detects workspace state, presents merge/PR/keep/discard options, cleans worktrees. Use when implementation is done — "ship this", "create a PR", "I''m done", "merge to main". task-runner and plan-executor will prompt you to run this once all tasks are complete. Not while tasks are in progress.'
license: MIT
disable-model-invocation: true
derived_from: 'obra/superpowers — finishing-a-development-branch'
source_url: 'https://github.com/obra/superpowers/blob/main/skills/finishing-a-development-branch/SKILL.md'
metadata:
  author: Samuel Marques
  version: 1.0.0
---

# Branch Shipper Skill

> **Attribution.** Derived from [`finishing-a-development-branch`](https://github.com/obra/superpowers/blob/main/skills/finishing-a-development-branch/SKILL.md) in [obra/superpowers](https://github.com/obra/superpowers) by **Jesse Vincent**, licensed under [MIT](https://github.com/obra/superpowers/blob/main/LICENSE).
> **Changes made:** Adds the test gate, Jira-aware messaging, and merge/PR/discard option set; retains upstream's workspace detection and detached-HEAD option flow.


Safely complete a development branch: verify tests, detect workspace environment, present
clear integration options, execute the chosen path, and clean up the workspace.

---

## Activation

**Use this skill** when all implementation tasks are done and verified:

| Signal phrase | Example |
|---------------|---------|
| Explicit completion | "finish the branch", "ship this", "I'm done with the tasks" |
| Integration intent | "create a PR", "merge back to main", "push and create PR" |
| Suggested handoff | `intent-ops:task-runner` or `intent-ops:plan-executor` will suggest running this once all tasks are complete — model-invocation is disabled, so run it via `/intent-ops:branch-shipper` |

**Do not activate** while tasks are still in progress. Verify all tasks are complete before
invoking this skill.

---

## Phases

### Phase 0 — Test Verification

Run the full project test suite before presenting any options:

```bash
./gradlew test        # Java / Spring Boot
npm test              # Node.js
pytest                # Python
go test ./...         # Go
cargo test            # Rust
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show each failure with file and line]

Cannot proceed with merge or PR until tests pass.
```

Stop. Do not proceed to Phase 1. Fix failures and re-run.

**If tests pass:** Continue to Phase 1.

---

### Phase 1 — Environment Detection

Determine the workspace state before presenting options:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

| State | Options menu | Cleanup on finish |
|-------|-------------|-------------------|
| `GIT_DIR == GIT_COMMON` (normal repo) | 4 options | No worktree to clean |
| `GIT_DIR != GIT_COMMON`, named branch | 4 options | Provenance-based (Phase 4) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | 3 options (no local merge) | Harness-managed, do not touch |

Determine the base branch:
```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

---

### Phase 2 — Option Presentation

**Normal repo or named-branch worktree — present exactly these 4 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD — present exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

Present options concisely. Do not add explanation or recommendations unless asked.

---

### Phase 3 — Execute Choice

#### Option 1: Merge Locally

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git checkout <base-branch>
git pull
git merge <feature-branch>
```

Run the full test suite on the merged result. If tests pass, proceed to Phase 4 cleanup,
then delete the branch:
```bash
git branch -d <feature-branch>
```

If tests fail after merge: report failures. Do not clean up until the user decides.

#### Option 2: Push and Create PR

```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
- [2-3 bullets describing what changed]

## Test Plan
- [ ] [verification steps]
EOF
)"
```

**Do not clean up the worktree** — the user needs it alive for PR iteration.

#### Option 3: Keep As-Is

Report: "Keeping branch `<name>`. Worktree preserved at `<path>`."
Do not clean up.

#### Option 4: Discard

Confirm first:
```
This will permanently delete:
- Branch: <name>
- Commits: <list of commits>
- Worktree: <path>

Type 'discard' to confirm.
```

Wait for the exact string `discard`. If confirmed, proceed to Phase 4 cleanup, then:
```bash
git branch -D <feature-branch>
```

---

### Phase 4 — Workspace Cleanup

**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

- **`GIT_DIR == GIT_COMMON`** — normal repo, nothing to clean up. Done.
- **Worktree path is under `.worktrees/` or `worktrees/`** — we own it:
  ```bash
  MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
  cd "$MAIN_ROOT"
  git worktree remove "$WORKTREE_PATH"
  git worktree prune
  ```
- **Any other path** — the harness owns this workspace. Do NOT remove it. If your
  platform provides a workspace-exit tool, use it. Otherwise leave it in place.

Always `cd` to the main repo root before `git worktree remove`. Never run it from inside
the worktree being removed.

---

## Key Principles

- **Tests first, always.** Never present options while tests are failing.
- **Detect before acting.** Environment state determines the menu and cleanup path.
- **Provenance-based cleanup.** Only remove worktrees you created (`.worktrees/` path).
- **Confirmation before discard.** Require typed `discard` — no shortcuts.
- **Keep worktree for PRs.** Option 2 and 3 always preserve the workspace.


---

## Examples

### Example 1: Standard PR flow

All tasks complete, tests pass.
Actions: Phase 0 (tests pass) → Phase 1 (normal repo, main as base) → Phase 2 (present 4 options) → user picks 2 → Phase 3 (push + gh pr create) → no cleanup.
Result: PR created, worktree preserved for feedback.

### Example 2: Failing tests

Phase 0 — 3 tests fail.
Action: Report failures with file:line details. Stop. Do not present integration options.
