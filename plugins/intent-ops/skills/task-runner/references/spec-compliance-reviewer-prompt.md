# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent.

**Purpose:** Verify the implementer built exactly what was requested — nothing more, nothing less.

**Dispatch after:** The implementer reports DONE or DONE_WITH_CONCERNS.
**Dispatch before:** Code quality review (spec compliance must pass first).

```
Task tool (general-purpose):
  description: "Spec compliance review for Task N"
  prompt: |
    You are reviewing whether an implementation matches its specification.

    ## What Was Requested

    [FULL TEXT of task requirements — paste the task spec from the plan]

    ## What the Implementer Reports

    [Implementer's status report — what they claim to have built]

    ## CRITICAL: Do Not Trust the Report

    The implementer may have been optimistic, incomplete, or may have misunderstood a
    requirement. You MUST verify everything independently.

    **DO NOT:**
    - Take their word for what they implemented
    - Trust their claims about completeness
    - Accept their interpretation of requirements

    **DO:**
    - Read the actual code they wrote
    - Compare the implementation to requirements line by line
    - Check for missing pieces they claim to have implemented
    - Look for extra features they did not mention

    ## Your Job

    Read the implementation code and answer these three questions — they are the objective test
    for whether an LLM output actually satisfies a spec, not "does it look reasonable":

    **1. Did the implementer assume something the task/spec didn't say?**
    - Is there a decision in the code that isn't decided by the requirements? If it's a real gap,
      that's on the spec/task — flag it as a missing requirement upstream, don't just accept the
      implementer's guess. If it's scope the implementer invented (YAGNI), flag it as over-building.

    **2. Did the implementer ignore a constraint?**
    - Constraints are the easiest thing to drop when a model optimizes for a clean-looking
      solution. Check every constraint in the Global/Domain context and every business rule in
      the spec against what was actually built — an elegant solution that violates a constraint
      is not a good solution.

    **3. Is the output verifiable against the Acceptance Criteria?**
    - For each AC this task maps to, can you point to a test that would fail if the behavior were
      wrong, with no interpretation required? If not, either the implementation is incomplete or
      the AC itself is still too vague — say which.

    Verify by reading code, not by trusting the report.

    ## Output Format

    - ✅ **Spec compliant** — all three questions answered cleanly (after code inspection)
    - ❌ **Issues found:**
      - [Assumed without basis]: [what was assumed, what the spec/task actually says] — `file:line`
      - [Constraint ignored]: [which constraint, how it was violated] — `file:line`
      - [Not verifiable]: [which AC, why no test could confirm it] — `file:line`
```
