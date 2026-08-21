# Testing Anti-Patterns

> **Attribution.** Derived from [`test-driven-development/testing-anti-patterns.md`](https://github.com/obra/superpowers/blob/v6.1.1/skills/test-driven-development/testing-anti-patterns.md) in [obra/superpowers](https://github.com/obra/superpowers) by **Jesse Vincent**, licensed under [MIT](https://github.com/obra/superpowers/blob/main/LICENSE).
> **Changes made:** Condensed; examples reworked in Java. Pinned to upstream v6.1.1, where this file lives at this path.

**Load this reference when:** writing or changing tests, adding mocks, or tempted to add
test-only methods to production code.

## Overview

Tests must verify real behavior, not mock behavior. Mocks are a tool to isolate dependencies,
not the thing being tested.

**Core principle:** Test what the code does, not what the mocks do.

**Following strict TDD prevents these anti-patterns.**

## The Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding the dependency
```

---

## Anti-Pattern 1: Testing Mock Behavior

**The violation:**
```java
// ❌ BAD: Testing that the mock exists
@Test
void rendersDashboard() {
    render(new DashboardPage());
    assertNotNull(find("#sidebar-mock"));  // testing the mock, not the component
}
```

**Why this is wrong:**
- You are verifying the mock works, not that the component works
- Tells you nothing about real behavior
- Test passes when the mock is present, fails when it is not

**The fix:**
```java
// ✅ GOOD: Test real component or do not mock it
@Test
void rendersDashboard() {
    render(new DashboardPage());  // do not mock the sidebar
    assertNotNull(find("[role=navigation]"));  // test real behavior
}
```

### Gate

```
BEFORE asserting on any mock element:
  Ask: "Am I testing real component behavior or just mock existence?"
  IF testing mock existence: delete the assertion or unmock the component.
```

---

## Anti-Pattern 2: Test-Only Methods in Production

**The violation:**
```java
// ❌ BAD: destroy() only called in tests
public class TenantSession {
    public void destroy() {  // looks like production API!
        workspaceManager.destroyWorkspace(this.id);
    }
}
```

**Why this is wrong:**
- Production class polluted with test-only code
- Dangerous if accidentally called in production
- Violates YAGNI and separation of concerns

**The fix:**
```java
// ✅ GOOD: move to test utilities
// TenantSession has no destroy() method

// In test-utils/
public static void cleanupSession(TenantSession session) {
    workspaceManager.destroyWorkspace(session.getId());
}
```

### Gate

```
BEFORE adding any method to a production class:
  Ask: "Is this only used by tests?"
  IF yes: do not add it — put it in test utilities instead.
```

---

## Anti-Pattern 3: Mocking Without Understanding

**The violation:**
```java
// ❌ BAD: mock prevents config write that test depends on
when(toolCatalog.discoverAndCacheTools()).thenReturn(null);  // over-mocking

service.addServer(config);
service.addServer(config);  // should throw duplicate — but won't, mock wiped side effect
```

**Why this is wrong:**
- Mocked method had a side effect the test depended on
- Over-mocking to "be safe" breaks actual behavior
- Test passes for the wrong reason

**The fix:**
```java
// ✅ GOOD: mock at the right level
when(serverManager.start()).thenReturn(null);  // mock the slow part only
// config write preserved — duplicate detection works correctly
```

### Gate

```
BEFORE mocking any method:
  1. What side effects does the real method have?
  2. Does this test depend on any of those side effects?
  3. Do I fully understand what this test needs?

  IF unsure: run the test with the real implementation first. Observe what actually happens.
  THEN add minimal mocking at the right level.
```

---

## Anti-Pattern 4: Incomplete Mocks

**The violation:**
```java
// ❌ BAD: only mocking fields you think you need
TenantResponse mockResponse = TenantResponse.builder()
    .status("success")
    .tenantId("t-123")
    .build();
// Missing: metadata.requestId that downstream code uses — silent NPE
```

**Why this is wrong:**
- Partial mocks hide structural assumptions
- Downstream code may depend on fields you did not include
- Tests pass but integration fails

**The fix:**
```java
// ✅ GOOD: mirror the real API response completely
TenantResponse mockResponse = TenantResponse.builder()
    .status("success")
    .tenantId("t-123")
    .metadata(Metadata.builder().requestId("req-789").build())
    .build();
```

### Gate

```
BEFORE creating mock responses:
  1. What fields does the real API response contain?
  2. Include ALL fields the system might consume downstream.
  3. Verify the mock matches the real response schema completely.
```

---

## Anti-Pattern 5: Tests as Afterthought

**The violation:**
```
✅ Implementation complete
❌ No tests written
"Ready for testing now"
```

Tests are part of implementation, not an optional follow-up. If you completed implementation
without writing tests first, the work is not done. Follow `intent-ops:tdd-guide`.

---

## Quick Reference

| Anti-Pattern | Fix |
|---|---|
| Assert on mock elements | Test real component or unmock it |
| Test-only methods in production | Move to test utilities |
| Mock without understanding | Understand dependencies first, mock minimally |
| Incomplete mocks | Mirror real API completely |
| Tests as afterthought | TDD — tests first |

## Red Flags

- Assertion checks for `*-mock` test IDs
- Methods only called in test files
- Mock setup is more than 50% of the test body
- Test fails when you remove the mock
- Can not explain why the mock is needed
- Mocking "just to be safe"
