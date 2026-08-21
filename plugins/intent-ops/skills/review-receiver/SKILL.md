---
name: review-receiver
description: 'Handle incoming code review feedback with technical rigor. Use when receiving review feedback — "address this review", "fix these review comments", "respond to the reviewer". Requires verification before implementing and technical pushback when feedback is wrong.'
license: MIT
disable-model-invocation: true
metadata:
  author: Samuel Marques
  version: 1.0.0
---

# Review Receiver Skill

Receive and act on code review feedback with technical discipline: verify before implementing,
ask before assuming, push back when technically wrong, and implement one item at a time.

**Core principle:** External feedback is a suggestion to evaluate, not an order to follow.
Verify. Question. Then implement.

---

## HARD-GATE

```
⛔ NO PERFORMATIVE AGREEMENT
Never write: "You're absolutely right!", "Great point!", "Excellent feedback!",
"Thanks for catching that!", or any expression of gratitude.
Actions speak. State the fix or the pushback. Nothing else.
```

---

## Activation

**Use this skill** when receiving any code review feedback:

| Source | Example |
|--------|---------|
| Subagent reviewer (from `intent-ops:code-reviewer`) | spec compliance or quality issues returned |
| Human reviewer | PR comment, verbal feedback |
| GitHub PR inline comments | `gh api` review comment replies |

---

## Phases

### Phase 0 — Read

Read the complete feedback before reacting to any of it. Do not start implementing
while still reading. Items may be related — partial understanding leads to wrong fixes.

---

### Phase 1 — Understand

For each feedback item:
- Restate the technical requirement in your own words
- If anything is unclear: **stop**. Ask for clarification on unclear items before implementing anything

```
CORRECT: "I understand items 1, 2, 3. Need clarification on 4 and 5 before implementing."
WRONG:   "I'll fix 1, 2, 3 now and ask about 4, 5 later."
```

Items may be related. Partial implementation before full understanding produces wrong fixes.

---

### Phase 2 — Verify

Before implementing any item, verify it against the current codebase:

- Does the suggestion apply to this codebase? Check the actual code.
- Does it break existing functionality? Run the relevant tests.
- Is there a reason the current implementation is the way it is? Check git history or comments.
- Does the suggestion conflict with a prior architectural decision?
- Does the suggestion cross a Bounded Context boundary or change a contract (API/event) without versioning? If so, treat it as an architectural decision to escalate, not a fix to apply directly.

```
CORRECT: "Checking... [reads code] — this endpoint is not called anywhere. YAGNI applies."
WRONG:   "Let me implement that now." (before verification)
```

---

### Phase 3 — Evaluate

For each verified item, evaluate technical soundness for this specific codebase:

**From subagent reviewers** — apply the same rigor as external reviewers.

**From external reviewers:**
- Is it technically correct for this stack and version?
- Does it work on all environments this code runs on?
- Does the reviewer have full context (the whole file, prior decisions, constraints)?
- Does it conflict with a prior decision made by the user?

**YAGNI check for "proper" features:**
- Reviewer suggests implementing something "properly"?
- Check: is that feature actually used anywhere?
- If not used: decline with reasoning ("This endpoint has no callers. YAGNI applies.")
- If used: implement properly.

---

### Phase 4 — Respond

After verifying and evaluating, respond technically:

**When feedback is correct:** state what changed — `"Fixed. [Brief description]."` or `"Good catch — [specific issue]. Fixed in [location]."` or just show the diff. No praise (see HARD-GATE).

**When pushing back:**
- State technical reasoning, not defensiveness
- Reference specific code, tests, or constraints that support your position
- Ask specific questions if the reviewer may lack context
- Escalate to the user if the disagreement is architectural

**When correcting a prior pushback:** `"Verified — you were right. [Specific finding]. Implementing now."` No apology or defense.

---

### Phase 5 — Implement

Implement feedback items in this order:

1. Clarify anything still unclear (before touching code)
2. Blocking issues first (security, data loss, broken functionality)
3. Simple fixes (typos, imports, naming)
4. Complex fixes (refactoring, logic changes)

For each item:
- Implement one item at a time
- Run relevant tests after each fix
- Verify no regressions before moving to the next item

**For GitHub PR inline comments:** Reply in the thread, not as a top-level PR comment:
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies \
  -f body="[technical response or fix description]"
```

---

## Key Principles

- **Verify before implementing.** Never implement on trust alone.
- **One item at a time.** Batch without testing causes regression cascades.
- **Technical rigor over social comfort.** Pushback is correct when technically justified.
- **No performative agreement.** The HARD-GATE is unconditional.
- **Corrections are factual.** State the finding and move on. No apologies.

---

## Examples

### Example 1: Correct feedback

Reviewer flags missing null check on `tenantId`.
Actions: Phase 2 (verify — code confirms no null check) → Phase 4 ("Fixed in `TenantService:42`") → Phase 5 (add check, run tests, confirm green).

### Example 2: Wrong feedback

Reviewer suggests adding a `metrics()` endpoint "properly".
Actions: Phase 2 (grep — no callers anywhere) → Phase 4 ("No callers found. YAGNI applies — not implementing.").

### Example 3: Unclear feedback

Reviewer says "Fix items 1-5." You understand 1, 2, 4. Items 3 and 5 are ambiguous.
Action: "Understand 1, 2, 4. Need clarification on 3 and 5 before implementing."
