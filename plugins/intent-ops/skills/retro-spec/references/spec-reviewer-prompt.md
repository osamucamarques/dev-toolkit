# Retro Spec Document Reviewer Prompt Template

**Purpose:** Confirm a retroactively written SPEC.md states *intent* rather than paraphrasing the
code it was derived from, and that every divergence from the implementation is disclosed.

**Dispatch after:** the spec is authored and the Phase 5 self-review gate passes.

**Substitute:** `[SPEC_FILE_PATH]`. Pass the spec content inline if it is not yet on disk.

```
Task tool (general-purpose):
  description: "Review retro spec document"
  prompt: |
    Review a specification that was written *after* the code, from the code. This changes
    what can go wrong: the author had a working implementation in front of them, so the
    dominant failure is not vagueness — it is a spec that describes the implementation and
    calls that the requirement.

    **Spec:** [SPEC_FILE_PATH]

    Read the whole spec first, including Section 12 (Decisions and Deviations) and
    Section 13 (Implementation Notes) if present.

    ## Pass 1 — the circularity test (the reason this review exists)

    A retro spec must say what the system is *for*, not narrate what the code *does*. For
    each requirement in Section 5, ask: **if the implementation were deleted, would this
    sentence still tell someone what to build — and why?**

    A requirement that only makes sense as a description of the existing code is the defect
    this review exists to catch. Quote it and state what intent it fails to express.

    ## Pass 2 — intent leaks

    Scan every Context, Outcome, and requirement sentence for three signals:

    | Signal | Example of a leak | What it should have said |
    |--------|-------------------|--------------------------|
    | Technical verb | "the system SHALL intercept the request" | the behavior the interception achieves |
    | Infrastructure term outside Constraints | "SHALL read the JWT from the header" | the identity or authorization outcome |
    | Out of Scope listing a rejected technique | "Out of scope: Redis caching" | the excluded *behavior*, not the discarded approach |

    Infrastructure nouns are legitimate inside Non-Functional Requirements and explicit
    constraints. They are leaks when they become the substance of a behavioral requirement.
    Quote each occurrence.

    ## Pass 3 — disclosure completeness in Section 13

    Section 13 may be omitted only when there are genuinely no gaps, no idempotency risks,
    and no compatibility risks. If it is absent, verify that claim against the spec's own
    content rather than accepting it.

    When present:

    - **Alignment gaps.** Every gap names the code behavior, the spec requirement, and a
      resolution direction (fix code / relax spec / accept). A gap row with an empty
      resolution column is incomplete.
    - **Idempotency coverage.** Every state-mutating operation described anywhere in the
      spec appears in the idempotency table. Build that list yourself from Section 5 and
      compare — an operation that creates, updates, or deletes state and is missing from
      the table is a blocking omission.
    - **Backward compatibility.** Every public contract in Section 5.5 appears in the
      compatibility table with a risk verdict.

    ## Pass 4 — Section 12 versus Section 13 discipline

    These two sections mean different things, and conflating them hides risk:

    - Section 12 holds **deliberate** decisions that diverge from what the spec would
      otherwise require — each with reason, status, and standing risk.
    - Section 13 holds **unintended** divergence between code and spec.

    Flag: a deliberate decision listed as an alignment gap, an unintended gap dressed up as
    a decision, and any Section 12 entry missing its reason or its standing risk.

    ## Pass 5 — baseline spec quality

    Apply the same structural bar as a forward spec, since a retro spec is held to an
    identical standard:

    - Section 5 requirements use complete EARS/GEARS patterns, not bare keywords, and sit
      in the correct subsection.
    - Domain terms match the Section 11 glossary in canonical form; retired aliases are
      defects.
    - Acceptance criteria in Section 7 are objectively decidable.
    - No placeholders, no contradictions, Section 8 present and non-empty.

    ## The indistinguishability check

    Finally: **could a reader tell this spec was written from code, if Section 13 were
    removed?** If the requirements read like a code walkthrough, say so plainly — that is a
    blocking finding even when every individual sentence is defensible.

    ## Severity

    **Blocking** — circular requirements, intent leaks, an omitted state-mutating operation
    or public contract, a gap with no resolution direction, Section 12/13 conflation, a
    structurally broken requirement, a glossary violation, or a placeholder.

    **Advisory** — phrasing, ordering, depth imbalance between sections.

    Quote the exact line for every blocking issue. Unquotable objections are preferences
    and belong under Recommendations.

    ## Out of scope for this review

    Do not propose refactors, redesign the implementation, or judge whether the code is
    good. You are reviewing whether the spec tells the truth about intent and discloses
    every divergence.

    ## Output Format

    ## Retro Spec Review

    **Status:** Approved | Issues Found

    **Blocking issues:**
    - [Section N]: <defect> — <what it hides or misstates>
      > <quoted line>

    **Undisclosed divergence:**
    - <operation or contract>: missing from Section 13

    **Recommendations (advisory, do not block approval):**
    - <suggestion>
```

**Reviewer returns:** Status, Blocking issues, Undisclosed divergence, Recommendations.
