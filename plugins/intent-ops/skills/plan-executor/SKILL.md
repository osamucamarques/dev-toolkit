---
name: plan-executor
description: 'Execute an approved PLAN.md inline in the current session. Use when the user wants to run the plan without subagents — "execute the plan", "implement this plan". Prefer intent-ops:task-runner when subagents are available. Not for spec writing or plan writing.'
license: MIT
disable-model-invocation: true
metadata:
  author: Samuel Marques
  version: 2.0.0
---

# Plan Executor Skill

Execute an approved PLAN.md task-by-task in the current session, following each step exactly,
verifying outputs at every checkpoint, and handing off to `intent-ops:branch-shipper` when all
tasks are complete.

> **Prefer `intent-ops:task-runner` when subagents are available.** Fresh subagent per task with
> two-stage review produces significantly higher quality. Use this skill only when you must stay
> in a single session without spawning subagents.

---

## HARD-GATE

```
⛔ BRANCH PROTECTION
Never start implementation on main or master without explicit user consent.
Always confirm workspace isolation (see Phase 1) before writing any code.
```

---

## Activation

**Use this skill** when the user has an approved PLAN.md and wants inline execution:

| Signal phrase | Example |
|---------------|---------|
| Explicit inline execution | "execute the plan", "run the plan", "implement this plan" |
| Session preference | "do it here", "execute inline", "no subagents" |
| Continuation | "pick up from Task 3", "resume the plan" |

**Do not activate** when: there is no approved plan, the user wants a spec or plan written,
or the user wants subagent-driven execution (use `intent-ops:task-runner` instead).

---

## Phases

### Phase 0 — Plan Harvest

1. Locate the PLAN.md referenced by the user. If no path is given, search `docs/plans/`
   for the most recently modified plan and confirm it with the user.
2. Note the Jira context passed by `plan-writer` (if present):
   - **Story key** — e.g. `PROJ-1234` (used as the feature branch name: `feature/PROJ-1234`)
   - **Task ID mapping** — e.g. `Task 1 → PROJ-1235`, `Task 2 → PROJ-1236`
   If no Jira context was passed, commits will use conventional format without a subtask prefix.
3. Read the full plan: goal, architecture, tech stack, the Impact Analysis and Architecture
   Decisions tables, and all tasks with their steps, intents, tiers, and contracts.
4. Review critically — before starting, surface any concerns:
   - Missing dependencies or unclear steps?
   - References to types or methods not defined elsewhere in the plan?
   - Scope that seems misaligned with the linked spec?
   - Has the codebase changed since the plan's Impact Analysis section was written? If a contract, bounded context, or architectural rule listed there is no longer accurate, stop and re-confirm before executing — the impact analysis is a constraint to respect, not something the executor re-derives on its own.
4. If concerns exist, raise them and wait for resolution before proceeding.
5. If no concerns, create a task list from all plan tasks and confirm the count with the user.

---

### Phase 1 — Workspace Isolation

`intent-ops:worktree-setup` has model-invocation disabled — it must be run by the user, not
called by this skill. Stop and suggest it:

> "Before writing any code, this needs an isolated workspace. Run `/intent-ops:worktree-setup`
> with feature name `<name from plan header>`, then let me know when it's done."

Wait for the user to confirm the workspace is isolated (or that the session is already in
one) before proceeding to Phase 2.

---

### Phase 2 — Task Execution

Execute tasks sequentially, in the order defined by the plan.

For each task:

1. Mark the task as **in progress**.
2. Observed red, no exceptions (`intent-ops:tdd-guide` has model-invocation disabled, so its
   hard-gate is restated here rather than loaded): for each behavior, write the test, run it and
   confirm it fails **for the right reason** — behavior missing, not a typo or broken setup —
   then implement it correctly, then re-run. Nothing gets committed on a test that has only ever
   been green.
   - **Step size follows the task's test-first tier.** Tier 1 (domain rules, validation,
     calculations, state transitions, bug fixes): one behavior per cycle. Tier 2 (task introduces
     a new component or boundary): settle the contract first — interfaces and signatures, no
     method bodies — then Tier 1 per behavior. Tier 3 (wiring, pure delegation): one test that
     was seen to fail may cover several elements. If the task declares no tier, treat it as Tier 1.
   - **Implement correctly, not crudely.** "Minimal" means no parameters, options, abstractions,
     or error handling that no acceptance criterion asked for. It does not mean writing code you
     already know you will rewrite on the next cycle.
   - **A green bar is not authority to decide architecture.** If a cycle reveals that an
     invariant's owner, a dependency direction, or a contract shape is wrong, stop and ask — do
     not reshape it inside a refactor step.
3. Follow every step in the task exactly — do not skip steps, verifications, or commits.
4. Run each verification command listed and confirm the expected output matches.
5. Commit at the checkpoint specified by the plan. Use the following format:
   - **With Jira task mapping:** `JIRA-SUBTASK-KEY: <conventional message>` (e.g. `PROJ-1235: feat: add tenant validation`)
   - **Without Jira task mapping:** `<conventional message>` (e.g. `feat: add tenant validation`)
   - If the `/commit` skill is available in the session, invoke it — pass the subtask key as prefix context.
6. Mark the task as **completed** only after all steps and verifications pass.

If you made a reasonable call the plan/spec didn't decide (an intentional deviation, not a
defect), record it directly in the linked SPEC.md's `## 12. Decisions and Deviations` section
before marking the task complete — this is a normal file edit, no skill invocation needed:

```markdown
### [Deviation name]

**Decision:** what was done differently from what the spec described.
**Reason:** why this decision was made.
**Status:** COMPLETE
**Risk:** the exposure while this deviation exists.
```

**Stop and ask immediately when:**
- A dependency is missing or a test fails unexpectedly
- An instruction is unclear or contradicts a prior task
- A verification fails repeatedly despite a correct-looking implementation
- The plan has a gap requiring an architectural decision its Architecture Decisions table
  does not cover

Never guess, adapt, or force through blockers. Pause and ask.

---

### Phase 3 — Branch Completion

`intent-ops:branch-shipper` has model-invocation disabled — suggest it, do not call it:

> "All tasks are complete and verified. Run `/intent-ops:branch-shipper` to run the full test
> suite and choose how to integrate the branch (merge / PR / keep / discard)."

Do not push, merge, or take any git action yourself — that is `branch-shipper`'s job once the
user runs it.

---

## Key Principles

- **Plan is the source of truth.** Follow it exactly — do not improvise.
- **Observed red always.** Every behavior gets a test that was run and seen to fail before the
  code satisfying it existed — the hard-gate is restated in Phase 2 since
  `intent-ops:tdd-guide` has model-invocation disabled. The task's tier sets the step size,
  never whether the red happens.
- **Design decisions escalate.** Contracts and boundaries come from the plan's Architecture
  Decisions section. If one is missing or wrong, stop — do not decide it mid-cycle.
- **One task at a time.** Never skip ahead or execute tasks in parallel.
- **Stop when blocked.** Do not guess, adapt, or force through failures.
- **Isolation first.** Always verify worktree before writing any code.
- **No main/master without consent.** The HARD-GATE is unconditional.

---

## Examples

### Example 1: Standard execution

User says: "The plan is approved — execute it."
Actions: Phase 0 (load and review plan, confirm task count) → Phase 1 (suggest `/intent-ops:worktree-setup`, wait for the user) → Phase 2 (execute tasks in order, stop on any blocker) → Phase 3 (suggest `/intent-ops:branch-shipper`).
Result: All tasks complete, branch ready for merge or PR.

### Example 2: Blocker during execution

Verification command from Task 2 fails with unexpected error.
Action: Stop immediately. Report the failure and the task step that triggered it. Wait for user resolution before continuing.

### Example 3: Wrong trigger — do not activate

User says: "Write a plan for this spec."
Action: Do not activate. Use `intent-ops:plan-writer` instead.
