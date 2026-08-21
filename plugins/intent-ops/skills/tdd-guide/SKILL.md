---
name: tdd-guide
description: 'Mandatory TDD workflow — red-green-refactor cycle required before any production code. Use whenever implementation begins: adding a feature, fixing a bug, or changing behavior. Provides the 6-phase cycle with hard gates and verification checklist. Covers Java, Python, Node.js, and Go.'
license: MIT
disable-model-invocation: true
metadata:
  author: Samuel Marques
  version: 1.0.0
---

# TDD Guide Skill

Enforce the red-green-refactor cycle for every feature and bug fix: write the failing test
first, watch it fail, write the minimal code to pass, confirm it passes, then refactor.

**Core principle:** If you did not watch the test fail, you do not know if it tests the
right thing.

---

## HARD-GATE

```
⛔ NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
If you wrote production code before writing a test: delete it. Start over.
No exceptions. "Keep as reference" is not an exception — delete means delete.
```

---

## Activation

**Use this skill** for every feature, bug fix, or behavior change:

| Trigger | Example |
|---------|---------|
| New feature | any new class, method, endpoint, or behavior |
| Bug fix | reproduce the bug in a test before fixing |
| Refactoring | confirm tests stay green through each change |
| Subagent task | `intent-ops:task-runner` implementers follow this skill |

**Exceptions** (require explicit user approval):
- Throwaway prototypes that will be deleted
- Generated boilerplate code
- Pure configuration files with no testable behavior

---

## Phases

### Phase 0 — Pre-Work Gate

Before writing any code, confirm:

1. Is there a failing test for the behavior you are about to implement? If yes, skip to Phase 2.
2. If not — write the test first (Phase 1). Production code comes after.

If you find existing production code with no test covering it: write a characterization test
that captures current behavior before making any changes.

---

### Phase 1 — RED: Write the Failing Test

**Before writing the test:** consult the Acceptance Criteria in the spec for the current task. A well-written AC maps directly to a test — a binary, verifiable AC gives you both the test name and the primary assertion.

Example: AC "The system blocks confirmation when any restriction is violated" → `shouldBlockConfirmationWhenRestrictionIsViolated()`.

If no spec AC exists for this behavior, that is a gap the spec's refinement should have closed — not a decision to make silently. Define the expected behavior explicitly, note it as an open gap in your report back, and proceed; do not let an unrecorded assumption stand in for the spec.

Write one minimal test that specifies the behavior you are about to implement.

**A good test:**
- Has a name that describes the behavior: `shouldRejectDuplicateTenant()`
- Tests one thing — if the name contains "and", split it into two tests
- Uses real code, not mocks, unless the dependency is genuinely external or slow
- Expresses the desired API from the caller's perspective

**A bad test:**
- Tests mock behavior instead of real behavior
- Has a vague name like `testMethod()` or `test1()`
- Sets up more mock infrastructure than actual assertions

Load `references/testing-anti-patterns.md` when writing or modifying test infrastructure.

---

### Phase 2 — Verify RED

**Mandatory. Never skip.**

Run the test and confirm it fails for the right reason:

```bash
./gradlew test --tests "com.example.ClassName.methodName"   # Java
pytest tests/path/test_file.py::test_name -v                # Python
npm test -- --testNamePattern="test name"                    # Node.js
go test -run TestName ./...                                  # Go
```

Confirm:
- The test fails (not errors out due to a syntax mistake)
- The failure message matches what you expect (e.g., "method not found", not a null pointer)
- The test fails because the feature is missing, not because of a typo or import error

**If the test passes immediately:** You are testing existing behavior or a duplicate. Fix the test.
**If the test errors:** Fix the error and re-run until it fails correctly.

---

### Phase 3 — GREEN: Write Minimal Implementation

Write the simplest code that makes the test pass. Nothing more.

- Do not add parameters, options, or features not required by the test
- Do not refactor other code in the same commit
- Do not add error handling for scenarios the test does not cover

If you are tempted to build something "the right way" before the test demands it: stop.
Write the minimal code. YAGNI applies here strictly.

---

### Phase 4 — Verify GREEN

**Mandatory. Never skip.**

Run the test again and confirm:
- The target test passes
- All previously passing tests still pass
- No warnings or errors in the output

**If the target test fails:** Fix the implementation — not the test.
**If other tests break:** Fix the regression now, before continuing.

---

### Phase 5 — REFACTOR

Only after Phase 4 confirms green:

- Remove duplication introduced by the minimal implementation
- Improve naming so code reads clearly without comments
- Extract helpers if a pattern repeats across two or more places
- Do not add new behavior during refactor

Keep all tests green throughout. If a refactor breaks a test: revert the refactor,
not the test.

---

### Phase 6 — Verification Checklist

Before marking a task complete:

- [ ] Every new method or class has a test that was written first
- [ ] Each test was watched to fail before implementation
- [ ] Each test failed for the expected reason (feature missing, not typo)
- [ ] Minimal code was written to pass each test
- [ ] All tests pass with no warnings
- [ ] Tests verify real behavior, not mock behavior
- [ ] Edge cases and error paths are covered

Cannot check all boxes? TDD was skipped. Start over.

---

## Key Principles

- **Red before green.** A test that was never red proves nothing.
- **Minimal implementation.** Write only what the test demands.
- **One behavior per test.** "and" in the test name means split it.
- **Mocks isolate, they do not replace.** Test real behavior; mock only external/slow dependencies.
- **Refactor only on green.** Never change design while tests are failing.

---

## Common Rationalizations — All Wrong

| Excuse | Why it fails |
|--------|-------------|
| "It's too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll write tests after" | Tests-after pass immediately and prove nothing. |
| "I already manually tested it" | Ad-hoc is not systematic. Cannot re-run on change. |
| "Deleting X hours of work is wasteful" | Sunk cost. Unverified code is technical debt. |
| "Keep as reference, write tests around it" | You will adapt it. That is tests-after. Delete it. |
| "TDD is dogmatic — I'm being pragmatic" | TDD is faster than debugging. Tests-first is pragmatic. |

---

## Examples

### Example 1: New feature via TDD

Task: "Add `rejectDuplicateTenant()` validation to `TenantService`."
Actions: Phase 0 (no existing test) → Phase 1 (write `shouldRejectDuplicateTenantRegistration()`) → Phase 2 (verify FAIL: `TenantService` has no such method) → Phase 3 (add minimal `rejectDuplicateTenant()` method) → Phase 4 (verify PASS, all other tests green) → Phase 5 (extract duplicate-check logic if reused elsewhere).

### Example 2: Bug fix via TDD

Bug: Empty `tenantId` accepted silently.
Actions: Phase 1 (write `shouldRejectEmptyTenantId()`) → Phase 2 (verify FAIL) → Phase 3 (add blank check) → Phase 4 (verify PASS) → done.
