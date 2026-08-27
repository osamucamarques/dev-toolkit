---
name: plan-writer
description: 'Write a formal PLAN.md from an approved SPEC.md. Use when the user wants an implementation plan — "write the plan", "plan this out", "plan the implementation". Decomposes work into behavior-sized, test-first tasks. Not for spec authoring, bug fixes without a spec, or post-approval execution.'
license: MIT
disable-model-invocation: true
derived_from: 'obra/superpowers — writing-plans'
source_url: 'https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md'
metadata:
  author: Samuel Marques
  version: 2.1.0
---

# Plan Writer Skill

> **Attribution.** Derived from [`writing-plans`](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md) in [obra/superpowers](https://github.com/obra/superpowers) by **Jesse Vincent**, licensed under [MIT](https://github.com/obra/superpowers/blob/main/LICENSE).
> **Changes made:** Rebuilt around a spec-first, phase-gated flow with a codebase pre-read and optional Jira subtasks; retains upstream's vague-plan red-flag checklist.


Produce a formal, implementation-ready PLAN.md from an approved SPEC.md, decomposed
into behavior-sized, test-first tasks with exact file paths, fixed contracts, acceptance criteria,
and expected test output — so any engineer can execute it without codebase context.

**The plan decides what and where; the implementer decides how, inside the contracts the plan
fixed.** A plan that pre-writes every method body is an implementation transcribed into markdown:
it goes stale on first contact with the codebase, and it burns the only phase dedicated to
architecture on typing code.

---

## HARD-GATE

```
⛔ EXECUTION BLOCK
No implementation, code execution, scaffolding, or migration may begin
until the user has explicitly approved the final PLAN.md.
This gate is unconditional and cannot be waived by any inline instruction.
```

---

---

## Evidence Discipline

**Every factual claim this skill makes about the codebase must be traceable to something read
in this session.** A plan is a set of instructions an engineer will follow without re-checking;
a single invented file path, signature, or pattern propagates straight into the implementation.

| Rule | In practice |
|------|-------------|
| **Read before asserting** | Never state that a class, method, endpoint, table, config key, or test exists without having opened the file. Cite it as `path/to/File.java:45`. |
| **Label what you did not verify** | Anything you believe but did not read is written as `ASSUMPTION: <claim> — needs confirmation`, never as fact. |
| **Never generalize from convention** | "Typically Spring projects…", "this is usually handled by…", "based on my understanding" are all fabrications unless a file in *this* repo says so. |
| **Absence is a finding, not a fact** | "There is no existing X" requires a search you actually ran. Say which search: `grep -r "X" src/` returned nothing. |
| **Unknown beats invented** | If you cannot read it and cannot infer it, ask the user. One question costs a message; a wrong contract costs a task. |

Every `ASSUMPTION:` line that survives to Phase 4 must appear in the plan's `## Assumptions`
section and be raised at the Phase 6 review gate. Zero unresolved assumptions is not the goal —
zero *unstated* assumptions is.

---

## Activation

**Always use this skill** when the user references a spec file or an approved SPEC.md combined
with any of the following intent signals — even if phrased casually:

| Signal phrase | Example |
|---------------|---------|
| Explicit plan request | "write the plan", "create an implementation plan", "plan this" |
| Post-spec intent | "spec is approved, now plan it", "let's plan the implementation" |
| Pre-implementation planning | "before we start coding", "plan from the spec" |
| Task decomposition request | "break this into tasks", "give me the steps" |

**Do not activate** when the user only wants to: write a spec, fix a bug, execute an
already-approved plan, or look up ticket status.

Locate the spec file and proceed immediately to **Phase 0**.

---

## Phases

### Phase 0 — Spec Harvest

1. Locate the SPEC.md file referenced by the user. If no path is given, search `docs/specs/`
   for the most recently modified spec file and confirm it with the user before proceeding.
2. Read the full spec: goal, bounded contexts, ubiquitous language glossary, requirements,
   acceptance criteria, and open questions.
3. If the spec has unresolved open questions flagged as blockers, surface them to the user
   and ask for resolution before continuing.
4. Summarize the harvested context internally. **Do not dump raw spec content to the user.**
   Surface only what is relevant to frame the first architecture question.

---

### Phase 0.1 — Existing Plan Check

After harvesting the spec, check the filesystem before starting the interview:

1. Search `docs/plans/` for files matching `<KEY>-*.md` or any plan whose header references the same spec file.
2. If a plan file is found, present it to the user before proceeding:

   > "A plan already exists: `docs/plans/<filename>.md`.
   > Would you like to:
   > 1. **Revise** — I'll read the existing plan and update only the tasks that need to change based on the current spec state.
   > 2. **Rewrite** — I'll start fresh from the spec as it stands today.
   > 3. **View** — Show me the current plan before I decide."

   - **Revise selected:** Read the existing plan. In Phase 2 and 3, focus only on tasks that are incomplete, contradicted by the spec, or dependent on spec changes. Preserve tasks that are unaffected.
   - **Rewrite selected:** Proceed to Phase 0.5 as normal.
   - **View selected:** Display the plan content, then repeat the three-option question.

3. If no plan file is found, proceed to Phase 0.5 as normal.

---

### Phase 0.5 — Plan Language

Ask the user in which language the PLAN.md should be written. Present the options clearly:

> "Before we begin: should the plan be written in **English** or **Portuguese (pt-BR)**?
> This affects the language of task descriptions, comments, and all plan content."

Wait for the answer and store the chosen language. Apply it consistently from Phase 4 onward.
All phases before Phase 4 (interview, structure proposal) are always conducted in the same
language as the conversation with the user.

---

### Phase 1 — Scope Assessment

Read the spec and answer internally:

> *Does this spec describe a single cohesive deliverable — or multiple independent subsystems
> that could be planned and executed separately?*

**Signals that suggest a single plan:**
- One bounded context as primary owner
- Acceptance criteria share the same data model or service boundary
- Work cannot be released independently in parts

**Signals that suggest multiple plans:**
- Multiple bounded contexts with independent deployability
- Acceptance criteria that map to clearly separate features
- The spec itself was produced from a decomposition

- **Single scope → proceed to Phase 1.5.**
- **Multiple independent scopes → flag immediately.**
  Present the user with proposed sub-plans and their boundaries before asking any
  architecture questions. Each sub-plan will go through its own full cycle.

---

### Phase 1.5 — Impact Analysis

**Planning an implementation (decomposing work into tasks) and analyzing architectural impact
(mapping what will be affected) are different activities — and impact analysis comes first.**
Skipping straight to file structure and tasks is how "distributed monoliths" and silently broken
contracts happen: each individual decision looks reasonable, but no one asked what it touches
outside the files being changed.

Before any architecture question or file-level decision, answer these four questions from the
codebase and the spec's context map — asking the user only what cannot be determined by reading:

| Question | What to look for |
|----------|------------------|
| **Which Bounded Contexts are affected?** | A change that looks localized can cross context boundaries non-obviously — check the spec's Context Map (Section 2) and any code the change touches outside the primary context. |
| **Which existing contracts could break?** | APIs, published events, integrations consumed by other contexts. Read consumers, not just the producer being changed. |
| **Which architectural rules could be violated?** | Forbidden dependencies, layer separation, domain invariants that this codebase already enforces. |
| **Which risks must be mitigated before deploy?** | Data migrations, backward compatibility, rollback path. |

Present the findings as a table and confirm with the user before moving to Phase 0.7.
**Every row carries its evidence** — the file you read that supports it, or the search you ran.
A row you could not substantiate is written as an assumption, not as a finding:

```
## Impact Analysis (draft — please confirm)

| Bounded Contexts affected | Contracts at risk | Architectural rules at risk | Deploy risks | Evidence |
|---------------------------|--------------------|------------------------------|---------------|----------|
| … | … | … | … | `path/File.java:120`, `grep -r "…" src/` |
| ASSUMPTION: … — needs confirmation | … | … | … | *not verified — could not locate consumers* |
```

Do not fill a cell with a plausible-sounding risk you did not find in the code. "No contract at
risk" is a valid finding **only** when you searched for consumers and can name the search.

If a contract or rule is at risk, resolve *how* it will be protected (versioning, ACL, migration
strategy) here — before Phase 2 — not as an afterthought discovered mid-task. This table becomes
the plan's `## Impact Analysis` section (see `references/plan-template.md`).

---

### Phase 0.7 — Codebase Pre-Read

Before asking any architecture questions, read the codebase:

1. Identify the most relevant files for this spec: controllers, services, repositories, domain classes, and existing tests in the relevant bounded context.
2. Internally answer as many Architecture Interview questions (Phase 2 question bank) as possible from direct reading — entry point, persistence layer, test framework, existing patterns.
3. Keep two explicit lists as you read:
   - **Verified** — answer + the `path:line` that proves it.
   - **Unverified** — the question you could not close by reading, and why (file absent, pattern
     inconsistent, decision not encoded anywhere).
4. Only ask the user about the **Unverified** list. Never let an unverified item silently become
   a verified one because it sounds right.

**Principle:** Do not ask for information you can obtain yourself. Every avoided question reduces friction and respects the user's time.

**Counter-principle, equally binding:** do not *invent* information you failed to obtain. The
pre-read exists to shrink the interview, not to replace it with guesses. An item that stayed
unverified and was never asked about becomes an `ASSUMPTION:` line in the plan — see
**Evidence Discipline**.

---

### Phase 2 — Architecture Interview

**Goal:** gather enough context to make concrete, correct file-level decomposition decisions.

**Rules:**
- One question per message. Never batch questions.
- Use only canonical terms from the spec's ubiquitous language glossary.
- If a question can be answered by reading the codebase, read the codebase instead of asking.
- Stop when you have enough to produce an accurate file structure and task breakdown.

**Question bank (adapt to the spec — do not follow mechanically):**

| # | Area | Sample framing |
|---|------|----------------|
| 1 | Tech stack | "Which framework and language does this feature live in?" |
| 2 | Existing patterns | "Is there an existing pattern in this codebase I should follow for this type of feature?" |
| 3 | Entry point | "Where does execution start — controller, event listener, scheduled job?" |
| 4 | Persistence | "Which persistence layer is involved and what's the ORM/query style used here?" |
| 5 | Test framework | "Which test framework and assertion library should I use?" |
| 6 | Integration points | "Which external systems or internal services does this feature call?" |
| 7 | Constraints | "Are there performance, security, or migration constraints I must plan around?" |
| 8 | Scope boundary | "What is explicitly out of scope for this plan?" |
| 9 | Contract risk | "Is this contract (API/event) consumed by other bounded contexts? If its shape changes, who breaks?" |
| 10 | Architectural rules | "Does this change cross a dependency or layering rule this codebase already enforces?" |

---

### Phase 3 — File Structure Proposal

Before writing tasks, map every file that will be **created** or **modified** and state
its single responsibility. Present this as a table and wait for user confirmation.

**Rules:**
- One responsibility per file. If a file does two things, split it.
- Files that change together should live together — split by responsibility, not by layer.
- In existing codebases, follow established patterns. Only propose restructuring if
  a file being modified has grown unwieldy.
- Every file listed here must appear in at least one task in Phase 4.

```
## File Structure (draft — please confirm)

| File | Action | Responsibility |
|------|--------|----------------|
| `src/exact/path/to/NewClass.java` | Create | … |
| `src/exact/path/to/ExistingClass.java:45-80` | Modify | … |
| `src/test/exact/path/to/NewClassTest.java` | Create | … |
```

Ask:
> "Does this file breakdown look right? Any files missing or responsibilities that should
> be merged or split further?"

Wait for confirmation before proceeding to Phase 3.5.

---

### Phase 3.5 — Architecture Gate

**Decomposition into tasks is not architecture.** Phase 1.5 mapped what the change *touches*;
this phase decides *how the change is shaped*. Both come before tasks, because a task list
written without these decisions forces the implementer to make them one green bar at a time —
which is how a shape nobody chose gets built.

Four decisions must be settled here:

| Decision | What to settle |
|----------|----------------|
| **Invariant ownership** | Which type owns each business rule. Two types enforcing the same invariant is a defect, not redundancy. |
| **Dependency direction** | What may depend on what. Name the architectural rule this respects — and if the change needs an exception, say so here. |
| **Contract shape** | Public signatures, event payloads, API shapes, and their versioning/compatibility strategy. |
| **Failure & transaction boundary** | Where errors surface to the caller, what is atomic, what is retryable. |

#### 3.5a — Present options, do not announce a verdict

**Your confidence is not the user's approval.** For every decision above where more than one
shape is genuinely viable in this codebase, present **2–3 concrete options** — never a single
choice framed as obvious. Recommend one, with reasoning. The user decides.

```
### Decision: <e.g. Invariant ownership for confirmation restrictions>

| Option | Summary | Pros | Cons | Effort | Risk |
|--------|---------|------|------|--------|------|
| **A** (recommended) | … | … | … | low/med/high | low/med/high |
| **B** | … | … | … | … | … |
| **C** | … | … | … | … | … |

**Recommendation:** A — <one or two sentences of reasoning grounded in the codebase, with the
`path:line` that supports it.>
```

Rules for the options:

- Each option must be a shape someone could actually build here — no strawman placed to make
  the recommendation look better. If you cannot state honest Pros for an option, it is a
  strawman: drop it and present the remaining ones.
- Options must be **materially different**, not the same design with a renamed class.
- Effort and Risk are your estimate; say so. Do not present them as measurements.
- If the decision genuinely has only one viable shape — the codebase already enforces it, or
  the spec fixed it — say that explicitly and cite what fixes it, instead of manufacturing
  alternatives. "Only one option, because `ArchUnitTest.java:34` forbids the alternative" is a
  legitimate answer; silence is not.

Ask one decision at a time. Do not batch four decisions into one message and ask for a single
approval — a batched approval hides the one the user would have pushed back on.

#### 3.5b — Record the outcome

Once the user has chosen each decision, assemble the confirmed table:

```
## Architecture Decisions (confirmed)

| Decision | Choice | Why | Alternative rejected |
|----------|--------|-----|----------------------|
| … | … | … | … |
```

Record the alternative the **user** rejected, not one you invented after the fact. A decision
with no rejected alternative was not a decision — it was a default, and defaults are where
architecture erodes.

This table becomes the plan's `## Architecture Decisions` section. Every contract settled here
appears verbatim in the task that implements it, so no task has to invent one.

Wait for confirmation before proceeding to Phase 4.

---

### Phase 4 — PLAN.md Authoring

Write the plan using the structure in `references/plan-template.md`. Apply the language chosen in Phase 0.5 consistently. Use only canonical terms from the spec's ubiquitous language glossary — never use retired aliases.

Load `references/plan-template.md` before writing — it contains the exact Plan Document Header and Task Structure templates that every plan must follow.

Collect every `ASSUMPTION:` accumulated since Phase 0.7 into the header's `## Assumptions` table,
with what it affects and how to resolve it. An assumption left out of that table does not stop
being an assumption — it just stops being reviewable, and the executor will read it as fact.

#### Task Granularity

**A task is one cohesive unit of behavior** — one aggregate's rule set, one endpoint, one
migration, one collaboration. The test: can you state the task's Intent in a single sentence?
If it takes two, split it. If it takes half a sentence, merge it.

Within a task, the steps are the verification cycle, not a keystroke log:

- Design pass (Tier 2 only — settle the contract, no method bodies)
- Write the failing test for one acceptance criterion
- Run it and confirm it fails for the right reason
- Implement that criterion
- Run the test and the suite — confirm green
- Repeat for each remaining AC in the task
- Commit

Assign a **test-first tier** to every task (see `intent-ops:tdd-guide`): Tier 1 for domain
rules, validation, calculations, state transitions, and bug fixes; Tier 2 when the task
introduces a new component or boundary; Tier 3 only for wiring and pure delegation. Default to
Tier 1 and justify anything else in the task.

Never collapse "write the test" and "run it to see it fail" into one step — the observed red is
the gate the whole cycle rests on.

#### No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures**:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without naming each test and its assertion)
- "Similar to Task N" (repeat the code — the engineer may read tasks out of order)
- A task with no Intent line, no test-first tier, or no acceptance criteria listed
- A task that defines or changes a signature, event, or API shape without a Contract block
- References to types, functions, or methods not defined in any task or contract
- A claim about existing code with no `path:line` behind it — including "the existing pattern is X"
- An unverified belief written as fact instead of as an `ASSUMPTION:` line
- An architecture decision the user never chose between options for

These are **not** plan failures — do not add them:
- Method bodies for behavior the AC and the contract already determine
- Test bodies (name the test and state the assertion instead)
- Boilerplate the codebase already has an established pattern for

---

### Phase 5 — Self-Review Gate

After authoring, perform an internal review before presenting to the user.
Load `references/plan-reviewer-prompt.md` for the full review checklist.

| Check | Question |
|-------|----------|
| Impact analysis done first | Was Phase 1.5 completed and its table included in the plan before file structure and tasks were decided? |
| Architecture gate done | Was Phase 3.5 confirmed, with a rejected alternative named for each decision, before tasks were written? |
| Options presented | For each architecture decision with more than one viable shape, were 2–3 options presented with Pros/Cons/Effort/Risk and a recommendation — and did the user choose? |
| Evidence | Does every claim about the existing codebase carry a `path:line` or a named search? Any sentence that starts "typically", "usually", or "presumably" is a defect — verify it or demote it to `ASSUMPTION:`. |
| Assumptions surfaced | Is every unverified item collected in `## Assumptions`, and is that section non-empty whenever the pre-read left questions open? |
| Phantom references | Does every type, method, file, and config key named in a task exist in the codebase (cited) or get created by an earlier task in this plan? |
| Spec coverage | Can you point to a task for every spec requirement? List any gaps. |
| Placeholder scan | Any pattern from the "No Placeholders" section above? Fix them. |
| Type consistency | Do method signatures and type names used in later tasks match earlier task definitions? |
| File coverage | Every file from the Phase 3 structure appears in at least one task? |
| Language | Is the chosen language applied uniformly? No mixed-language sentences. |
| Ubiquitous language | Are only canonical glossary terms used — no retired aliases? |
| Task granularity | Can each task's Intent be stated in one sentence? Split or merge otherwise. |
| Tier assignment | Does every task declare a test-first tier, with a justification for anything other than Tier 1? |
| Contract coverage | Does every task that changes a signature, event, or API shape carry a Contract block traceable to Phase 3.5? |
| AC traceability | Does every task list the spec ACs it covers, and does every AC appear in some task? |
| Red step intact | Is "write the test" separate from "run it and confirm it fails" in every task? |
| YAGNI | Any unrequested scope creep? Remove it. |

Fix all issues before presenting.

---

### Phase 6 — User Review Gate

Present the completed plan inline and ask:

> "Plan complete. Please review the tasks, file structure, and steps.
>
> **Assumptions I could not verify:** [list them, or state that there are none.] Each one is
> recorded in the plan's `## Assumptions` section — if any is wrong, the tasks it affects change.
>
> Let me know if anything needs to change before we finalize.
> **Execution is blocked until you approve.**"

Never present a plan while silently holding an unverified belief you did not list here. The
review gate is the last cheap place to correct one.

Wait for explicit approval. If changes are requested, re-run Phase 5 after edits.

---

### Phase 7 — Save & Jira Sync (Post-Approval)

Once approved:

1. Save the plan to the filesystem:
   - Path **with a Jira/spec key**: `docs/plans/<SPEC-KEY>-<kebab-case-title>.md`
   - Path **without a key** (spec had no Jira ticket): `docs/plans/<kebab-case-title>.md` —
     match the naming of the source spec file.
   - Create the directory if it does not exist.
   - Confirm the path to the user after saving.

2. Offer to update the linked spec to reference this plan:
   - Add a `## Implementation Plan` section at the end of the SPEC.md pointing to the plan file.

3. **Only if the spec is linked to a Jira user story**, ask whether to create the plan tasks as
   Jira subtasks (skip this step entirely when there is no Jira key — the plan stands on its own):

   > "Do you want to create the **N tasks** from this plan as subtasks in Jira user story **[SPEC-KEY]**?
   > Each task will become a subtask with the plan task name as its summary."

   If accepted:
   - Call `Atlassian:getJiraProjectIssueTypesMetadata` to identify the subtask issue type for the project.
   - For each plan task (Task 1 … Task N), call `Atlassian:createJiraIssue` with:
     - `issuetype`: subtask type resolved above
     - `parent`: the user story key (e.g. `PROJ-1234`)
     - `summary`: the task name from the plan (e.g. `Task 1: TenantService validation`)
   - Collect the created subtask keys in order (e.g. `PROJ-1235`, `PROJ-1236`, …).
   - Build the **task ID mapping**: `Task N → JIRA-SUBTASK-KEY`
   - Confirm the created subtasks to the user with a table:

     | Task | Jira Subtask |
     |------|-------------|
     | Task 1: … | PROJ-1235 |
     | Task 2: … | PROJ-1236 |

   Store this mapping — it is passed to the executor in Phase 8.

---

### Phase 8 — Transition to Execution

After saving, offer the user a choice of execution approach:

> "Plan saved to `docs/plans/<filename>.md`. Two execution options:
>
> **1. Task Runner (recommended)** — `intent-ops:task-runner`
> Fresh subagent per task, spec compliance review + code quality review after each task.
> Higher quality, catches issues early.
>
> **2. Inline Execution** — `intent-ops:plan-executor`
> Execute tasks in this session, step-by-step, with checkpoints.
> Use when subagents are not available or you prefer a single session.
>
> Which approach?"

Both `task-runner` and `plan-executor` have model-invocation disabled — they must be run by
the user, not called by this skill.

**If Task Runner chosen:**
- Tell the user to run `/intent-ops:task-runner`, mentioning the saved plan path, the Jira story
  key (if any), and task ID mapping (if subtasks were created) so they can pass that context along.

**If Inline Execution chosen:**
- Tell the user to run `/intent-ops:plan-executor`, mentioning the same context.

Do NOT take any implementation action before the user chooses an execution approach, and do
NOT attempt to invoke either skill yourself — surface the command and stop.

---

## Key Principles

- **Impact before decomposition.** Analyze what the change affects — bounded contexts, contracts, architectural rules, deploy risk — before deciding what files or tasks to create. Doing this in the opposite order turns retrofitting into the plan's design process.
- **Architecture before decomposition.** Invariant ownership, dependency direction, contracts,
  and failure boundaries are settled in Phase 3.5 — not discovered by the implementer mid-task.
- **Concrete where it decides something.** Exact paths, exact contracts, exact commands, exact
  expected output. Not exact method bodies — the plan fixes the shape, the implementer fills it.
- **One question at a time.** Never overwhelm the user.
- **Observed red always.** Every behavior gets a test that was run and seen to fail before the
  code satisfying it existed — every task, every time. Tier choice sets the step size, never
  whether the red happens.
- **Approval required.** The HARD-GATE is unconditional.
- **Spec is the source of truth.** Every requirement in the spec must map to a task.
- **Ubiquitous language.** Use only canonical terms from the spec's confirmed glossary.
- **DRY, YAGNI, frequent commits.** No gold-plating, no unrequested abstractions.
- **Language consistency.** Apply the chosen language uniformly — never mix within a document.
- **Evidence or nothing.** Every statement about the codebase is backed by a file you opened or a
  search you ran. What you did not verify is labelled, not smoothed over.
- **Options, then a recommendation, then the user's call.** Presenting one shape as inevitable is
  how the plan quietly becomes the author's preference instead of the team's decision.

---

## Common Rationalizations — All Wrong

| Excuse | Why it fails |
|--------|-------------|
| "This is standard Spring/JPA, I don't need to open the file" | Standard elsewhere ≠ present here. Repos deviate. Open it. |
| "The spec implies the design, so I can skip the options" | Implied ≠ decided. A spec fixes behavior, not shape. Present options. |
| "One approach is clearly best — alternatives would just confuse them" | If alternatives confuse, the requirements are unclear. Clarify, don't conceal. |
| "I'll batch the four architecture decisions into one approval" | A batched approval hides the one they'd have rejected. One at a time. |
| "I'll mark it TBD and the implementer will figure it out" | The implementer resolves it one green bar at a time — that's how a shape nobody chose gets built. |
| "I couldn't find the consumer, so there probably isn't one" | Absence of evidence written as evidence of absence. Name the search or write `ASSUMPTION:`. |
| "Reading the whole codebase costs too much context" | Reading the *relevant* files is Phase 0.7. Skipping it doesn't save context — it moves the cost to rework. |
| "Listing assumptions makes the plan look weak" | An unstated assumption doesn't stop existing; it just stops being reviewable. |
| "The user already approved something similar" | Similar isn't this. Approval doesn't transfer across artifacts. |
| "I'll write the method bodies to be helpful" | The plan fixes shape; bodies go stale on first contact and burn the architecture phase on typing. |

---

## Red Flags — STOP and Reassess

If you catch yourself thinking any of these, you are about to violate the methodology:

- "Typically, in codebases like this…"
- "Based on my understanding of the framework…"
- "It's safe to assume the repository layer…"
- "I'll note the exact path later"
- "Let me just quickly propose the structure"
- "The obvious choice is…"
- "They'll probably be fine with this, I'll keep going"
- "I'll confirm this at the final review instead"

**Every one of these means: stop. Read the file, run the search, or ask the question.**

---

## Examples

### Example 1: Single-scope plan

User says: "The spec is approved — can you write the implementation plan for PROJ-1234?"
Actions: Phase 0 (locate and read SPEC.md) → Phase 0.5 (plan language) → Phase 1 (single scope confirmed) → Phase 1.5 (impact analysis — bounded contexts, contracts, architectural rules, deploy risks, confirm) → Phase 0.7 (codebase pre-read, answer architecture questions from code) → Phase 2 (architecture interview, only what the codebase didn't answer) → Phase 3 (file structure proposal, confirm) → Phase 3.5 (architecture gate — 2–3 options per decision with Pros/Cons/Effort/Risk, one decision per message, user chooses) → Phase 4 (author PLAN.md) → Phase 5 (self-review) → Phase 6 (HARD-GATE: present and wait for explicit approval) → Phase 7 (save to `docs/plans/PROJ-1234-*.md`, offer spec update).
Result: PLAN.md on disk. No execution until the user explicitly approves.

### Example 2: Multi-scope decomposition

User says: "Write the plan for the spec that covers auth and billing."
Actions: Phase 1 detects 2 independent scopes. Present decomposition table with boundaries and plan order. Wait for approval before starting the first architecture interview cycle.
Result: Two separate plans; one per bounded context.

### Example 3: Wrong trigger — do not activate

User says: "Implement the plan from PROJ-1234."
Action: Do not activate. The user wants execution, not planning. Intent to produce a plan artifact is required.
