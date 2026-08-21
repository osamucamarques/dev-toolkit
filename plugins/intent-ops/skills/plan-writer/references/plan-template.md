# Plan Writer — Document Templates

> **Attribution.** The task scaffolding here — the five-step TDD cycle labels and the plan/task
> headings — follows [`writing-plans`](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md)
> in [obra/superpowers](https://github.com/obra/superpowers) by **Jesse Vincent**, licensed under
> [MIT](https://github.com/obra/superpowers/blob/main/LICENSE).
> **Changes made:** adds the Impact Analysis table, exact-path Files blocks, Java examples, and the
> Jira-prefixed commit convention.

## Plan Document Header

Every PLAN.md must start with this header:

```markdown
# [Feature Name] Implementation Plan

> **Spec:** `docs/specs/<spec-filename>.md`
> **Approval required before execution** — see HARD-GATE.

**Goal:** [One sentence describing what this builds — copied from the spec]

**Architecture:** [2–3 sentences about the approach chosen in Phase 3]

**Tech Stack:** [Key technologies, frameworks, libraries]

## Impact Analysis

| Bounded Contexts affected | Contracts at risk | Architectural rules at risk | Deploy risks |
|---------------------------|--------------------|------------------------------|---------------|
| … | … | … | … |

---
```

---

## Task Structure

Each task maps to one cohesive unit of work (one class, one endpoint, one migration).
Every task MUST follow this structure exactly:

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/File.java`
- Modify: `exact/path/to/Existing.java:123-145`
- Test: `src/test/exact/path/to/FileTest.java`

- [ ] **Step 1: Write the failing test**

```java
@Test
void shouldDoSpecificBehavior() {
    var result = subject.method(input);
    assertThat(result).isEqualTo(expected);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./gradlew test --tests "com.example.FileTest.shouldDoSpecificBehavior"`
Expected: FAIL — `FileTest > shouldDoSpecificBehavior FAILED`

- [ ] **Step 3: Write minimal implementation**

```java
public ReturnType method(InputType input) {
    // minimal implementation
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./gradlew test --tests "com.example.FileTest.shouldDoSpecificBehavior"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/example/File.java src/test/java/com/example/FileTest.java
git commit -m "JIRA-TASK-ID: feat: add specific behavior"
```

> Replace `JIRA-TASK-ID` with the Jira subtask key for this task (e.g. `PROJ-1235`),
> or omit the prefix if Jira subtasks were not created.
````
