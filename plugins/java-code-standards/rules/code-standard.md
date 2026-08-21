---
paths:
  - "src/**/*.java"
---

# Coding Standards — Java

## Core Principles

- Prefer clarity over cleverness.
- Immutable by default; minimize shared mutable state.
- Fail fast with meaningful exceptions.
- Consistent naming and package structure.

---

## Readability

- Use names that reveal intent — no abbreviations or acronyms unless universally understood in the domain.
- Avoid deep nesting; extract nested logic into well-named methods.
- Comments explain *why*, not *what*. Never restate what the code already says.
- Always combine `coding-guidelines`, `cognitive-driven-development`, and `coupling-analysis` when writing or changing code.

---

## Code Style

- One public top-level type per file.
- Keep methods short and focused; extract helpers.
- Order members: constants, fields, constructors, public methods, protected, private.

---

## Code Smells to Avoid

- Long parameter lists → use DTO/builders.
- Deep nesting → early returns.
- Magic numbers → named constants.
- Static mutable state → prefer dependency injection.
- Silent catch blocks → log and act or rethrow

---

## Complexity

ICP (Intrinsic Complexity Points) is a diagnostic tool — **semantic cohesion takes priority over metric decomposition**. Never fragment a coherent responsibility just to satisfy a number.

| ICP | Status | Action |
|-----|--------|--------|
| ≤ 7 | ✅ Ideal | No action needed |
| 8–9 | ⚠️ Tolerated | Only if the Abstraction Gate rejects decomposition — must be noted |
| ≥ 10 | ❌ Hard block | Must refactor before merge |

Before any extraction, run the **Abstraction Gate** (defined in `cognitive-driven-development`). If the proposed class fails the gate, accept the higher ICP rather than creating an abstraction that exists only to satisfy the metric.

---

## Code Quality

- Use the most efficient algorithm and data structure for the task — justify non-obvious choices with a comment.
- Minimize I/O operations; batch or async where possible.
- After writing code, use `coverage-driven-test-generation` to create unit tests.

---

## Architecture

Prefer architectures that are **agent-friendly** — as easy for an AI agent to reason about as for a human. This means favoring the explicit over the implicit at every level.

- **Explicit boundaries** — each module, package, or bounded context has a clearly defined responsibility and a single documented entry point. No reaching across boundaries into another component's internals.
- **Stable contracts** — interactions happen through contracts (interfaces, APIs, event schemas) that change rarely and predictably. See *Contracts & Compatibility* below for the compatibility rules.
- **Typed interfaces** — model inputs and outputs with explicit types, not maps, generic `Object`, or loosely-structured strings. The type *is* the documentation.
- **Deterministic tests** — tests produce the same result on every run. No dependence on wall-clock time, random values, execution order, or external network state — inject those as controllable dependencies.
- **Avoid implicit behavior** spread across hidden conventions. Behavior that depends on naming magic, ambient global state, reflection, or "you just have to know" conventions is a liability: make it explicit in code or configuration that can be read at the call site.

---

## Contracts & Compatibility

### Idempotency

- State-mutating operations (writes, updates, deletes) **MUST be idempotent**: calling them N times with the same input produces the same result as calling them once.
- Design for at-least-once delivery — callers may retry on transient failure.
- Use natural idempotency patterns: upserts (save-or-update), conditional updates (`IF NOT EXISTS`, optimistic locking via `version`), deduplication keys on events.
- A method that is not idempotent by design MUST be named and documented to make that explicit.

### Backward Compatibility

- Public APIs (REST endpoints, service interfaces, event schemas) **MUST NOT** introduce breaking changes without a major version bump.
- **Breaking changes** (require a version bump): removing or renaming fields, changing types, tightening validation, altering behavior for existing valid inputs.
- **Additive changes** (safe without a version bump): new optional fields, new endpoints, relaxed validation, new enum values at the end.
- Deprecate before removing: annotate with `@Deprecated`, document the replacement, and keep the old contract functional for at least one release cycle.

---

## Testing Enforcement

### 1. New Feature → New Test Case

For every change:

- Add TC in `testing.md`
- Include:
    - Objective
    - Steps
    - Acceptance Criteria

- Update:
    - Coverage Matrix
    - Changelog

- Required scenarios (if critical):
    - Edge
    - Invalid
    - Default
    - Error

- Classification:
    - New / Regression / Validation / Edge / Integration / Security / Performance

---

### 2. Missing Coverage

Before finishing:

- Check `testing.md`
- Implement tests for:
    - All uncovered TCs
    - `[REGRESSION]`, `[NEW]`, critical flows

If not automatable:
- Document limitation
- Provide closest validation

---

### 3. Enforcement

PR is **invalid** if:

- No TC for new feature
- Impacted TCs not updated
- No regression tests
- Coverage Matrix inconsistent

---

### 4. Definition of Done

- All classes ≤ 7 ICP (8–9 tolerated with Abstraction Gate rejection noted; ≥ 10 blocks merge)
- TCs added/updated
- Tests implemented
- Coverage Matrix updated
- Test Changelog updated
- No regression gaps

---

### 5. No Silent Changes

If no new TC:

- Justify explicitly
- Reference existing TC covering behavior

---

## Discipline

Hard "don'ts" — violating any of these blocks merge:

- **Don't write vague commit messages.** Each commit states *what* changed and *why* in specific terms. No `fix`, `wip`, `update`, or `changes` — the message must let a reviewer understand the change without reading the diff.
- **Don't skip tests for new features.** Every new feature ships with its test cases (see *Testing Enforcement*). "I'll add tests later" is not acceptable — untested new behavior blocks the PR.
- **Don't deviate from established patterns without discussion.** Follow the conventions already present in the surrounding code and the codebase docs. If a different approach is genuinely better, raise it explicitly and get agreement *before* implementing — don't introduce a divergent pattern silently.

---

> **Remember:** Keep code intentional, typed, and observable. Optimize for maintainability over micro-optimizations unless proven necessary.
