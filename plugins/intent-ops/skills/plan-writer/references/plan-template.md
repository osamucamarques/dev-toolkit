# Plan Writer — Document Templates

> **Attribution.** The task scaffolding here — the TDD cycle step labels and the plan/task
> headings — follows [`writing-plans`](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md)
> in [obra/superpowers](https://github.com/obra/superpowers) by **Jesse Vincent**, licensed under
> [MIT](https://github.com/obra/superpowers/blob/main/LICENSE).
> **Changes made:** adds the Impact Analysis and Architecture Decisions tables, exact-path Files
> blocks, per-task Intent/Contract/AC framing with test-first tiers, Java examples, and the
> Jira-prefixed commit convention.

## Plan Document Header

Every PLAN.md must start with this header:

```markdown
# [Feature Name] Implementation Plan

> **Spec:** `docs/specs/<spec-filename>.md`
> **Approval required before execution** — see HARD-GATE.

**Goal:** [One sentence describing what this builds — copied from the spec]

**Architecture:** [2–3 sentences about the approach chosen in Phase 3.5]

**Tech Stack:** [Key technologies, frameworks, libraries]

## Impact Analysis

| Bounded Contexts affected | Contracts at risk | Architectural rules at risk | Deploy risks | Evidence |
|---------------------------|--------------------|------------------------------|---------------|----------|
| … | … | … | … | `path/File.java:120` |

## Architecture Decisions

| Decision | Choice | Why | Alternative rejected |
|----------|--------|-----|----------------------|
| Invariant ownership | … | … | … |
| Dependency direction | … | … | … |
| Contract shape / versioning | … | … | … |
| Failure & transaction boundary | … | … | … |

## Assumptions

Everything this plan takes as true but did not verify by reading the codebase. Each line is a
question the executing engineer must close before the task that depends on it — not a note to
skim past. An empty table is only correct when the pre-read genuinely closed every question.

| # | Assumption | Why it could not be verified | Affects | Resolve by |
|---|-----------|------------------------------|---------|-----------|
| A1 | … | … | Task 3 | Reading `…` / asking the API owner |

---
```

---

## Task Structure

Each task maps to one cohesive unit of behavior (one aggregate rule set, one endpoint, one
migration, one collaboration). A task is sized so that its **Intent** can be stated in one
sentence — not so that each keystroke is a checkbox.

Every task MUST follow this structure exactly:

````markdown
### Task N: [Component Name]

**Intent:** [One sentence — what behavior exists after this task that did not before.]

**Test-first tier:** 1 | 2 | 3 — see `intent-ops:tdd-guide`. State why if not Tier 1.

**Files:**
- Create: `exact/path/to/File.java`
- Modify: `exact/path/to/Existing.java:123-145`
- Test: `src/test/exact/path/to/FileTest.java`

**Contract** (required whenever this task defines or changes a signature, an event, or an
API shape — this is a design decision, so it is decided here, not during implementation):

```java
public interface ConfirmationPolicy {
    void assertConfirmable(ConfirmationRequest request);
}
```

**Acceptance criteria covered** (from the spec — each maps to at least one test):
- AC-3: The system blocks confirmation when any restriction is violated.
- AC-4: A violated restriction surfaces as `RestrictionViolationException`.

**Steps:**

- [ ] **Step 1: Design pass** — *Tier 2 only; omit for Tier 1 and Tier 3.*
      Confirm the Contract above against the codebase, write interfaces/signatures with no
      bodies, and report any decision the spec did not make.

- [ ] **Step 2: Write the failing test for the first AC**

Test name: `shouldBlockConfirmationWhenRestrictionIsViolated`
Assertion: calling `assertConfirmable` with a violated restriction throws
`RestrictionViolationException`.

- [ ] **Step 3: Run it and confirm it fails for the right reason**

Run: `./gradlew test --tests "com.example.ConfirmationPolicyTest.shouldBlockConfirmationWhenRestrictionIsViolated"`
Expected: FAIL — no such method / assertion not satisfied. **Not** a setup or import error.

- [ ] **Step 4: Implement the behavior**

Implement it correctly for this AC, following the Contract above and the patterns already in
the codebase. No parameters, options, or error handling that no AC asked for.

- [ ] **Step 5: Run the test and the suite — confirm green**

Run: `./gradlew test`
Expected: target test PASS, no regressions.

- [ ] **Step 6: Repeat Steps 2–5 for each remaining AC in this task**

- [ ] **Step 7: Commit**

```bash
git add src/main/java/com/example/File.java src/test/java/com/example/FileTest.java
git commit -m "JIRA-TASK-ID: feat: add specific behavior"
```

> Replace `JIRA-TASK-ID` with the Jira subtask key for this task (e.g. `PROJ-1235`),
> or omit the prefix if Jira subtasks were not created.
````

### When to include code in a task

| Include | Do not include |
|---------|----------------|
| Contracts: interfaces, public signatures, event payloads, DTO shapes, DB schema | Full method bodies the implementer can derive from the AC and the contract |
| Anything where more than one shape is valid and the plan is choosing | Test bodies — name the test and state the assertion instead |
| Non-obvious framework configuration | Boilerplate the codebase already has a pattern for |

The plan decides **what and where**. The implementer decides **how**, inside the contract the
plan fixed. A plan that pre-writes every body is an implementation transcribed into markdown:
it goes stale on first contact with the codebase, and it spends the planning phase — the only
phase dedicated to architecture — on typing code.
