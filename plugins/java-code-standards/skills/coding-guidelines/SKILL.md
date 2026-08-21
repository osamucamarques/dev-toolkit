---
name: coding-guidelines
description: 'Mandatory DoD checklist for every code change. Use for any feature, bug fix, refactor, or modification. Coordinates the Java trio: cognitive-driven-development (ICP <= 7), coupling-analysis, and coverage-driven-test-generation. Enforces simplicity-first and surgical-change rules.'
license: CC-BY-4.0
derived_from: 'tech-leads-club/agent-skills — (development)/coding-guidelines'
source_url: 'https://github.com/tech-leads-club/agent-skills/blob/main/packages/skills-catalog/skills/%28development%29/coding-guidelines/SKILL.md'
metadata:
  author: Samuel Marques
  version: '1.1.0'
  upstream_author: ale
  upstream_source: 'Karpathy Guidelines'
---

# Coding Guidelines

> **Attribution.** Derived from [`coding-guidelines`](https://github.com/tech-leads-club/agent-skills/blob/main/packages/skills-catalog/skills/%28development%29/coding-guidelines/SKILL.md) by **ale**, in the [Tech Leads Club agent-skills](https://github.com/tech-leads-club/agent-skills) catalog, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The upstream skill credits *Karpathy Guidelines* as its own source.
> **Changes made:** added §5 Definition of Done, the `code-standard.md` trio note, the worked Examples section, and a Java-oriented description.

Behavioral guidelines to reduce common LLM coding mistakes. These principles bias toward caution over speed — for trivial tasks, use judgment.

> This skill is part of the **code-standard.md** trio. When writing or changing Java code, always combine it with `cognitive-driven-development` and `coupling-analysis`. After writing, always run `coverage-driven-test-generation`.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- Disagree honestly. If the user's approach seems wrong, say so — don't be sycophantic.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

**The test:** Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Definition of Done (code-standard.md)

Before declaring work complete, verify:

- All modified/created classes have **≤ 7 ICP** (use `cognitive-driven-development` to measure)
- Coupling between new/changed modules is acceptable (use `coupling-analysis` to verify)
- Tests written and passing (use `coverage-driven-test-generation` after writing code)
- No regression gaps — existing tests still pass
- If a new feature was added: TC documented in `testing.md` with objective, steps, and acceptance criteria

---

## Examples

### Example 1: Adding a new feature

User says: "Add retry logic to the payment client."
Actions: State assumptions (idempotency, retry count), write a failing test for the retry scenario, watch it fail, then implement it — scoped to that scenario and nothing more. Adjacent error handling left untouched.
Result: Only retry logic added. No surrounding code modified.

### Example 2: Bug fix

User says: "The order total sometimes shows as negative."
Actions: Write a test that reproduces the negative total, fix only the root cause. Do not refactor the surrounding calculation method.
Result: One targeted fix, one new failing→passing test, no unrelated changes.
