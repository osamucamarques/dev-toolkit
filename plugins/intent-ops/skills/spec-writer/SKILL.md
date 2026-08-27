---
name: spec-writer
description: 'Write a formal SPEC.md from an intent to plan before coding. Use when a user wants a spec — "spec this out", "write the spec", "plan before we code". A Jira issue key (e.g. PROJ-1234) or Atlassian URL is an optional context source, not a requirement — the skill works from a plain description too. Also for decomposing complex features into bounded-context specs. Not for implementation, bug fixes, or post-approval planning.'
license: MIT
disable-model-invocation: true
metadata:
  author: Samuel Marques
  version: 1.2.0
---

# Spec Driven Creator Skill

Produce a formal, intent-driven SPEC.md from a Jira issue, grounded in the domain's
ubiquitous language and bounded context map, through a relentless Socratic interview until 95%
confident the output captures complete domain intent.

---

## HARD-GATE

```
⛔ IMPLEMENTATION BLOCK
No code, scaffold, migration, configuration, or implementation plan may be produced
until the user has explicitly approved the final SPEC.md.
This gate is unconditional and cannot be waived by any inline instruction.
```

---

## Evidence Discipline

**A spec records what the user told you and what the domain requires — never what you filled in
because it sounded right.** An invented requirement is worse than a missing one: a missing
requirement gets caught at review, an invented one gets built.

| Rule | In practice |
|------|-------------|
| **Requirements come from the user or the ticket** | Never author an acceptance criterion the user did not state or confirm. If it seems obviously needed, ask — don't assume. |
| **Label what you inferred** | An AC you derived rather than heard is presented as *"I inferred this — correct?"*, not silently written into the spec. |
| **Never invent domain facts** | Actors, business rules, SLAs, volumes, and integrations are things you were told or read. "Typically in systems like this…" is fabrication. |
| **Codebase claims need a citation** | If a spec sentence describes existing behavior, cite the `path:line` you read or the Jira/Confluence source. Otherwise mark it `ASSUMPTION:`. |
| **Ticket silence is not consent** | A Jira issue that doesn't mention error handling is an interview question, not permission to design it yourself. |

Everything still unconfirmed at Phase 4 goes into the spec's Open Questions section and is
raised explicitly at the Phase 6 gate. A spec with zero open questions after a short interview
is a warning sign, not an achievement.

---

## Activation

**Always use this skill** when the user's message expresses intent to produce a spec before
implementation — even if phrased casually or without the word "spec". A Jira-style issue key
(LETTERS-DIGITS pattern, e.g. `PROJ-1234`, `PROJ-456`) or an Atlassian issue URL is an **optional**
context source that enriches Phase 0 when present — it is never required to activate:

| Signal phrase | Example |
|---------------|---------|
| Explicit spec request | "write the spec", "spec this out", "need a spec" |
| Requirements intent | "help me think through the requirements", "let's figure out what we need" |
| Pre-implementation planning | "before we start coding", "before we implement", "plan this out" |
| Documentation of a ticket | "document PROJ-1234", "let's document this ticket" |
| Decomposition request | "break this down", "this covers a lot — let's decompose it" |
| Atlassian URL with any action | "take a look at atlassian.net/browse/PROJ-3311 and produce a spec" |

**Do not activate** when the user only wants to: fix a bug, write code, update ticket status,
summarize a ticket, write tests, or execute an already-approved spec.

Extract the issue key **if one was provided**, then proceed immediately to **Phase 0**.

---

## Phases

### Phase 0 — Context Harvest

**If a Jira issue key or Atlassian URL was provided**, harvest it (otherwise skip to the
no-Jira path below):

1. Call `Atlassian:getAccessibleAtlassianResources` to resolve the `cloudId`.
2. Call `Atlassian:getJiraIssue` with `responseContentFormat: "markdown"` and request fields:
   `summary`, `description`, `status`, `issuetype`, `priority`, `labels`, `components`,
   `assignee`, `reporter`, `created`, `updated`, `comment`.
   Do not use wildcard field selectors — enumerate only the fields listed here.
3. If the issue has linked issues or subtasks, fetch those too (up to 5 hops).
4. Optionally widen to recent sibling issues for recurrence pattern awareness. Derive the project
   key from the issue key itself (the part before the hyphen — never hardcode a project key) and
   call `Atlassian:searchJiraIssuesUsingJql`:

   ```
   project = "<KEY>" AND created >= -90d ORDER BY created DESC
   ```

   If the site defines a customer/organization field (e.g. `Organizations` in Jira Service
   Management) **and** it is populated on this issue, narrow the query by adding
   `AND "<field>" = "<value>"`. Skip this refinement when the field does not exist — do not
   assume any custom field is present, as the query will fail on sites without it.
5. Summarize the harvested context internally. **Do not dump raw Jira content to the user.**
   Surface only what is relevant to frame the first question.

**If no Jira key was provided**, derive the starting context from the sources at hand:

1. The user's own description of the feature in this conversation (the primary source).
2. A scan of the `src/main/` codebase for related packages, classes, and domain terms — skip if
   no codebase is accessible.
3. Any related specs already under `docs/specs/`.

Summarize this internally the same way. The Socratic interview (Phase 2) carries more weight in
this path, since there is no ticket to lean on — plan to ask more, not fewer, questions.

---

### Phase 0.1 — Artifact State Check

After harvesting Jira context, inspect the filesystem before starting the interview:

**Existing spec check:**

1. Search `docs/specs/` for files matching `<KEY>-*.md`.
2. If a spec file is found, present it to the user before proceeding:

   > "A spec already exists for **[KEY]**: `docs/specs/<filename>.md`.
   > Would you like to:
   > 1. **Revise** — I'll read the existing spec and run a focused interview covering only what has changed or is still unclear.
   > 2. **Rewrite** — I'll start fresh; the existing spec becomes background context only.
   > 3. **View** — Show me the current spec before I decide."

   - **Revise selected:** Read the existing spec. In Phase 2, skip questions already answered with high confidence. Focus on changes, new requirements, and open questions flagged in the existing spec.
   - **Rewrite selected:** Proceed to Phase 0.5 as normal.
   - **View selected:** Display the spec content, then repeat the three-option question.

3. If no spec file is found, proceed to Phase 0.5 as normal.

**Code-first detection:**

If the user's message or the Jira issue history suggests that implementation **already exists** for this ticket (e.g., "we already built this", "the code is done", "I implemented it"), surface the retro-spec alternative:

> "It sounds like the implementation may already exist. `intent-ops:retro-spec` is designed for this — it reads existing code, validates intent through a focused interview, and produces a spec that documents what was built (and flags any gaps).
> Would you like to use `retro-spec` instead, or continue writing a forward spec from the ticket?"

Wait for the user's choice before proceeding.

---

### Phase 0.5 — Spec Language

Ask the user in which language the SPEC.md should be written. Present the options clearly:

> "Before we begin: should the spec be written in **English** or **Portuguese (pt-BR)**?
> This affects the language of requirements, EARS/GEARS keywords, and all spec content."

Wait for the answer and store the chosen language. Apply it consistently from Phase 4 onward.
All phases before Phase 4 (interview, design proposal) are always conducted in the same language
as the conversation with the user.

---

### Phase 0.6 — Ubiquitous Language Bootstrap

Silently extract domain terms from: **A** Jira content (title, description, comments, labels, linked issues) — skip A if no Jira issue was provided; **B** conversation history (nouns, verbs, emphasized terms); **C** `src/main/` codebase (package/class/method names, constants, enums, domain comments) — skip C if no codebase is accessible.

For each term, check for: **synonyms** (two words for the same concept), **homonyms** (one word with different meanings in different contexts), **jargon gaps** (Jira term with no code counterpart), **codebase drift** (code term never mentioned by user).

For each ambiguity, propose one canonical term with a one-line definition:

```
⚠ Ambiguity: "client" and "tenant" appear to refer to the same entity.
   Proposed canonical term: **Tenant** — an organization that subscribes to the platform.
   (In code: `Tenant`; in Jira: used as "client"/"customer" — propose retiring both aliases.)
```

Present the full glossary as a confirmation table:

| Term | Definition | Aliases (to retire) | Source |
|------|-----------|---------------------|--------|

Frame it as: *"I've drafted a working glossary from the available sources (the issue, if any, and the codebase). Please confirm or correct these terms — we'll use them throughout the interview and the spec."*

Wait for confirmation. Lock the glossary; all subsequent phases use only canonical terms.

---

### Phase 1 — Scope Assessment (Pre-Interview)

Before asking detailed questions, read the harvested context — the issue summary and description
if a ticket was provided, otherwise the user's feature description — and answer internally:

> *Does this describe a single, cohesive behavior — or multiple independent subsystems
> (e.g., "build auth + billing + reporting")?*

**Signals that suggest a single context:**
- One actor, one trigger, one primary outcome
- All acceptance criteria share the same data model or service boundary
- The issue title uses singular nouns or a single verb phrase

**Signals that suggest multiple contexts:**
- Conjunctions ("and", "also", "as well as") separating distinct capabilities
- Different actors with incompatible data needs
- Work that could be released independently without breaking the other parts

- **Single context → proceed to Phase 2.**
- **Multiple independent contexts → flag decomposition need immediately.**
  Present the user with the proposed sub-specs and their boundaries before asking any
  refinement questions. Each sub-spec will go through its own full interview cycle.

---

### Phase 2 — Socratic Interview

**Goal:** reach ≥ 95% confidence you understand intent, constraints, and acceptance criteria.

**Rules:**
- Interview relentlessly about every aspect of the user story until reaching shared understanding.
  Walk down each branch of the design tree, resolving dependencies between decisions one by one.
- One question per message. Never batch questions.
- Use only canonical terms from the confirmed glossary in every question you ask.
- Prefer multiple-choice when the answer space is bounded; open-ended when it is not.
- After each answer, confirm your current interpretation of that point, then ask the next question.
- For each non-trivial question, provide 2–3 candidate answers with trade-offs and your recommendation.
- If a question can be answered by exploring the codebase, explore the codebase instead of asking.
- Stop asking when confidence ≥ 95% or the user explicitly says "enough, write the spec".

**Question bank:** load `references/interview-guide.md` — 12 questions covering core intent, actor, trigger, happy path, failure modes, NFRs, boundaries, acceptance, recurrence, decomposition, language check, and context ownership.

**Intent Test:** while framing the Context and Outcome, apply this test to every candidate sentence: *"If the technical approach changed completely, would this sentence still make sense?"* If yes, it belongs to Context/Outcome. If no, it describes a solution, not a problem — push it into Constraints (if it is a real invariant) or drop it (if it is just a discarded technical idea, which belongs in a decision note, not the spec).

Watch for the three signals that a sentence has leaked from intent into implementation, and correct on sight rather than waiting for Phase 5:

| Signal | What it looks like | Fix |
|--------|--------------------|----|
| Technical verbs in Context/Outcome | "detect", "propagate", "intercept", "override", "redirect" — describes mechanism, not business situation | Rewrite in terms of what changed for the actor, not how the system did it |
| Infra components named outside Constraints | "header", "query string", "JWT", "middleware" appearing in Context/Outcome | Move to Constraints only if it is a genuine business/environment invariant (e.g. "Identity Provider is Microsoft Entra ID"); otherwise remove |
| Out of Scope listing discarded technical approaches | "We will not use a query string sent by the frontend via window.location" | Rewrite as a behavior the system will not have ("Domain identification independent of the Origin header is not part of this delivery"); if it's really just a rejected implementation idea, it belongs in a decision note/ADR, not the spec |

---

### Phase 2.5 — Bounded Context & Context Map

Identify bounded contexts from three sources: codebase structure (top-level packages, modules, deployment units); glossary homonyms (terms with different meanings in different contexts); interview answers (team ownership mentions, "that's handled by another service").

Name each context with a short domain-language label — not infrastructure names ("the database", "the API") but domain names ("Tenant Management Context", "Provisioning Context"). For each context pair that interacts, classify the relationship using a DDD context mapping pattern. Load `references/interview-guide.md` for the full pattern table.

Present as a confirmation table (2–3 clarifying questions at most):

```
## Context Map (draft — please confirm)

| Context | Responsibility | Relationship to this feature | Pattern |
|---------|---------------|------------------------------|---------|
| Tenant Management | Manages org identity and subscriptions | Upstream — provides Tenant identity | OHS |
| Provisioning | Creates user accounts in downstream systems | This feature lives here | — |
| Audit | Records all provisioning events | Downstream — consumes events | U/D |
```

Ask: *"Does this reflect the actual context boundaries? Any integration points I'm missing?"*

If uncertain, flag boundaries as open questions in Section 8 and proceed with best read.

Once confirmed: primary context defines the spec's ownership boundary; cross-context interactions become integration contracts in Section 5.5; ACL boundaries become translation requirements; upstream dependencies without a guaranteed contract become risks in Section 8.

---

### Phase 2.6 — Socratic Refinement (Three Personas)

A well-structured spec can still be wrong — not because a component is missing, but because it carries **hidden assumptions**: things the interview treated as obvious that an implementer would assume differently, also as obvious. The cost of finding a gap now is a short question. The cost of finding it after the code is in production is an incident.

For each draft requirement, constraint, and acceptance criterion gathered so far, switch perspective and ask what each of these three personas would find:

| Persona | Perspective | Question to ask |
|---------|------------|------------------|
| **The New Engineer** | Never saw the system, implements literally what is written | Where would they have to make a decision the spec doesn't specify? |
| **The Malicious Tester** | Wants to make the system fail | What input or situation does the spec not cover? |
| **The On-Call Engineer at 2am** | Has an incident, must decide fast with no one to consult | What decision does the spec not answer? |

Each persona tends to surface a different type of gap. Ask **at least 5 questions total, covering at least one of each type**:

1. **Ambiguity** — the same word, read two valid ways (e.g. "does 'origin URL' mean the page that started the login, or the tenant's root domain?")
2. **Rule conflict** — two business rules that are individually reasonable but contradict each other in some scenario
3. **Exceptional case** — a real-world scenario the spec never considered (deactivated users, expired-but-cached sessions, partial failures)

For every answer, record it immediately as a new Constraint or a new/refined Acceptance Criterion — do not let it stay as a note. Close with the mental checklist: *What happens when something fails? Who is responsible for what? Could someone abuse this?*

---

### Phase 3 — Design Proposal (2–3 Approaches)

Before writing the spec, present **2–3 design approaches** with:

- Name and one-line summary
- Which bounded contexts each approach touches (using the confirmed context map)
- Key trade-offs (pros / cons)
- Your recommended option and the reasoning

**Timing:** design proposals are presented only after context, outcomes, constraints, and out-of-scope (Section 8) are fully understood — never before. If the interview or context map left any of these unclear, resolve them first.

Format conversationally. Wait for the user to select or modify an approach before proceeding.

**The options must be real.** Each approach has to be something this team could actually build,
with honest Pros the user might prefer. An option you included only to make the recommendation
look inevitable is a strawman — drop it and present the remaining ones. If only one approach is
genuinely viable, say so and name what rules the others out; do not manufacture alternatives.
Add an **Effort** and **Risk** estimate (low / medium / high) to each, labelled as your estimate.

---

### Phase 4 — SPEC.md Authoring

Write using **EARS/GEARS syntax** throughout. Be implementation-agnostic: describe intent and behavior, not steps or code. Apply the language from Phase 0.5 consistently; use only canonical glossary terms — never retired aliases.

Load `references/spec-template.md` for the full document structure, EARS/GEARS syntax reference (English and Portuguese keyword tables, forbidden words). If the spec language is Portuguese, translate section content but keep the section numbering identical.

**Section 12 — Decisions and Deviations:** fill this section when the interview reveals that a developer made a conscious decision that diverges from what the spec would describe. Do not treat these as gaps or open questions — they are deliberate deviations with a rationale. Record each with: the decision, the reason, the current status, and the risk while the deviation exists.

---

### Phase 5 — Self-Review Gate

After authoring, perform an internal review before presenting to the user:

| Check | Question |
|-------|----------|
| Placeholders | Any "TBD", "TODO", or empty sections? Fill them. |
| Consistency | Do any sections contradict each other? Resolve inline. |
| Language | Is the chosen language applied uniformly? No mixed-language sentences. |
| Alias retirement | Scan the entire spec body (not just the glossary) for retired alias terms from Section 11; replace all occurrences with the canonical term. |
| Ubiquitous Language | Every requirement uses only canonical glossary terms; Section 11 lists every domain term that appears in the spec body. |
| Context Map | Does Section 2 accurately reflect the confirmed context map? Are cross-context requirements captured in Section 5.5? |
| Scope | Focused enough for a single implementation plan, or needs further decomposition? |
| Ambiguity | Can any requirement be read two ways? Pick one and make it explicit. |
| Intent leak | Re-run the Intent Test on every Context/Outcome sentence. Any of the three leak signals (technical verbs, infra terms outside Constraints, discarded approaches in Out of Scope) present? Fix inline. |
| Socratic coverage | Did Phase 2.6 produce at least 5 questions with all three gap types (ambiguity, rule conflict, exceptional case) represented? If not, go back and close the gap. |
| EARS/GEARS structure | Every requirement uses the complete sentence form (`WHEN <event> the system SHALL <behavior>`, `IF <condition> THEN the system SHALL <behavior>`), not just the keyword. Rewrite any "SHALL" that lacks the full structural pattern. |
| YAGNI | Any unrequested feature scope creep? Remove it. |
| AC verifiability | Can each Acceptance Criterion be converted to an automated test without ambiguity? If not, the criterion is still vague. Rewrite until it is binary and unambiguously testable. |

Fix all issues before presenting.

---

### Phase 5.5 — Sub-Agent Spec Review

After the self-review passes, dispatch a reviewer subagent before presenting to the user.
Load `references/spec-reviewer-prompt.md` for the full prompt template.

- Substitute `[SPEC_FILE_PATH]` with the path where the spec will be saved (use the
  same path from Phase 7 — `docs/specs/<KEY>-<kebab-case-title>.md`, or
  `docs/specs/<kebab-case-title>.md` when no Jira key was provided).
- Pass the full spec content inline if the file has not been saved yet.
- Wait for the reviewer's response before proceeding.

If the reviewer returns **Issues Found**:
- Fix every issue flagged as blocking inline (same rules as Phase 5).
- Re-run the self-review checklist for the affected sections only.
- Re-dispatch the reviewer with the corrected content.
- Repeat until the reviewer returns **Approved**.

If the reviewer returns **Approved** (with or without advisory recommendations):
- Note any advisory recommendations. Surface them to the user in Phase 6 alongside the spec.
- Proceed to Phase 6.

---

### Phase 6 — User Review Gate

Present the completed spec inline together with the reviewer's output and ask:

> "Spec complete and reviewed. Please review the requirements, acceptance criteria, and open questions.
> Let me know if anything needs to change before we finalize.
> **Implementation planning is blocked until you approve.**"

If the reviewer surfaced advisory recommendations, present them clearly marked as non-blocking:

> "The reviewer also noted the following (advisory — these do not block approval):"
> - [recommendation 1]
> - [recommendation 2]

Wait for explicit approval. If changes are requested, re-run Phase 5 and Phase 5.5 after edits.

---

### Phase 7 — Save & Atlassian Sync (Post-Approval)

Once approved:

1. Save the spec to the filesystem:
   - Path **with a Jira key**: `docs/specs/<KEY>-<kebab-case-title>.md`
   - Path **without a Jira key**: `docs/specs/<kebab-case-title>.md`
   - Create the directory if it does not exist.
   - Confirm the path to the user after saving.

**Steps 2 and 3 apply only when a Jira issue is linked. If no Jira key was provided, skip them
and go straight to Phase 8.**

2. Ask whether to upload the spec as an attachment to the Jira user story:

   > "Do you want to upload this spec to the Jira user story **[KEY]** as a Confluence page?
   > I'll create the page and add a comment linking it to the issue."

   If accepted:
   - Call `Atlassian:getConfluenceSpaces` to let the user pick the target space if more than one is available.
   - Create the page via `Atlassian:createConfluencePage` with the spec content.
   - Link it back to the issue via `Atlassian:addCommentToJiraIssue` with the Confluence page URL.

3. Offer to transition the Jira issue to the next appropriate status if the user requests it.

---

### Phase 8 — Transition to Implementation Planning

`intent-ops:plan-writer` has model-invocation disabled — it must be run by the user, not
called by this skill. After the spec is saved, stop and suggest it:

> "Spec saved to `docs/specs/<filename>.md`. Run `/intent-ops:plan-writer` with this spec path
> to create the implementation plan (include the Jira issue key `<KEY>` if one is linked)."

Do NOT proceed to any other skill or take any implementation action — `plan-writer`, run by the
user, is the only valid next step after spec approval.

---

## Semantic Decomposition Protocol

When an issue spans multiple independent contexts, apply this protocol:

1. **Identify semantic boundaries** — components that can change independently without breaking others.
2. **Name each context** — short, domain-language label (e.g., "Auth Context", "Billing Context").
3. **Map contracts** — what does each context expose or consume from the others?
4. **Sequence** — which context must be specced first based on dependency order?
5. **Create one SPEC.md per context.** Each has its own interview cycle, requirements, and acceptance criteria.

```
Decomposition output format:

## Proposed Decomposition

| Context | Responsibility | Depends On | Spec Order |
|---------|----------------|------------|------------|
| Context A | … | none | 1 |
| Context B | … | Context A | 2 |
```

Present this table and get user approval before starting any individual spec interview.

---

## Key Principles

- **Intent over steps.** Specs describe behavior, not implementation. Apply the Intent Test: if the technical approach changed completely, the Context and Outcome sentences must still make sense.
- **Refine like the three personas.** The New Engineer, the Malicious Tester, and the On-Call Engineer at 2am each expose different hidden assumptions — a spec that satisfies all three is far less likely to hide a bug.
- **One question at a time.** Never overwhelm the user.
- **2–3 approaches before commitment.** Always present options before writing.
- **Approval required.** The HARD-GATE is unconditional.
- **Semantic isolation.** Decompose when complexity demands it.
- **Recurrence awareness.** Surface patterns from the client's issue history.
- **Spec is the source of truth.** Not a secondary artifact.
- **Language consistency.** Apply the chosen language uniformly — never mix within a document.
- **Ubiquitous language.** Every term in the spec must come from the confirmed glossary.
- **Context map drives scope.** Cross-context boundaries define what is in scope vs. out of scope.
- **Nothing enters the spec unsourced.** Every requirement traces to the user, the ticket, or a
  file you read. What you inferred is presented as an inference and confirmed, never smuggled in.

---

## Common Rationalizations — All Wrong

| Excuse | Why it fails |
|--------|-------------|
| "The user obviously wants validation here, I'll just add the AC" | Obvious to you ≠ decided by them. Ask. An invented AC becomes built behavior. |
| "The ticket doesn't mention errors, so there's no error requirement" | Silence is a gap in the interview, not an answer. Surface it. |
| "I'll batch the remaining questions to finish faster" | Batching produces shallow answers and missed requirements. One at a time. |
| "The interview is long enough, I'll infer the rest" | Length isn't coverage. Inference isn't confirmation. |
| "I'll write it as fact and they'll correct me if it's wrong" | Reviewers confirm what looks right. That's how invented requirements survive review. |
| "One approach is clearly right — alternatives would waste their time" | Implied ≠ decided. Present options; the user decides. |
| "Open Questions make the spec look unfinished" | An unrecorded question doesn't stop existing; it just resurfaces as a production incident. |
| "This is standard domain behavior for this kind of system" | There is no standard. There is only this domain, and only the user knows it. |

---

## Red Flags — STOP and Reassess

If you catch yourself thinking any of these, stop and ask instead:

- "They probably want…"
- "It goes without saying that…"
- "In most systems, this would…"
- "I'll assume the happy path for now and revisit"
- "This is obvious, I don't need to ask"
- "I already know what they meant"
- "I'll clarify this at the final review"
- "Presenting alternatives will just confuse them"

**Every one of these means: ask the question. One message now beats a rewrite later.**

---

## Examples

### Example 1: Single-context feature

User says: "Can you spec out PROJ-1234 before we start coding?"
Actions: Phase 0 (Atlassian harvest) → Phase 0.5 (spec language) → Phase 0.6 (glossary, confirm with user) → Phase 1 (single context confirmed) → Phase 2 (Socratic interview, one question at a time) → Phase 2.5 (context map, confirm) → Phase 2.6 (socratic refinement with the three personas, ≥5 questions across all gap types) → Phase 3 (2–3 design approaches) → Phase 4 (author SPEC.md) → Phase 5 (self-review) → Phase 5.5 (sub-agent spec review, fix issues until Approved) → Phase 6 (HARD-GATE: present spec + reviewer output, wait for explicit approval) → Phase 7 (save to `docs/specs/PROJ-1234-*.md`, offer Confluence sync) → Phase 8 (suggest `/intent-ops:plan-writer`).
Result: SPEC.md on disk, plan-writer suggested to the user. No implementation artifact produced until the user explicitly approves the spec.

### Example 2: Multi-context decomposition

User says: "PROJ-5000 covers auth, billing, and reporting — let's break it down."
Actions: Phase 1 detects 3 independent contexts. Present decomposition table with contexts, dependencies, and spec order. Wait for approval before starting the first interview cycle.
Result: Three separate interview cycles; one SPEC.md per bounded context.

### Example 3: No Jira ticket — spec from a plain description

User says: "Before we code, let's spec out the new tenant self-signup flow."
Actions: No Jira key present. Phase 0 derives context from the user's description + a `src/main/`
scan → Phase 0.5 (language) → Phase 0.6 (glossary from conversation + code) → Phases 1–6 as
usual, leaning harder on the Socratic interview → Phase 7 saves to
`docs/specs/tenant-self-signup.md` (no key prefix, no Confluence sync) → Phase 8 suggests
`/intent-ops:plan-writer`.
Result: SPEC.md on disk with no Jira dependency at any step.

### Example 4: Wrong trigger — do not activate

User says: "Implement the changes from PROJ-1234."
Action: Do not activate. The user wants implementation, not a spec. A Jira key alone is not a trigger — intent to produce a spec artifact is required.
