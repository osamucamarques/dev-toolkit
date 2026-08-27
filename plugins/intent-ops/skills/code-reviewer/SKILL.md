---
name: code-reviewer
description: 'Dispatch a code reviewer subagent to verify completed work. Use after implementing a task or feature, or before merging — "review this task", "request code review", "review before merge". Not when nothing has been implemented yet.'
license: MIT
disable-model-invocation: true
metadata:
  author: Samuel Marques
  version: 1.2.0
---

# Code Reviewer Skill

Dispatch a focused code reviewer subagent with precisely crafted context — never the session
history — to verify implementation quality, plan alignment, and production readiness before
issues cascade into more work.

**Core principle:** Review early, review often. The reviewer sees the work product, not your
thought process.

---

## Activation

**Use this skill** when work is complete and needs verification:

| Signal phrase | Example |
|---------------|---------|
| Post-task review | "review this task", "review before I continue" |
| Pre-merge review | "review before merge", "check this before PR" |
| Ad-hoc | when stuck and a fresh perspective would help |

This skill has model-invocation disabled, so run it yourself with `/intent-ops:code-reviewer`
— nothing else in this plugin can invoke it for you. Note that `intent-ops:task-runner` does
*not* call this skill: it dispatches its own equivalent review subagent inline
(its own `task-runner/references/code-quality-reviewer-prompt.md`) after every task, so its
per-task review already
happens without you needing to run this separately. Use this skill for ad-hoc reviews outside
that loop — after completing a major feature, or before merging to main.

---

## Phases

### Phase 0 — Prepare Context

Collect the information the reviewer needs:

```bash
BASE_SHA=$(git rev-parse HEAD~1)   # or the commit before the task started
HEAD_SHA=$(git rev-parse HEAD)
```

Gather:
- **Description** — one sentence: what was built
- **Requirements** — task text from the plan, or a path to the relevant spec section
- **Base SHA** — the commit before this work started
- **Head SHA** — the current commit

For multi-task reviews (final review), set `BASE_SHA` to the branch point:
```bash
BASE_SHA=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master)
```

---

### Phase 1 — Dispatch Reviewer

Load `references/code-reviewer-prompt.md`. Substitute:
- `{DESCRIPTION}` — the one-sentence description from Phase 0
- `{PLAN_OR_REQUIREMENTS}` — task text or spec path
- `{BASE_SHA}` — starting commit
- `{HEAD_SHA}` — ending commit

Dispatch a general-purpose subagent. Wait for the full review.

---

### Phase 2 — Act on Feedback

Handle each issue by severity:

| Severity | Action |
|----------|--------|
| **Critical** | Fix immediately before proceeding to the next task |
| **Important** | Fix before merging. May proceed to next task if time-boxed iteration is needed |
| **Minor** | Note for later. Do not block on minor issues |
| **Advisory/Recommendations** | Evaluate against YAGNI. Only implement if clearly justified |

**If the reviewer is wrong:** Push back with technical reasoning. Reference specific code or
tests that demonstrate correctness. Involve the user if the disagreement is architectural.

**If the reviewer suggests unrequested features:** Apply YAGNI. Check if the suggested feature
is actually used anywhere. If not, decline with reasoning.

---

## Key Principles

- **Precise context, not session history.** The reviewer subagent gets exactly what it needs.
- **Severity is real.** Not everything is Critical. Trust the calibration in the reviewer prompt.
- **Acknowledge strengths.** Accurate praise builds trust for the rest of the feedback.
- **Pushback is valid.** Technical disagreement with clear reasoning is correct behavior.
- **Review early.** Catching issues per-task is cheaper than catching them at the end.

---

## Examples

### Example 1: Post-task review

After implementing Task 2 of the plan.
Actions: Phase 0 (get BASE_SHA before task, HEAD_SHA now) → Phase 1 (dispatch reviewer with task text) → Phase 2 (fix 1 Important issue found, proceed to Task 3).

### Example 2: Pre-merge final review

All tasks complete, before running `/intent-ops:branch-shipper`.
Actions: Phase 0 (BASE_SHA = branch point, HEAD_SHA = HEAD) → Phase 1 (dispatch reviewer with full plan) → Phase 2 (fix Critical issues, note Minors).
