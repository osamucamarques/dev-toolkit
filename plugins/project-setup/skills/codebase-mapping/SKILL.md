---
name: codebase-mapping
description: Produces a structured codebase knowledge base (7 Markdown files in docs/codebase/ + Document Map in CLAUDE.md). Use when asked to "map this codebase", "understand this repo", or generate STACK.md, ARCHITECTURE.md, CONVENTIONS.md, STRUCTURE.md, TESTING.md, INTEGRATIONS.md, or CONCERNS.md. Not for greenfield scaffolding or single-file analysis.
license: MIT
metadata:
  author: Samuel Marques
  version: 1.0.0
---

# Codebase Mapping

Produce a structured knowledge base for an unfamiliar codebase — 7 focused Markdown files
in `docs/codebase/` plus a **Knowledge Base — Document Map** section in `CLAUDE.md`. Each
file is a reusable reference that future work (bug fixes, features, migrations) can load
on-demand rather than re-exploring the whole project each time.

## The Golden Rules

These rules override everything else. They are non-negotiable.

1. **Never assume, never invent.** If you don't know, say "I don't know — I need more context." Uncertainty is always explicit.
2. **If it cost investigation, it deserves a note.** Knowledge that would take time to rediscover goes into `.notebook/`.
3. **Pointers, not copies.** Reference code by `file:function()` or `file` (L10-25). Never paste code blocks into notes.
4. **Surgical precision.** Touch only what the mission requires. Match existing style. Leave unrelated code alone.
5. **Verify against source, not memory.** Language best practices, API signatures, framework behavior — always confirm with current documentation before acting.
6. Explore using Read, Bash (find/grep), and systematic sampling.

---

## Process

Work through these phases in order. Don't skip phases — the output quality depends on actual
observation, not assumption.

---

### Phase 1: Structural Reconnaissance

```bash
# Overall layout
find . -maxdepth 3 -type f | sort

# Config and manifest files
find . -name "*.json" -o -name "*.toml" -o -name "*.gradle" -o -name "*.xml" \
  -o -name "requirements*.txt" -o -name "package.json" -o -name "Pipfile" \
  -o -name "pom.xml" | head -20

# Known issues and technical debt markers
rg "TODO|FIXME|HACK|XXX|TEMP|WORKAROUND" -n

# Entry points
fd "index|main|app|server|mod|lib" --type f | head -20
```

Identify: project root, top-level modules/packages, build/config files, and obvious entry points.

---

### Phase 2: Stack Extraction from Manifests

Read the actual dependency files (`package.json`, `build.gradle`, `pom.xml`,
`requirements.txt`, `Cargo.toml`, etc.). Record framework names and versions — do not guess
from directory names.

---

### Phase 3: Representative Code Sampling

Pick 5–10 files per category (service, repository, controller, model, test). Read them to
identify consistent patterns, naming conventions, error handling style, and architectural
decisions. Focus on consistency — note exceptions where found.

```bash
# Understand dependency patterns
rg "import.*from|require\(|use " -n | head -15

# Internal coupling
rg "\.\/|\.\.\/|@\/" -n | head -10
fd "index|mod|lib" --type f
```

---

### Phase 4: Data Flow & State Tracing

Go beyond structure — trace how data actually moves through the system.

```bash
# Transformations and parsing
rg "map|transform|convert|parse|serialize|deserialize" -A 2 -B 1

# Input/output boundaries
rg "input|output|request|response|payload" -A 1 -B 1

# Persistence and retrieval
rg "store|save|persist|cache|fetch|load|write|read" -A 1

# State management patterns
rg "state|store|reducer|action|event|dispatch|emit" -A 2
rg "useState|createStore|useReducer|observable" -A 1
```

Use findings here to populate the **Data Flow** section of `ARCHITECTURE.md`.

---

### Phase 5: Multi-Dimensional Gap Analysis

Before writing `CONCERNS.md`, examine the codebase through three lenses:

**Technical**
- Architecture patterns and anti-patterns
- Performance bottlenecks (N+1 queries, missing indexes, unbounded loops)
- Security gaps (unvalidated inputs, exposed secrets, weak auth)
- Test coverage blind spots

**Operational**
- Missing observability (no logging, no metrics, no health checks)
- Deployment fragility (hardcoded configs, environment assumptions)
- Scalability risks (stateful singletons, no pagination, in-memory queues)
- Missing error recovery (no retries, no circuit breakers, silent failures)

**Business**
- Undocumented business rules buried in code
- Compliance risks (data retention, PII handling, audit trails)
- Features that are incomplete or partially implemented

```bash
# Risk indicators
rg "unwrap|panic|todo!|unreachable!|unsafe" -n          # Rust
rg "\.get\(|force_unwrap|!\.isEmpty" -n                 # Swift / Kotlin
rg "any\b|@ts-ignore|as unknown|eslint-disable" -n      # TypeScript
rg "except:|bare except|pass$" -n                       # Python

# Security red flags
rg "password|secret|token|api_key|apikey" -i -n | grep -v "test\|spec\|mock"
rg "eval\(|exec\(|system\(|shell_exec" -n
rg "SELECT.*\+|WHERE.*\+" -n                             # Potential SQL injection
```

Only document concerns you can back with a file path or measurement. No speculation.

---

### Phase 6: Integration Catalog

Look for Feign clients, HTTP clients, Kafka consumers/producers, database configs, external
API references, webhook handlers, and background job definitions.

```bash
rg "http|fetch|axios|curl|HttpClient|RestTemplate|WebClient" -n | head -20
rg "kafka|rabbitmq|sqs|pubsub|queue|topic|consumer|producer" -i -n
rg "cron|schedule|job|worker|task" -i -n
```

---

### Phase 7: Write the 7 Files

Write each file to `docs/codebase/`. Create the directory if it doesn't exist.

Load `references/output-templates.md` for the full template and token budget for each of the 7 files. Use the templates exactly — fill in every section from what you observed; never leave placeholder text.

---

### Phase 8: Write the Knowledge Base — Document Map

After all 7 files are written, update `CLAUDE.md` with the table below. Fill in the
**Purpose** column using the actual contents of each generated file — make each entry
specific to this project, not generic. If a file was sparse (e.g., no integrations found),
reflect that honestly in the purpose cell.

The table to insert:

```markdown
| File | When to load | Purpose |
|------|--------------|---------|
| [`docs/codebase/STACK.md`](docs/codebase/STACK.md) | Before dependency work, migrations, runtime/tooling changes | Framework versions, all dependencies, testing frameworks, dev tools |
| [`docs/codebase/ARCHITECTURE.md`](docs/codebase/ARCHITECTURE.md) | Before changing flows, service boundaries, repositories, events, or migrations | Patterns, data flows, module boundaries |
| [`docs/codebase/CONVENTIONS.md`](docs/codebase/CONVENTIONS.md) | Before adding or changing any code | Naming rules, file structure, error handling style, logging |
| [`docs/codebase/STRUCTURE.md`](docs/codebase/STRUCTURE.md) | When locating a capability, config, or special directory | Full directory tree, where each domain lives, where things are configured |
| [`docs/codebase/TESTING.md`](docs/codebase/TESTING.md) | Before adding tests, fixing tests, measuring coverage, or choosing a test command | Test frameworks, base classes, container setup, coverage exclusions, known gaps |
| [`docs/codebase/INTEGRATIONS.md`](docs/codebase/INTEGRATIONS.md) | Before changing API clients, event handlers, database config, or background jobs | External services, API clients, configuration, authentication notes, event flows, background work |
| [`docs/codebase/CONCERNS.md`](docs/codebase/CONCERNS.md) | Before risky changes, refactors, performance work, security review, or planning tech debt | Security issues, outdated deps, performance risks, coverage gaps — each with evidence |
```

**Placement — check these cases in order:**

**Case A — `### Codebase Reference (\`docs/codebase/\`)` already exists in `CLAUDE.md`**
(the user ran `/project-init` before this skill — the heading is a pre-created placeholder)

- If the heading is followed immediately by the next `###` or `##` heading (empty placeholder):
  insert the table between the heading line and the next heading.
- If the heading already has a table beneath it (a previous mapping run):
  replace the existing table rows with the new ones; keep the heading intact.

**Case B — `## Knowledge Base — Document Map` exists but no `### Codebase Reference` subsection**

Insert a `### Codebase Reference (\`docs/codebase/\`)` heading followed by the table
(from above) at the top of that section — immediately after the `## Knowledge Base — Document Map`
line and its intro paragraph, before any other `###` subsection.

**Case C — Neither section exists (no `CLAUDE.md` or file has no Document Map section)**

Append to `CLAUDE.md` (create the file if absent) a `## Knowledge Base — Document Map`
section with the intro line, then a `### Codebase Reference (\`docs/codebase/\`)` heading,
then the table from above.

---

## Quality Checks

Before writing each file, ask: "Is every claim here backed by something I actually read in the
code?" Remove anything speculative. Reference real file paths wherever patterns are described.

After all 7 files and the Document Map are written, summarize for the user:
- Which files were created
- Any areas where coverage was thin (e.g., no integration tests found, config server not
  identified) so they know where to dig deeper
- Estimated token count for each file if it approached the budget
- Any high-risk concerns from `CONCERNS.md` that warrant immediate attention
