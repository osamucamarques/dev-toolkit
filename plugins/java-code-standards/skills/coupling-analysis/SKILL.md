---
name: coupling-analysis
description: 'Java coupling measurement using strength x distance x volatility model. Classifies coupling (intrusive/functional/model/contract) and calculates MAINTENANCE_EFFORT. Use when a module has many dependencies, deciding to extract/merge modules, evaluating cross-service coupling, or coding-guidelines requires a coupling check. Use with coding-guidelines and cognitive-driven-development.'
license: CC-BY-4.0
derived_from: 'tech-leads-club/agent-skills — (architecture)/coupling-analysis'
source_url: 'https://github.com/tech-leads-club/agent-skills/blob/main/packages/skills-catalog/skills/%28architecture%29/coupling-analysis/SKILL.md'
metadata:
  author: Samuel Marques
  version: 1.0.0
---

# Coupling Analysis Skill

> **Attribution.** Derived from [`coupling-analysis`](https://github.com/tech-leads-club/agent-skills/blob/main/packages/skills-catalog/skills/%28architecture%29/coupling-analysis/SKILL.md) in the [Tech Leads Club agent-skills](https://github.com/tech-leads-club/agent-skills) catalog, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The three-dimensional coupling model itself is from *Balancing Coupling in Software Design* by Vlad Khononov.
> **Changes made:** narrowed to Java, added the `MAINTENANCE_EFFORT` calculation, the four-way coupling classification, and the `code-standard.md` trio integration.

You are an expert software architect specializing in coupling analysis. You analyze codebases following the **three-dimensional model** from _Balancing Coupling in Software Design_ (Vlad Khononov):

1. **Integration Strength** — _what_ is shared between components
2. **Distance** — _where_ the coupling physically lives
3. **Volatility** — _how often_ components change

The guiding balance formula:

```
BALANCE = (STRENGTH XOR DISTANCE) OR NOT VOLATILITY
```

A design is **balanced** when:

- Tightly coupled components are close together (high strength + low distance = cohesion)
- Distant components are loosely coupled (low strength + high distance = loose coupling)
- Stable components (low volatility) can tolerate stronger coupling

> This skill is part of the **code-standard.md** trio. Use together with `coding-guidelines` and `cognitive-driven-development` when writing or reviewing code. After resolving coupling issues, run `coverage-driven-test-generation` to ensure affected code is tested.

## When to Use

Apply this skill when the user:

- Asks to "analyze coupling", "refactor", "evaluate architecture", or "check dependencies"
- Wants to understand integration strength between modules or services
- Needs to identify problematic coupling or architectural smell
- Wants to know if a module should be extracted or merged
- Writes code

## Process

### PHASE 1 — Context Gathering

Collect before analyzing:

- Scope: full codebase or specific area? Abstraction level: methods / classes / modules / services?
- Git history available? (needed for Phase 4 volatility)
- Which parts are business core vs. generic infrastructure?

Classify subdomains — determines volatility in Phase 4:

| Type | Volatility | Indicators |
|------|-----------|------------|
| **Core subdomain** | High | Proprietary logic, competitive advantage |
| **Supporting subdomain** | Low | Simple CRUD, core support |
| **Generic subdomain** | Minimal | Auth, billing, email, logging, storage |

---

### PHASE 2 — Structural Mapping

For each module record: name, location (namespace/package/path), primary responsibility, and declared dependencies (imports, DI, HTTP calls). Build a directed dependency graph (A → B = "A depends on B").

**Distance** — use the encapsulation hierarchy:

| Common ancestor level  | Distance | Example |
| ---------------------- | -------- | ------- |
| Same method/function   | Minimal  | Two lines in same method |
| Same object/class      | Very low | Methods on same object |
| Same namespace/package | Low      | Classes in same package |
| Same library/module    | Medium   | Libs in same project |
| Different services     | High     | Distinct microservices |
| Different systems/orgs | Maximum  | External APIs, different teams |

If modules are maintained by different teams, increase distance by one level (Conway's Law).

---

### PHASE 3 — Integration Strength Analysis

For each dependency in the graph, classify the **Integration Strength** level (strongest to weakest):

#### INTRUSIVE COUPLING (Strongest — Avoid)

Downstream accesses implementation details of upstream that were _not designed for integration_.

**Code signals**: Reflection to access private members, service directly reading another service's database, dependency on internal file/config structure.

**Effect**: Any internal change to upstream breaks downstream.

---

#### FUNCTIONAL COUPLING (Second strongest)

Modules implement interrelated functionalities — shared business logic, interdependent rules, or coupled workflows.

**Three degrees**:
- **Sequential (Temporal)** — modules must execute in specific order
- **Transactional** — operations must succeed or fail together
- **Symmetric (strongest)** — same business logic duplicated in multiple modules

**General signals**: Comments like "remember to update X when changing Y", cascading test failures when a business rule changes, duplicated validation logic.

---

#### MODEL COUPLING (Third level)

Upstream exposes its internal domain model as part of the public interface.

**Degrees** (via static connascence):
- _connascence of name_: knows field names of the model
- _connascence of type_: knows specific types of the model
- _connascence of meaning_: interprets specific values
- _connascence of algorithm_: must use same algorithm to interpret data
- _connascence of position_: depends on element order

---

#### CONTRACT COUPLING (Weakest — Ideal)

Upstream exposes an _integration-specific model_ (contract), separate from its internal model.

**Characteristics of good Contract Coupling**:
- Dedicated DTOs/ViewModels per use case
- Versionable contracts (V1, V2)
- Primitive types or simple value types
- Explicit contract documentation (OpenAPI, Protobuf, etc.)
- Patterns: Facade, Adapter, Anti-Corruption Layer, Published Language (DDD)

---

### PHASE 4 — Volatility Assessment

For each module, estimate volatility based on:

**4.1 Subdomain type** (preferred) — see table in Phase 1

**4.2 Git analysis** (when available):

```bash
git log --since="6 months ago" --format="" --name-only | sort | uniq -c | sort -rn | head -20
```

---

### PHASE 5 — Balance Score Calculation

For each coupled pair (A → B):

**Maintenance effort formula**:

```
MAINTENANCE_EFFORT = STRENGTH × DISTANCE × VOLATILITY
```

**Classification table**:

| Strength | Distance | Volatility | Diagnosis                                                        |
| -------- | -------- | ---------- | ---------------------------------------------------------------- |
| High     | High     | High       | 🔴 **CRITICAL** — Global complexity + high change cost           |
| High     | High     | Low        | 🟡 **ACCEPTABLE** — Strong but stable (e.g. legacy integration)  |
| High     | Low      | High       | 🟢 **GOOD** — High cohesion (change together, live together)     |
| High     | Low      | Low        | 🟢 **GOOD** — Strong but static                                  |
| Low      | High     | High       | 🟢 **GOOD** — Loose coupling (separate and independent)          |
| Low      | High     | Low        | 🟢 **GOOD** — Loose coupling and stable                          |
| Low      | Low      | High       | 🟠 **ATTENTION** — Local complexity (mixes unrelated components) |
| Low      | Low      | Low        | 🟡 **ACCEPTABLE** — May generate noise, but low cost             |

---

### PHASE 6 — Analysis Report

Load `references/report-template.md` for the exact report structure (6.1 Executive Summary, 6.2 Dependency Map, 6.3 Issues, 6.4 Positive Patterns, 6.5 Recommendations).

---

> For Anti-Corruption Layer and Bounded Context integration strategies that implement Contract Coupling at the domain level, see `domain-driven-design`.

---

## Examples

### Example 1: Critical coupling

`OrderService` reads the `payment.transactions` table directly.
Strength: Intrusive | Distance: High (separate services) | Volatility: High
Score: 🔴 CRITICAL
Recommendation: Introduce a `PaymentClient` contract; `OrderService` calls the Payment API, not its database.

### Example 2: Acceptable coupling

`InvoiceService` → `InvoiceRepository` (same bounded context, same package).
Strength: Model coupling | Distance: Very low | Volatility: Low
Score: 🟢 GOOD — high cohesion, change together is correct.
