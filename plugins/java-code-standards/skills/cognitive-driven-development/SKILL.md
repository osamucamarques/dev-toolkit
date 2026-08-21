---
name: cognitive-driven-development
description: 'Java ICP (Intrinsic Complexity Points) measurement and class-extraction tool. Use when measuring class complexity, a class hits ICP >= 8, deciding to split/keep a class, or coding-guidelines requires an ICP check. Provides scoring algorithm and Abstraction Gate. Use with coding-guidelines and coupling-analysis.'
license: MIT
metadata:
  author: Samuel Marques
  version: 1.0.0
---

# Cognitive-Driven Development (CDD)

Expert software architect applying CDD to control complexity and improve code legibility in Java codebases.

> This skill is part of the **code-standard.md** trio. Use together with `coding-guidelines` and `coupling-analysis` when writing or reviewing code. After refactoring, trigger `coverage-driven-test-generation` to ensure coverage is maintained.

## Core Principle

**Semantic cohesion > metric decomposition.**

ICP is a diagnostic tool — it flags classes that are hard to read and reason about. It is not an architectural objective. The goal is **architecture optimized for operability**, not architecture optimized for ICP.

A codebase with fewer, coherent classes that slightly exceed the ICP target is healthier than one fragmented into micro-abstractions that exist only to satisfy a number.

---

## Response Style

- Ultra concise
- Technical only
- No explanations unless asked
- Output = analysis + solution

---

## ICP Tolerance Tiers

| ICP | Status | Action |
|-----|--------|--------|
| ≤ 7 | ✅ Ideal | No action needed |
| 8–9 | ⚠️ Tolerated | Acceptable **only if** the Abstraction Gate (below) rejects decomposition. Must be noted in the analysis. |
| ≥ 10 | ❌ Hard block | Must refactor regardless. No exceptions. |

ICP 8 or 9 is not a failure — it is a conscious trade-off: less fragmentation and less orchestration noise in exchange for slightly higher measured complexity.

---

## Workflow

1. Measure ICP for all classes in scope
2. If any class ≥ 10 → refactor (hard block, no gate needed)
3. If any class is 8–9 → run the **Abstraction Gate** before deciding to refactor
4. If the gate approves decomposition → refactor (all resulting classes must also comply)
5. If the gate rejects decomposition → accept the ICP with a note; do not extract
6. Verify final ICP after any refactoring
7. Confirm coverage still passes (run `coverage-driven-test-generation` if tests were added)

---

## Abstraction Gate

Run this check **before every extraction**. If the proposed refactoring fails any question, reject it — do not extract.

**1. Real concept or refactoring artifact?**
Does the new class have a name that describes a genuine domain or infrastructure responsibility? A class that only exists because of ICP pressure is an artifact, not a concept.
- `DiscountApplicationService` → real responsibility ✅
- `OrderServicePart2`, `OrderServiceHelper`, `OrderServiceProcessor` → artifact ❌

**2. Would this class exist without ICP?**
If the honest answer is "no — I'm only creating it to lower the number", the extraction is ICP-driven. Reject it.

**3. Does the caller get simpler?**
After the extraction, is the calling class easier to read and reason about — or did we just push the same complexity into orchestration code that now coordinates multiple collaborators?
- Caller removes a responsibility it shouldn't own → simplification ✅
- Caller now sequences calls to the new class with no reduction in its own logic → orchestration noise ❌

**4. Does the total system have fewer concepts to hold in mind?**
Count the number of classes a developer needs to understand to trace the flow. If extraction increases that count without a proportional gain in clarity, reject it.

A refactoring that passes all four questions improves cohesion. One that fails any question satisfies a metric — not the codebase.

---

## ICP Metric

Each class accumulates one point per occurrence of:

### A. Contextual Coupling
- Dependency on any project-specific class

### B. Control Flow
- `if`, `else`, `switch`
- `for`, `while`
- `try`, `catch`, `finally`

### C. Function as Argument
- Lambdas or functional interfaces passed as parameters

---

## Anti-Pattern Constraints

### Complexity redistribution (always forbidden)
- Moving the same logic unchanged to another class
- Creating pass-through classes with identical control flow
- Splitting code without reducing total cognitive load

### ICP-driven micro-abstractions (forbidden when gate rejects)
- Classes whose sole purpose is to bring a parent class under the limit
- Orchestrator classes that replace one large class with three small ones plus coordination glue
- Helper/Util extractions that fracture a coherent responsibility into satellite fragments

Every extraction must:
- Reduce branching, coupling, or mental overhead in the caller
- Improve semantic clarity — the new class must own a responsibility that has a name in the domain or infrastructure layer
- Survive the Abstraction Gate

If the total system complexity (sum of ICPs across all resulting classes) does not improve, the refactor is invalid.

---

## Design Pattern Reference

When refactoring, prefer well-known structural solutions over ad-hoc abstractions. See [Gang of Four Design Patterns](gof-design-patterns.md) for intent, structure, and usage guidance on all 23 GoF patterns.

---

## Refactoring Strategies

1. **Extraction & Cohesion** — split responsibilities along real domain boundaries, move logic to domain objects that own it
2. **Polymorphism** — replace conditionals with interfaces or enums
3. **Deliberate tolerance** — when no extraction passes the gate, accept ICP 8–9 and document why decomposition would hurt operability more than the complexity costs
4. **Named transformations** — apply catalog-based techniques from `refactoring-patterns` (Extract Method, Move Method, Replace Conditional with Polymorphism) after the Abstraction Gate approves the decomposition

---

## Decision Principles

- Prefer polymorphism over maps or config-driven behavior
- A coherent ICP-9 class is better than three ICP-3 classes plus an ICP-4 orchestrator
- Operability first: can a developer unfamiliar with this code understand the flow without jumping across five files?

---

## Output Format

### 1. Initial Analysis
```
ClassName — N ICP
  Coupling:       N
  Branches:       N
  Function args:  N
```

### 2. Gate Result (for ICP 8–9 only)
```
Abstraction Gate: APPROVED / REJECTED
  Reason: [one line]
```

### 3. Refactored Code (if gate approved or ICP ≥ 10)
Full implementation including new classes.

### 4. Final Analysis
```
ClassName — N ICP  ✅ / ⚠️ tolerated / ❌
```
All classes must be ✅ or ⚠️ tolerated (with gate rejection noted) before the task is done.

---

## Examples

### Example 1: Hard block — must refactor

```
OrderService — 11 ICP ❌
  Coupling:       5  (OrderRepository, DiscountService, EmailService, AuditLog, InventoryService)
  Branches:       5  (if discount, if premium, try/catch, for each item, if inventory)
  Function args:  1  (lambda passed to stream)
```
Gate not needed — hard block. Refactor: extract `DiscountApplicationService` (owns discount logic, 3 ICP ✅) and `OrderFulfillmentService` (owns inventory + item loop, 4 ICP ✅). `OrderService` drops to 5 ICP ✅.

---

### Example 2: Tolerated — gate rejects decomposition

```
PaymentProcessor — 9 ICP ⚠️
  Coupling:       4  (PaymentGateway, FraudCheck, AuditLog, NotificationService)
  Branches:       4  (if fraud, if retry, try/catch, if notification)
  Function args:  1
```
Gate result: REJECTED — extracting retry logic would produce `PaymentRetryCoordinator` (artifact, not a domain concept) and force the caller to orchestrate two collaborators for what is currently one coherent flow. Accept ICP 9. Note: all four responsibilities are intrinsic to payment processing; no extraction improves semantic cohesion.

---

### Example 3: Class passes

```
UserService — 5 ICP ✅
  Coupling:       3
  Branches:       2
  Function args:  0
```
No action needed. Proceed.
