# Codebase Mapping — Output File Templates

All 7 files are written to `docs/codebase/`. Token budgets exist to keep each file loadable on-demand without flooding context.

---

## 1. `docs/codebase/STACK.md` — 2,000 tokens max

When to load: before dependency, migration, runtime, or tooling work.

```markdown
# Tech Stack

**Analyzed:** [YYYY-MM-DD]

## Core

- Framework: [name + version]
- Language: [name + version]
- Runtime: [name + version]
- Package manager: [name]

## Frontend (omit if not applicable)

- UI Framework: [name + version]
- Styling: [approach + tools]
- State Management: [library/pattern]
- Form Handling: [library if present]

## Backend (omit if not applicable)

- API Style: [REST/GraphQL/gRPC + framework]
- Database: [ORM/query builder + database system]
- Authentication: [library/approach]

## Testing

- Unit: [framework]
- Integration: [framework]
- E2E: [framework if present]

## External Services

- [Category]: [Service name]

## Development Tools

- [Category]: [Tool name]
```

---

## 2. `docs/codebase/ARCHITECTURE.md` — 4,000 tokens max

When to load: before changing flows, service boundaries, resources, repositories, events, or migrations.

```markdown
# Architecture

**Pattern:** [monolith / modular monolith / microservice / etc.]

## High-Level Structure

[Describe or diagram the major layers/components based on actual code organization]

## Identified Patterns

### [Pattern Name]

**Location:** [package or directory]
**Purpose:** [what problem this solves]
**Implementation:** [how it's structured]
**Example:** [concrete file or class reference]

## Data Flow

### [Key Flow — e.g., Request lifecycle, Auth flow, Event processing]

[Step-by-step trace through actual code, with file references]
[Derived from Phase 4 — data flow & state tracing]

## State Management

**Approach:** [how state is managed — local, global, server-side, event-sourced]
**Key patterns found:** [store names, reducers, event types with file refs]

## Code Organization

**Approach:** [feature-based / layer-based / domain-driven / etc.]

**Structure:**
[Map actual directory organization — 2–3 levels]

**Module boundaries:**
[How modules/packages divide responsibility]
```

---

## 3. `docs/codebase/CONVENTIONS.md` — 3,000 tokens max

When to load: before adding or changing code.

```markdown
# Code Conventions

## Naming Conventions

**Files:** [observed pattern]
Examples: [actual filenames]

**Functions/Methods:** [observed pattern]
Examples: [actual method names]

**Variables:** [observed pattern]
Examples: [actual variable names]

**Constants:** [observed pattern]
Examples: [actual constant names]

## Code Organization

**Import ordering:** [observed pattern with example]

**File structure:** [observed internal organization with example]

## Type Safety

**Approach:** [type system / documentation approach]
[Example from actual code]

## Error Handling

**Pattern:** [observed approach]
[Example from actual code]

## Comments

**Style:** [when and how comments are used]
[Example from actual code]
```

---

## 4. `docs/codebase/STRUCTURE.md` — 2,000 tokens max

When to load: when looking for where a capability, module, config, or special directory lives.

```markdown
# Project Structure

**Root:** [path]

## Directory Tree

[Visual tree — max 3 levels]

## Module Organization

### [Module/Area]

**Purpose:** [what this area handles]
**Location:** [path]
**Key files:** [important files]

## Where Things Live

**[Capability]:**
- Business Logic: [path]
- Data Access: [path]
- Configuration: [path]

## Special Directories

**[Directory]:** [purpose and key files]
```

---

## 5. `docs/codebase/TESTING.md` — 4,000 tokens max

When to load: before adding tests, fixing tests, measuring coverage, or choosing a test command.

```markdown
# Testing Infrastructure

## Test Frameworks

**Unit/Integration:** [framework + version]
**E2E:** [framework + version if present]
**Coverage:** [tool if used]

## Test Organization

**Location:** [where tests live]
**Naming:** [file naming pattern]
**Structure:** [how tests are organized]

## Testing Patterns

### Unit Tests

**Approach:** [observed pattern]
**Location:** [path]
[Description with example]

### Integration Tests

**Approach:** [observed pattern]
**Location:** [path]
[Description with example]

### E2E Tests (omit if absent)

**Approach:** [observed pattern]
**Location:** [path]

## Test Execution

**Commands:** [how to run tests]
**Configuration:** [test config approach]

## Coverage

**Current:** [if measurable]
**Goals:** [if documented]
**Enforcement:** [if automated]
**Known gaps:** [areas with little or no coverage — from Phase 5 gap analysis]
```

---

## 6. `docs/codebase/INTEGRATIONS.md` — 5,000 tokens max

When to load: before changing API clients, event handlers, config server, database, or background jobs.

```markdown
# External Integrations

## [Service Category]

**Service:** [name]
**Purpose:** [what this provides]
**Implementation:** [where the integration lives]
**Configuration:** [how the service is configured]
**Authentication:** [auth approach]

## API Integrations

### [API Name]

**Purpose:** [what this API provides]
**Location:** [client/code path]
**Authentication:** [method]
**Key endpoints:** [major endpoints used]

## Event Handling (omit if absent)

### [Topic or Event]

**Direction:** inbound / outbound
**Handler location:** [path]
**Event types:** [list]

## Webhooks (omit if absent)

### [Source]

**Purpose:** [events handled]
**Handler location:** [path]

## Background Jobs (omit if absent)

**Queue system:** [system]
**Location:** [job definitions path]
**Jobs:** [key jobs]
```

---

## 7. `docs/codebase/CONCERNS.md` — 5,000 tokens max

When to load: before risky changes, refactors, performance work, security review, or planning technical debt.

Every concern must cite evidence (file path, line number, measurement, or reproduction step). Omit categories with no findings. Prioritize by impact.

This file is populated from **Phase 5** — the multi-dimensional gap analysis covering Technical, Operational, and Business lenses.

```markdown
# Codebase Concerns

## Technical Concerns

### [Specific Concern Title]

**Risk:** [high / medium / low]
**Evidence:** [file:line or measurement]
**Impact:** [what breaks or degrades if ignored]
**Fix approach:** [concrete remediation steps]

## Operational Concerns

### [Specific Concern Title]

**Risk:** [high / medium / low]
**Evidence:** [file:line or measurement]
**Impact:** [what breaks or degrades if ignored]
**Fix approach:** [concrete remediation steps]

## Business / Compliance Concerns

### [Specific Concern Title]

**Risk:** [high / medium / low]
**Evidence:** [file:line or measurement]
**Impact:** [what breaks or degrades if ignored]
**Fix approach:** [concrete remediation steps]

## Tech Debt Backlog

| Priority | Area | Description | File Reference |
|----------|------|-------------|----------------|
| High     | [area] | [short description] | [file:line] |
| Medium   | [area] | [short description] | [file:line] |
| Low      | [area] | [short description] | [file:line] |
```
