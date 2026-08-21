---
name: task-runner
description: 'Execute an approved PLAN.md using fresh subagents per task with two-stage review. Use when the user has an approved plan — "execute the plan", "run with subagents". Prefer over intent-ops:plan-executor when subagents are available. Not for spec writing, plan writing, or when subagents are unavailable.'
license: MIT
disable-model-invocation: true
metadata:
  author: Samuel Marques
  version: 1.1.0
---

# Task Runner Skill

Execute an approved PLAN.md by dispatching a fresh subagent per task, enforcing two-stage
review (spec compliance first, code quality second) before advancing — producing high quality
through per-task context isolation and rigorous review gates.

---

## HARD-GATE

```
⛔ BRANCH PROTECTION
Never start implementation on main or master without explicit user consent.
Always confirm workspace isolation (see Phase 1) before any implementer is dispatched.
Never skip a review stage. Spec compliance must pass before code quality review begins.
Never dispatch multiple implementer subagents in parallel — git conflicts will corrupt the branch.
```

---

## Activation

**Use this skill** when the user has an approved PLAN.md and wants subagent-driven execution:

| Signal phrase | Example |
|---------------|---------|
| Subagent-driven preference | "run with subagents", "use task-runner", "subagent-driven" |
| Post-plan-writer handoff | automatically offered as the recommended execution option |
| Default execution intent | "execute the plan", "implement this plan" |

**Do not activate** when: there is no approved plan, the user explicitly wants inline
execution (use `intent-ops:plan-executor`), or subagents are unavailable.

---

## Phases

### Phase 0 — Plan Harvest

1. Read the PLAN.md file **once**. Extract all tasks with their full text and context.
   **Never make a subagent read the plan file** — the controller provides full task text.
2. Note the Jira context passed by `plan-writer` (if present):
   - **Story key** — e.g. `PROJ-1234` (used as the feature branch name: `feature/PROJ-1234`)
   - **Task ID mapping** — e.g. `Task 1 → PROJ-1235`, `Task 2 → PROJ-1236`
   If no Jira context was passed, commits will use conventional format without a subtask prefix.
3. Note the architectural context: goal, tech stack, file structure, cross-task dependencies.
4. Create a task list with all tasks in order (pending / in-progress / completed).
5. Scan the task list for already-completed checkboxes (`[x]`). If any are found, surface them before proceeding:

   > "Tasks [N, M, …] are already marked complete in the plan. Options:
   > 1. **Skip** — start from the first incomplete task.
   > 2. **Re-verify** — re-run spec compliance and code quality review on the completed tasks before advancing.
   > 3. **Rerun** — execute the completed tasks from scratch."

   Wait for the user's answer. Default to **Skip** if the user does not respond within the conversation turn.

6. Confirm the remaining task count with the user before dispatching the first implementer.

---

### Phase 1 — Workspace Isolation

`intent-ops:worktree-setup` has model-invocation disabled — it must be run by the user, not
called by this skill. Stop and suggest it:

> "This task needs an isolated workspace before any implementer is dispatched. Run
> `/intent-ops:worktree-setup` with feature name `<name from plan header>`, then let me know
> when it's done and I'll continue."

Wait for the user to confirm the workspace is isolated (or to report that the session is
already in one) before proceeding to Phase 2. Do not dispatch an implementer in the meantime.

---

### Phase 2 — Task Loop

Execute tasks **sequentially** — one at a time, in plan order.

For each task:

#### Step 2.1 — Dispatch Implementer

Capture the current HEAD before any work begins — this becomes `BASE_SHA` for the code quality review:
```bash
BASE_SHA=$(git rev-parse HEAD)
```

Load `references/implementer-prompt.md`. Substitute:
- `[FULL TEXT of task]` — the complete task text extracted in Phase 0 (never a file path)
- `[Context]` — architectural context: where this task fits, what precedes it, file structure
- `[JIRA-SUBTASK-KEY]` — the subtask key for this task from the mapping (e.g. `PROJ-1235`), or omit if no mapping

Dispatch a general-purpose subagent. Mark the task as **in progress**.

#### Step 2.2 — Handle Implementer Status

| Status | Action |
|--------|--------|
| `DONE` | Proceed to Step 2.3 |
| `DONE_WITH_CONCERNS` | Read the concerns. If correctness or scope risk: address before review. If observational: note and proceed. |
| `NEEDS_CONTEXT` | Provide missing context and re-dispatch the same task. |
| `BLOCKED` | Assess: context problem → provide context and re-dispatch. Task too large → break it down. Plan wrong → escalate to the user. |

Never ignore BLOCKED or NEEDS_CONTEXT. Never retry without change.

#### Step 2.3 — Spec Compliance Review

Load `references/spec-compliance-reviewer-prompt.md`. Substitute:
- `[FULL TEXT of task requirements]` — the task spec from Phase 0
- `[Implementer's report]` — what the implementer reported

Dispatch a general-purpose subagent.

- ✅ **Spec compliant** → proceed to Step 2.4
- ❌ **Issues found** → for each issue, decide whether it's a defect (fix it) or an intentional
  deviation (the implementer made a reasonable call the spec didn't decide, and it should
  stand). Defects: re-dispatch the implementer with specific fix instructions, then re-dispatch
  the spec reviewer. Repeat until compliant. Deviations you accept: do not re-dispatch for
  these — instead record them directly (Step 2.3.1) and proceed.

**Do not advance to code quality review while spec compliance has open (unrecorded) issues.**

#### Step 2.3.1 — Record Accepted Deviations

If Step 2.3 surfaced a deviation you're accepting rather than fixing, edit the task's SPEC.md
directly — append an entry to its `## 12. Decisions and Deviations` section (this is a normal
file edit; it does not require invoking `spec-writer` or any other skill):

```markdown
### [Deviation name]

**Decision:** what was done differently from what the spec described.
**Reason:** why this decision was made.
**Status:** COMPLETE
**Risk:** the exposure while this deviation exists.
```

Never leave an accepted deviation unrecorded — the next spec compliance review (or a future
reader of the spec) has no way to know it was a deliberate choice rather than a missed
requirement.

#### Step 2.4 — Code Quality Review

Capture the current HEAD — use `BASE_SHA` captured in Step 2.1:
```bash
HEAD_SHA=$(git rev-parse HEAD)
```

Load `references/code-quality-reviewer-prompt.md`. Substitute the SHAs and task summary.
Dispatch a general-purpose subagent.

- ✅ **Approved** → mark task **completed**, proceed to next task
- ❌ **Issues found** → re-dispatch the implementer with fix instructions, re-run spec
  compliance (Step 2.3), then code quality. Repeat until approved.

---

### Phase 3 — Final Review

After all tasks are complete, dispatch a final code review across the full implementation:

```bash
BASE_SHA=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master)
HEAD_SHA=$(git rev-parse HEAD)
```

Load `references/code-quality-reviewer-prompt.md`. Use the full implementation as scope.
Fix any Critical or Important issues before proceeding.

---

### Phase 4 — Branch Completion

`intent-ops:branch-shipper` has model-invocation disabled — suggest it, do not call it:

> "All tasks are reviewed and approved. Run `/intent-ops:branch-shipper` to run the full test
> suite and choose how to integrate the branch (merge / PR / keep / discard)."

Do not push, merge, or take any git action yourself — that is `branch-shipper`'s job once the
user runs it.

---

## Prompt Templates

All in `references/`:
- `implementer-prompt.md` — task instructions for the implementer subagent
- `spec-compliance-reviewer-prompt.md` — verify implementation matches spec
- `code-quality-reviewer-prompt.md` — verify implementation is well-built

---

## Key Principles

- **Fresh context per task.** Subagents receive only what they need — never the session history.
- **Controller reads, subagents implement.** Read the plan once; never delegate file reading.
- **Two-stage review is mandatory.** Spec compliance first, code quality second. No skipping.
- **Sequential tasks.** Never dispatch multiple implementers in parallel.
- **Stop when blocked.** Never force through BLOCKED status without change.
- **Isolation first.** Worktree before any code.
- **Observed red always.** Implementer subagents carry the hard-gate inline in
  `references/implementer-prompt.md` — every behavior gets a test that was run and seen to fail
  before the code satisfying it existed. The task's test-first tier sets the step size, never
  whether the red happens.
  (`intent-ops:tdd-guide` has model-invocation disabled, so subagents can't load it themselves —
  the gate is embedded in the prompt template instead.)

---

## Examples

### Example 1: Standard subagent execution

User says: "Execute the plan with task-runner."
Actions: Phase 0 (extract all tasks) → Phase 1 (suggest `/intent-ops:worktree-setup`, wait for the user) → Phase 2 (per task: implementer → spec compliance → code quality, loop until both pass) → Phase 3 (final review) → Phase 4 (suggest `/intent-ops:branch-shipper`).
Result: All tasks reviewed and approved, branch ready.

### Example 2: Blocked task

Implementer reports BLOCKED — missing dependency.
Action: Assess. Provide the missing context (file path, interface contract). Re-dispatch same task. If the plan itself is wrong, escalate to the user before retrying.

### Example 3: Spec compliance failure

Spec reviewer finds a missing requirement after Task 3.
Action: Re-dispatch the Task 3 implementer with specific fix instructions referencing the gap. Re-run spec reviewer. Do not advance to code quality until compliant.
