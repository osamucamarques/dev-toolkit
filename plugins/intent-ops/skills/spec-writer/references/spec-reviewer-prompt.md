# Spec Document Reviewer Prompt Template

**Purpose:** Confirm a SPEC.md captures intent precisely enough that a plan built from it would
implement the right thing — before anyone is authorized to write code.

**Dispatch after:** the spec is authored and the Phase 5 self-review passes.

**Substitute:** `[SPEC_FILE_PATH]`. Pass the spec content inline if it is not yet on disk.

```
Task tool (general-purpose):
  description: "Review spec document"
  prompt: |
    Review a specification for precision of intent. Nothing has been built yet, and no
    code may be written until this spec is approved — so an ambiguity you let through
    becomes a feature built wrong.

    **Spec:** [SPEC_FILE_PATH]

    Read the whole spec before judging any section. The glossary (Section 11) and the
    Out of Scope list (Section 8) change how you must read Sections 5 and 7 — read them
    first if you are tempted to skim.

    ## The standard you are applying

    For each requirement, ask: **could two competent engineers read this and build
    different things?** If yes, that is the defect — not the wording, the divergence.
    Name both readings when you flag it.

    ## Pass 1 — requirement structure

    Section 5 requirements must use a complete EARS/GEARS pattern, not merely contain the
    keyword. The keyword without its clause is the most common failure:

    | Subsection | Required shape |
    |-----------|----------------|
    | 5.1 Ubiquitous | `The <system> SHALL <response>` |
    | 5.2 Event-driven | `WHEN <trigger> the <system> SHALL <response>` |
    | 5.3 Conditional / unwanted state | `IF <condition> THEN the <system> SHALL <response>` |
    | 5.4 State-dependent | `WHILE <state> the <system> SHALL <response>` |
    | 5.5 Integration contracts | The contract, its direction, and its failure behavior |

    Flag as blocking: a `WHEN` with no trigger, an `IF` with no `THEN`, a requirement
    filed under the wrong subsection, a requirement with two responses fused into one
    statement, and any use of `should` / `may` / `might` where `SHALL` is meant.

    ## Pass 2 — ubiquitous language

    Every domain term in Sections 4 through 7 must appear in the Section 11 glossary and
    be used in its canonical form. Retired aliases are defects, not style: if the glossary
    retires "client" in favor of "Tenant", then "client" appearing in a requirement means
    the requirement and the glossary disagree about what the system is. Quote each
    occurrence.

    ## Pass 3 — internal consistency and completeness

    - **Contradictions.** Two requirements that cannot both hold. Quote both.
    - **Acceptance criteria.** Every criterion in Section 7 must be objectively decidable
      — a human or a test can say yes or no without judgment. "Works correctly",
      "performs well", and "is user friendly" are not criteria.
    - **Traceability.** Every acceptance criterion traces back to a requirement, and no
      requirement in Sections 5 or 6 is left without one.
    - **Boundary honesty.** Section 8 must exist and be non-empty. A spec that excludes
      nothing has not been scoped.
    - **Placeholders.** `TBD`, `TODO`, `<...>`, an unfilled template heading, or an empty
      section that the template expects to be filled.
    - **Open questions.** Section 9 items are acceptable, but any open question that
      would change a requirement's meaning is blocking — say which requirement it
      destabilizes.

    ## Pass 4 — scope and bounded context

    - The spec covers **one** bounded context. If Sections 2 and 5 describe work that
      belongs to two independently deployable subsystems, say so and name the split.
    - Requirements the interview never established, and that no stakeholder asked for,
      are speculative scope. Flag them.

    ## Severity

    **Blocking** — would produce a flawed plan: a structurally broken requirement, a
    contradiction, an ambiguity with two defensible readings, an untestable acceptance
    criterion, a glossary violation, a placeholder, a missing Out of Scope section, or a
    spec spanning multiple bounded contexts.

    **Advisory** — phrasing you would tighten, sections you find thinner than others,
    ordering preferences. Recommendations only; these never block.

    Quote the exact line for every blocking issue. An unquotable objection is a
    preference, and preferences go under Recommendations.

    ## Out of scope for this review

    Do not propose a design, choose an implementation approach, or add requirements. You
    are checking whether the stated intent is unambiguous, not deciding what the intent
    should be.

    ## Output Format

    ## Spec Review

    **Status:** Approved | Issues Found

    **Blocking issues:**
    - [Section N]: <defect> — <the two ways this could be read, or what it breaks>
      > <quoted line>

    **Recommendations (advisory, do not block approval):**
    - <suggestion>
```

**Reviewer returns:** Status, Blocking issues, Recommendations.
