# Plan Document Reviewer Prompt Template

**Purpose:** Confirm a PLAN.md is executable by a subagent that has no memory of the planning
conversation — the only context it gets is the plan text itself.

**Use at:** Phase 5 — Self-Review Gate, after the plan is authored.

Two ways to use this file. `plan-writer` Phase 5 works through the three passes below as its own
checklist, without dispatching anything. When you want an independent pair of eyes — a large plan,
or one you authored across several sessions — dispatch the prompt block as a subagent instead.

**Substitute (dispatch only):** `[PLAN_FILE_PATH]`, `[SPEC_FILE_PATH]`.

```
Task tool (general-purpose):
  description: "Review plan document"
  prompt: |
    Review a test-first implementation plan for executability. You are the last gate before
    subagents start writing code from it.

    **Plan:** [PLAN_FILE_PATH]
    **Approved spec:** [SPEC_FILE_PATH]

    Read the plan end to end before judging any single task. Read the spec second — you
    need it to answer coverage questions, not to re-litigate design decisions that were
    already approved.

    ## The standard you are applying

    Every task will be handed to a fresh subagent with no access to this conversation.
    Ask of each task: **could that subagent finish it using only the task text?** If it
    would have to guess a type name, invent a file path, or decide for itself what
    "handle errors properly" means, the task is not ready.

    ## Pass 1 — task mechanics

    Each task must carry these, with nothing implied:

    | Element | Must contain |
    |---------|--------------|
    | Intent | One sentence: what behavior exists after this task that did not before |
    | Test-first tier | 1, 2, or 3 — with a justification for anything other than 1 |
    | Acceptance criteria | The spec AC ids this task covers |
    | Contract | Interfaces, signatures, event payloads, or schema — required whenever the task defines or changes a shape; traceable to the plan's Architecture Decisions |
    | Verification cycle | Write the test → run it and confirm it fails for the right reason → implement → run and confirm green, repeated per AC |
    | Commit | Concrete `git add` paths and the commit message |

    For each test step: the test's name and its assertion must be stated, and the run step
    must carry the exact command plus the failure expected. "Write the test" and "run it and
    confirm it fails" must be separate steps — the observed red is the gate the cycle rests on.

    Flag: a missing element, a task whose Intent takes more than one sentence, a shape-changing
    task with no Contract, a run step with no command or no expected output, and any placeholder
    where a decision belongs.

    **Do not flag** the absence of method bodies or test bodies. The plan fixes contracts and
    states assertions; the implementer writes the code. A plan that pre-writes every body is
    over-specified, not thorough.

    Also check the **Files** block of each task: created paths must be exact, modified
    paths should carry line ranges, and the test path must correspond to the file under
    test.

    ## Pass 2 — cross-task coherence

    A plan can have flawless individual tasks and still be unbuildable.

    - **Forward references.** A later task uses a class, method, or field that no earlier
      task creates and that does not already exist in the codebase.
    - **Signature drift.** The same method appears in two tasks with different parameters
      or return type. Quote both.
    - **Ordering.** A task depends on something a later task builds.
    - **Commit prefix consistency.** Either every task's commit uses a Jira subtask key,
      or none does. A plan that mixes both is a defect.

    ## Pass 3 — coverage against the spec

    Build the mapping yourself; do not trust the plan's own claims.

    - Every behavioral and non-functional requirement (spec Sections 5 and 6) traces to at
      least one task. List any requirement with no task.
    - Every acceptance criterion in Section 7 is verified by a test in some task. An AC
      with no test is a blocking gap.
    - Nothing in the plan is absent from the spec. Behavior the spec never asked for is
      scope creep — name it and quote it.
    - The Impact Analysis table holds real findings, not dashes.
    - The Architecture Decisions table settles invariant ownership, dependency direction,
      contract shape, and failure/transaction boundary — each with the alternative it rejected.
      A decision left to the implementer is a blocking gap, not a detail.

    ## Severity

    **Blocking** — would stop or misdirect an implementer: a missing verification step, a
    collapsed test/run-it pair, a missing Intent, tier, AC list, or Contract, an unsettled
    architecture decision, a placeholder (`TBD`, `TODO`, `implement later`, bare `...`), an
    unresolvable reference, a signature conflict, an uncovered requirement or AC, or scope
    the spec does not authorize.

    **Advisory** — everything else. Task ordering you would have chosen differently,
    naming you find less clear, a test you would have written more thoroughly. Say it once
    under Recommendations and do not let it hold up approval.

    Every blocking issue must quote the line or code block it refers to. If you cannot
    quote it, you have not found a defect — you have a preference, and it belongs in
    Recommendations.

    ## Out of scope for this review

    Do not redesign the architecture, propose additional features, or rewrite the plan.
    Your output is a verdict plus a defect list.

    ## Output Format

    ## Plan Review

    **Status:** Approved | Issues Found

    **Blocking issues:**
    - [Task N, Step M]: <defect> — <what breaks during implementation>
      > <quoted line>

    **Coverage gaps:**
    - <spec requirement or AC id>: no task implements or verifies this

    **Recommendations (advisory, do not block approval):**
    - <suggestion>
```

**Reviewer returns:** Status, Blocking issues, Coverage gaps, Recommendations.
