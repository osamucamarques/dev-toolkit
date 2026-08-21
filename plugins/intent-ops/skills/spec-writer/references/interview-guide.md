# Spec Writer — Interview & Context Map Reference

## Phase 2 — Socratic Question Bank

Adapt questions to the issue — do not follow mechanically.

| # | Area | Sample framing |
|---|------|----------------|
| 1 | Core intent | "What is the single most important outcome this feature/fix must deliver?" |
| 2 | Actor | "Who are the primary actors and what are their distinct needs?" |
| 3 | Trigger / Event | "What event or condition initiates this behavior?" |
| 4 | Happy path | "Walk me through the ideal execution — step by step — from trigger to outcome." |
| 5 | Failure modes | "What are the top 2–3 ways this can go wrong, and what must the system do?" |
| 6 | NFRs | "Are there latency, availability, security, or compliance constraints we must honor?" |
| 7 | Boundaries | "What is explicitly OUT of scope for this spec?" |
| 8 | Acceptance | "How will we know this is done? What would a failing acceptance test look like?" |
| 9 | Recurrence | (if prior incidents detected) "We've seen similar issues before — does this spec supersede or complement those?" |
| 10 | Decomposition check | "Does anything here feel like it belongs to a separate system or team?" |
| 11 | Language check | "When you say '<term>', do you mean the same thing as '<synonym>'? Which should we use going forward?" |
| 12 | Context ownership | "Which team or system owns the '<entity>' you just described? Is it part of our system or external?" |

---

## Phase 2.5 — DDD Context Map Patterns

For each pair of contexts that interact around this feature, classify their relationship:

| Pattern | Meaning |
|---------|---------|
| **Upstream / Downstream (U/D)** | One context's model drives the other; downstream adapts to upstream |
| **Shared Kernel** | Two contexts share a subset of the domain model and coordinate changes |
| **Customer / Supplier** | Downstream negotiates requirements with upstream; upstream commits to a contract |
| **Conformist** | Downstream adopts upstream's model as-is, with no translation |
| **Anti-Corruption Layer (ACL)** | Downstream translates upstream's model to protect its own model's integrity |
| **Open Host Service (OHS)** | Upstream publishes a protocol others can integrate against (e.g., a REST API) |
| **Published Language** | Upstream publishes a well-documented shared language (e.g., event schema, OpenAPI) |
| **Separate Ways** | Contexts do not integrate — they solve the problem independently |

Context map table format to present to the user:

```
## Context Map (draft — please confirm)

| Context | Responsibility | Relationship to this feature | Pattern |
|---------|---------------|------------------------------|---------|
| [Context A] | … | Upstream — provides [X] identity | OHS |
| [Context B] | … | This feature lives here | — |
| [Context C] | … | Downstream — consumes events | U/D |
```
