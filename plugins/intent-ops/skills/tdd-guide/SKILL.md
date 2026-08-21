---
name: tdd-guide
description: 'Verification-driven implementation workflow — no behavior ships without a test that was observed failing for the right reason. Use whenever implementation begins: adding a feature, fixing a bug, or changing behavior. Provides tiered test-first rules, the red-green cycle with hard gates, and a verification checklist. Covers Java, Python, Node.js, and Go.'
license: MIT
disable-model-invocation: true
metadata:
  author: Samuel Marques
  version: 2.0.0
---

# TDD Guide Skill

Every behavior ships with a test that was **watched to fail for the right reason** before the
code that makes it pass existed. That is the non-negotiable part. How large a step you take
between one red test and the next is a judgement call, and this skill tells you how to make it.

**Core principle:** if you did not watch the test fail, you do not know that it tests anything.
A test written against code that already works proves only that the code compiles.

---

## HARD-GATE

```
⛔ NO COMMIT WITHOUT AN OBSERVED RED
Every behavior in the commit must have a test that was run and seen to fail — for the
right reason — before the code satisfying it existed.
No "I'll add the test after." No test that has only ever been green.
```

The gate is on the **commit**, not on the keystroke. If you wrote a few lines of production
code while thinking, you do not have to delete them — but you must delete or set aside what
you wrote, write the test, watch it fail, and only then bring the implementation back. If the
test cannot be made to fail against the code you already wrote, the test is worthless: fix the
test, not the gate.

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

## Test-First Tiers

Not every line of code carries the same risk, and applying the tightest cycle everywhere buys
nothing while costing design attention. Pick the tier per behavior, and state which tier you
chose when you report.

| Tier | Applies to | Cycle |
|------|-----------|-------|
| **1 — Strict test-first** | Domain rules and invariants, validation, calculations, state transitions, bug fixes, published contract behavior, anything with a branch or an edge case | One behavior at a time: RED → verify RED → implement → verify GREEN. No batching. |
| **2 — Design pass, then test-first** | A new component or collaboration whose shape is not yet decided — several classes, a new boundary, a new contract | First decide the design (Phase 0.5): types, contract, dependency direction, invariant owner. Write no production body. Then Tier 1 per behavior against that design. |
| **3 — Test required, order flexible** | Wiring, dependency-injection config, pure delegation with no logic, DTO mapping with no rules | A test must exist and be seen to fail at least once against the missing wiring. It may cover several elements at once. |

**When in doubt, treat it as Tier 1.** Tier 3 is for code where there is literally no decision
to get wrong; if you are arguing that something belongs in Tier 3, it probably does not.

---

## Phases

### Phase 0 — Pre-Work Gate

Before writing any code, confirm:

1. Is there a failing test for the behavior you are about to implement? If yes, skip to Phase 2.
2. If not — decide the tier above, then continue.

If you find existing production code with no test covering it: write a characterization test
that captures current behavior before making any changes.

---

### Phase 0.5 — Design Pass (Tier 2 only)

Skip this phase for Tier 1 and Tier 3 work. For Tier 2, decide and write down — in the task
report, not in code — before the first test:

- The **types and their responsibilities**: which class owns which invariant.
- The **contract**: public signatures, what is published, what stays internal.
- The **dependency direction**: what may depend on what, and which existing architectural rule
  this respects.
- The **failure and transaction boundary**: where errors surface, what is atomic.

Interfaces, signatures, and record declarations may be written now — **method bodies may not**.
The design pass exists so that the red-green cycles that follow are filling in a shape you chose
deliberately, instead of accumulating into a shape nobody chose.

If the design pass reveals a decision the plan or spec did not make, surface it before
implementing. Do not resolve an architectural question inside a green-bar cycle.

---

### Phase 1 — RED: Write the Failing Test

**Before writing the test:** consult the Acceptance Criteria in the spec for the current task. A well-written AC maps directly to a test — a binary, verifiable AC gives you both the test name and the primary assertion.

Example: AC "The system blocks confirmation when any restriction is violated" → `shouldBlockConfirmationWhenRestrictionIsViolated()`.

If no spec AC exists for this behavior, that is a gap the spec's refinement should have closed — not a decision to make silently. Define the expected behavior explicitly, note it as an open gap in your report back, and proceed; do not let an unrecorded assumption stand in for the spec.

Write one test that specifies the behavior you are about to implement.

**A good test:**
- Has a name that describes the behavior: `shouldRejectDuplicateTenant()`
- Tests one thing — if the name contains "and", split it into two tests
- Uses real code, not mocks, unless the dependency is genuinely external or slow
- Expresses the desired API from the caller's perspective
- Would still fail if the implementation were replaced by `return null` or an empty body

Load `references/testing-anti-patterns.md` when writing or modifying test infrastructure.

---

### Phase 2 — Verify RED

**Mandatory. Never skip.** This is the phase the hard-gate protects.

Run the test and confirm it fails for the right reason:

```bash
./gradlew test --tests "com.example.ClassName.methodName"   # Java
pytest tests/path/test_file.py::test_name -v                # Python
npm test -- --testNamePattern="test name"                    # Node.js
go test -run TestName ./...                                  # Go
```

Confirm:
- The test fails (not errors out due to a syntax mistake)
- The failure message matches what you expect (e.g., "method not found" or a wrong-value
  assertion, not a null pointer from broken setup)
- The test fails because the behavior is missing, not because of a typo or import error

**If the test passes immediately:** you are testing existing behavior, or asserting on a mock,
or the assertion is vacuous. Fix the test — this is the single most common way a test suite
becomes decorative.
**If the test errors:** fix the error and re-run until it fails correctly.

---

### Phase 3 — GREEN: Implement

Write the implementation the design calls for — correct, complete for the behavior under test,
and no more.

- **In scope:** the behavior the test specifies, done properly the first time, following the
  design from Phase 0.5 and the patterns already established in the codebase.
- **Out of scope:** parameters, options, configuration, abstraction layers, or error handling
  for scenarios no test and no requirement asked for. That is scope creep, and YAGNI applies.

Do not write a deliberately naive implementation you already know you will replace. Writing
`return true` to get a green bar, then rewriting it two minutes later, adds a cycle and buys
nothing when you already know the correct shape. Write the correct implementation of *this*
behavior — the discipline lives in the boundaries of the behavior, not in the crudeness of
the code.

Do not refactor unrelated code in the same commit.

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

- Remove duplication that has actually appeared in two or more places
- Improve naming so code reads clearly without comments
- Extract helpers where a pattern repeats
- Do not add new behavior during refactor

Keep all tests green throughout. If a refactor breaks a test: revert the refactor,
not the test.

**A refactor is not a redesign.** If green-bar work reveals that the boundary or the ownership
of an invariant is wrong, that is a design change: stop, say so, and get it decided — do not
reshape the architecture silently inside a refactor step.

---

### Phase 6 — Verification Checklist

Before marking a task complete:

- [ ] Every behavior in this change has a test that was observed failing first
- [ ] Each test failed for the expected reason (behavior missing, not typo or broken setup)
- [ ] Each test would still fail against an empty implementation
- [ ] The chosen tier is stated for each behavior, and Tier 2 work had a design pass first
- [ ] No unrequested parameters, options, or abstractions were added
- [ ] All tests pass with no warnings
- [ ] Tests verify real behavior, not mock behavior
- [ ] Edge cases and error paths are covered
- [ ] Any design decision the plan or spec did not make is reported, not buried

Cannot check all boxes? The work is not done. Fix what is missing before reporting.

---

## Key Principles

- **Observed red or it does not count.** A test that has only ever been green proves nothing.
- **Scope the behavior, not the crudeness.** Minimal means "no unrequested scope", not
  "deliberately wrong code you will rewrite".
- **Design before the cycle, not inside it.** Tier 2 work decides its shape first.
- **One behavior per test.** "and" in the test name means split it.
- **Mocks isolate, they do not replace.** Test real behavior; mock only external/slow dependencies.
- **Refactor only on green.** Never change design while tests are failing.
- **Escalate design questions.** A green bar is not authority to decide architecture.

---

## Common Rationalizations — All Wrong

| Excuse | Why it fails |
|--------|-------------|
| "It's too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll write tests after" | Tests-after get shaped by the implementation and pass on the first run. They prove nothing. |
| "I already manually tested it" | Ad-hoc is not systematic. Cannot re-run on change. |
| "The test passes already, close enough" | Then it does not test your change. Break it deliberately and see. |
| "I'll figure out the design as the tests accumulate" | That is how a shape nobody chose gets built. Tier 2 exists for this. |
| "This needs a config flag / extra param for later" | No test asks for it. YAGNI. |
| "TDD is dogmatic — I'm being pragmatic" | The observed red is the pragmatic part; it is the only cheap proof the test works. |

---

## Examples

### Example 1: Tier 1 — single domain rule

Task: "Add `rejectDuplicateTenant()` validation to `TenantService`."
Actions: Phase 0 (Tier 1 — one domain rule, existing class) → Phase 1 (write `shouldRejectDuplicateTenantRegistration()`) → Phase 2 (verify FAIL: `TenantService` has no such method) → Phase 3 (implement the validation properly) → Phase 4 (verify PASS, all other tests green) → Phase 5 (extract the duplicate-check if it now repeats).

### Example 2: Tier 1 — bug fix

Bug: Empty `tenantId` accepted silently.
Actions: Phase 1 (write `shouldRejectEmptyTenantId()`) → Phase 2 (verify FAIL, reproducing the bug) → Phase 3 (add blank check) → Phase 4 (verify PASS) → done.

### Example 3: Tier 2 — new collaboration

Task: "Introduce `ConfirmationPolicy` to arbitrate restrictions before confirmation."
Actions: Phase 0 (Tier 2 — new boundary, more than one valid shape) → Phase 0.5 (decide: `ConfirmationPolicy` owns the restriction invariant, `ConfirmationService` depends on it and not the reverse, violations surface as a domain exception; write the interface, no bodies; report the decision) → then Tier 1 per rule: RED → verify RED → implement → verify GREEN, one restriction at a time → Phase 5.

### Example 4: Tier 3 — wiring

Task: "Register `ConfirmationPolicy` in the Spring configuration."
Actions: one context-load test asserting the bean resolves, run against the missing registration to see it fail, then add the registration. No per-line cycle.
