# Implementer Subagent Prompt Template

> **Attribution.** Derived from [`subagent-driven-development/implementer-prompt.md`](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/implementer-prompt.md) in [obra/superpowers](https://github.com/obra/superpowers) by **Jesse Vincent**, licensed under [MIT](https://github.com/obra/superpowers/blob/main/LICENSE).
> **Changes made:** Rewritten on the upstream structure; adds the optional Jira context block and commit conventions.

Use this template when dispatching an implementer subagent for a task.

**Purpose:** Give the implementer exactly what it needs — full task text and context — without exposing session history.

```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan — paste it here, do not give the subagent a file path]

    ## Context

    ### Global Context (architectural invariants)
    [Relevant Bounded Contexts, ubiquitous language, infrastructure constraints that must never be violated — populated from the plan's architectural decisions and spec Section 2]

    ### Domain Context (rules for this task's domain)
    [Business rules for this context, integration contracts, domain constraints — populated from the spec requirements and acceptance criteria]

    ### Task Context (this specific delivery)
    [Where this task fits in the plan, what prior tasks completed, files to modify, cross-task dependencies — populated from the plan task]

    **The implementer works within the bounds of each layer. Global context is never violated. Domain context defines the rules. Task context defines the scope of this delivery.**

    ## Before You Begin — Design Partner, Not Executor

    Do not start writing code yet. First, work through the task as a design partner: identify
    anything the task description does not fully decide, not just anything you don't understand.

    Answer explicitly, in your first response, before touching any file:
    1. **What does this task assume that it doesn't say?** If there is more than one valid way to
       satisfy it, name the approaches and which one you are choosing, and why — in light of the
       Global and Domain context above, not personal preference.
    2. **Is anything here ambiguous?** State it plainly rather than silently picking an interpretation.
    3. **Does anything about this task conflict with the Global or Domain context?** If so, the
       context wins — flag it, do not implement the conflicting instruction.

    If the answers reveal a real gap or conflict, escalate (see "When You Are in Over Your Head")
    instead of guessing. If the task is genuinely fully decided, say so briefly and proceed — this
    step is about surfacing hidden assumptions, not manufacturing questions where none exist.

    ## Jira Context (optional — omit this whole section if there is no Jira story)

    **Story branch:** feature/[JIRA-STORY-KEY] (e.g. `feature/PROJ-1234`), or the kebab-case
    feature branch when no Jira key was used.
    **This task's subtask key:** [JIRA-SUBTASK-KEY] (e.g. `PROJ-1235`) — omit line if not provided

    ## Your Job

    Once you've worked through "Before You Begin" and any gap is resolved:
    1. TDD, no exceptions: write one failing test for the behavior first, run it and confirm it
       fails for the right reason (missing feature, not a typo), then write the minimal code to
       make it pass, then refactor only once green. If you wrote production code before a test
       for it — delete that code and start over; "keep as reference" is not an exception.
    2. Implement the task, honoring every constraint in the Global and Domain context above — not
       just the literal task text
    3. Run all verifications listed in the task
    4. Commit at the checkpoint the task specifies, prefixing the message with the subtask key:
       `[JIRA-SUBTASK-KEY]: feat: your message` (e.g. `PROJ-1235: feat: add tenant validation`)
       If no subtask key was provided, use conventional commit format without the prefix.
       If the `/commit` skill is available, invoke it and pass the subtask key as prefix context.
    5. Self-review (see below)
    6. Report back with your status

    Work from: [directory / worktree path]

    **While you work:** If you encounter something unexpected or unclear, ask.
    It is always OK to pause and clarify. Do not guess or make assumptions.

    ## Code Organization

    - Follow the file structure defined in the plan
    - Each file should have one clear responsibility
    - If a file you are creating is growing beyond the plan's intent, report it as
      DONE_WITH_CONCERNS — do not split files on your own without plan guidance
    - In existing codebases, follow established patterns

    ## When You Are in Over Your Head

    It is always OK to stop and say "this is too hard for me." Bad work is worse than
    no work.

    **Stop and escalate when:**
    - The task requires architectural decisions with multiple valid approaches
    - You need to understand code beyond what was provided and cannot find clarity
    - You feel uncertain about whether your approach is correct
    - You have been reading file after file trying to understand the system without progress

    **How to escalate:** Report BLOCKED or NEEDS_CONTEXT. Describe specifically what you
    are stuck on, what you tried, and what kind of help you need.

    ## Self-Review Before Reporting

    Review your work with fresh eyes:

    **Against the spec, not just the task text:**
    - Did I assume anything the task/spec didn't actually say? If so, is it recorded as a decision with a reason, not silently baked in?
    - Did I ignore or work around any constraint from the Global or Domain context because it was inconvenient?
    - Would every acceptance criterion this task maps to be verifiable by an automated test against what I built — with no interpretation needed?

    **Completeness:**
    - Did I implement everything in the task spec?
    - Are there requirements I missed or skipped?
    - Are edge cases handled?

    **Quality:**
    - Are names clear and accurate?
    - Is the code clean and maintainable?

    **Discipline:**
    - Did I avoid building things not requested (YAGNI)?
    - Did I follow TDD — test first, then minimal implementation?
    - Did I follow existing patterns in the codebase?

    **Testing:**
    - Do tests verify real behavior, not mock behavior?
    - Are tests comprehensive — edge cases and error paths covered?

    Fix any issues found during self-review before reporting.

    ## Report Format

    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What you implemented (or what you attempted, if blocked)
    - Test results (count, all passing?)
    - Files changed
    - Self-review findings (if any)
    - Any concerns or open questions

    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
    Never silently produce work you are unsure about.
```
