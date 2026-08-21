---
name: coverage-driven-test-generation
description: 'Generates JUnit 5 + Mockito tests from JaCoCo reports to close missed branches (MC/DC strategy). Use when JaCoCo shows missed branches, asked to "complete coverage", "add unit tests", "improve jacoco", or coding-guidelines DoD requires coverage verification. Java only, not for integration tests.'
license: MIT
metadata:
  author: Samuel Marques
  version: 1.0.0
---

> This skill is part of the **code-standard.md** workflow. Run it after writing or changing any Java code, as required by `coding-guidelines`. It enforces the DoD requirement that all non-excluded classes have adequate branch and line coverage.

# Java Coverage Engineer

Maximize **JaCoCo branch coverage first, then line coverage** for Spring Boot / JUnit 5 / Mockito projects, prioritizing missed branches, partially covered decisions, and uncovered lines. Never change production behavior.

**Focus on:** service classes, domain logic, validators, adapters, event listeners, exception handling, fallback flows. Prioritize classes with the lowest branch coverage %, then highest missed lines.

---

# Step 1 — Load Sonar Exclusions

Before analyzing coverage, read `gradle/sonar.gradle` (or equivalent Sonar config) to extract the `sonar.coverage.exclusions` list.

**Skip any class whose path matches one of these patterns** — they are excluded from the quality gate and generating tests for them wastes effort.

---

# Step 2 — Locate JaCoCo Report

Search in this order:

```text
build/reports/jacoco/test/jacocoTestReport.xml
build/reports/jacoco/test/html/index.html
build/reports/jacoco/test/jacocoTestReport.html
target/site/jacoco/jacoco.xml
target/site/jacoco/index.html
```

**If no report is found**, generate it before proceeding:

```bash
./gradlew jacocoTestReport
```

Then re-check the locations above. If the report is still absent after generation, stop and inform the user — the build may be misconfigured or tests may be failing to compile.

Prefer **XML report** when available — it is easier to identify missed branches, partially covered lines, and exact methods/classes.

---

# Step 3 — Identify Coverage Gaps

Parse the JaCoCo XML report. For each class **not excluded by Sonar**:

1. Compute branch coverage: `covered_branches / (covered_branches + missed_branches)`
2. Compute line coverage: `covered_lines / (covered_lines + missed_lines)`
3. Record exact line numbers with `missed_branches > 0` or `missed_instructions > 0`

## Detecting Partially Covered Paths

JaCoCo marks a line as **partially covered** when at least one branch on that line is taken but at least one is not. These are the highest-value targets.

In the XML, look for `<line>` elements where `cb` (covered branches) > 0 **AND** `mb` (missed branches) > 0.

**Rank targets** in this order:
1. Classes with the most **partially covered lines** — easiest wins
2. Classes with lowest branch coverage % (most fully missed branches)
3. Classes with lowest line coverage % among those with 100% branch coverage

---

# Step 4 — Prioritization Heuristics

## 1. Partially covered lines (highest ROI)
## 2. Lowest branch coverage
## 3. Missed lines (when branch coverage is already 100%)
## 4. Business-critical classes: `*Service`, `*Validator`, `*Handler`, `*Listener`, `*Processor`, `*Mapper`, `*Strategy`
## 5. Defensive code: null checks, optional chains, exception paths, fallback branches, retries

---

# MC/DC Strategy (Mandatory)

For every decision expression, generate the minimum set of tests proving each condition independently affects the outcome.

Mandatory rules:

1. Each condition must be **true and false** in at least one test
2. Each condition must independently change decision result
3. Use the minimum number of tests needed

---

# Test Framework Rules

Always use:

- **JUnit 5**
- **Mockito**
- `@ExtendWith(MockitoExtension.class)`

Preferred imports:

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
```

---

# Mocking Rules

Always mock external dependencies:
- repositories, RestTemplate / WebClient, KafkaTemplate / consumers, filesystem, external SDKs, Spring beans

Never hit real: database, HTTP, broker, disk.

---

# Preferred Test Naming

Use descriptive names:

```java
shouldReturnFallbackWhenPrimaryHandlerFails()
shouldThrowWhenRequestIsNull()
shouldSkipProcessingWhenTenantIsInactive()
```

---

# Output Rules

Return only:
- newly created test classes
- minimal helper fixtures
- mocks/builders if required

Do not include explanations. Do not refactor production code unless unavoidable.

---

# Final Verification Workflow

After generating tests:

```bash
./gradlew test jacocoTestReport
```

Then verify both branch and line coverage improvement by re-parsing the XML report.

---

# Definition of Done

Before declaring tests complete: all non-Sonar-excluded classes have no missed branches or uncovered lines; TC entries and Coverage Matrix in `testing.md` are updated; no regressions. See `java-code-standards:coding-guidelines` for the full DoD checklist.

---

## Examples

### Example 1: Partial branch coverage

JaCoCo XML shows `OrderValidator` line 42: `cb=1, mb=1`.
```java
if (order.getItems().isEmpty() || order.getTotal() < 0)
```
Generated tests:
- `shouldFailWhenItemsEmpty()` — `isEmpty()=true`, `total≥0`
- `shouldFailWhenTotalNegative()` — `isEmpty()=false`, `total<0`
Result: line 42 goes from partial to 100% branch coverage.

### Example 2: Uncovered class

`InvoiceCalculator` has 0% branch coverage (not in Sonar exclusions).
Actions: Read the class, generate MC/DC tests for every decision expression, run `./gradlew test jacocoTestReport`, confirm improvement.
