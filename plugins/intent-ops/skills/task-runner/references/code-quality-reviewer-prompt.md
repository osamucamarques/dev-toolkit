# Code Quality Reviewer Prompt Template

> **Attribution.** Derived from [`subagent-driven-development/task-reviewer-prompt.md`](https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/task-reviewer-prompt.md) in [obra/superpowers](https://github.com/obra/superpowers) by **Jesse Vincent**, licensed under [MIT](https://github.com/obra/superpowers/blob/main/LICENSE).
> **Changes made:** Condensed and refocused on code quality; spec compliance was split into a separate prompt.

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify the implementation is well-built — clean, tested, and maintainable.

**Only dispatch after spec compliance review passes (✅ Spec compliant).**

```
Task tool (general-purpose):
  description: "Code quality review for Task N"
  prompt: |
    Use the template at intent-ops:code-reviewer references/code-reviewer-prompt.md

    DESCRIPTION: [task summary — what was built, from the implementer's report]
    PLAN_OR_REQUIREMENTS: Task N from [plan-file-path]
    BASE_SHA: [commit before task started]
    HEAD_SHA: [current commit]
```

**In addition to standard code quality concerns, check:**
- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Does the implementation follow the file structure from the plan?
- Did this change create new files that are already large, or significantly grow existing
  files? (Do not flag pre-existing file sizes — focus on what this task contributed.)
- Do tests verify real behavior, not mock behavior?

**Reviewer returns:** Strengths, Issues (Critical / Important / Minor), Assessment
