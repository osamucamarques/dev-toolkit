---
name: retro-spec
description: 'Write a formal SPEC.md from existing code for retroactive documentation or validation. Use when implementation already exists and a spec is needed — "retro spec", "reverse spec", "spec from existing code", "we already built this", or starting from a Jira key with code already on the branch. Not for new features — use intent-ops:spec-writer instead.'
license: MIT
disable-model-invocation: true
metadata:
  author: Samuel Marques
  version: 1.1.0
---

# Retro Spec Skill

Produce a formal SPEC.md from existing code: read the implementation, validate intent through a
focused interview, and write a spec that documents actual behavior — flagging gaps, deviations,
and idempotency/compatibility risks discovered during analysis.

The output format is identical to `intent-ops:spec-writer` (EARS/GEARS requirements, DDD
structure, ubiquitous language). The difference is the direction: code is the source of truth,
and the spec validates it — not the other way around.

---

## HARD-GATE

```
⛔ IMPLEMENTATION BLOCK
No code changes may be produced during this skill.
This skill reads and documents — it does not modify the implementation.
If gaps or bugs are found, they are flagged as open questions in the spec.
The developer decides whether to fix the code or update the spec after review.
```

---

## Activation

**Always use this skill** when:

| Signal | Example |
|--------|---------|
| Code-first, spec-after | "I already coded this — write the spec for it" |
| Retroactive documentation | "Document what we built in PROJ-1234" |
| Spec-code alignment check | "Validate our code against a spec", "does our code match the requirements?" |
| Post-implementation spec | "retro spec for this feature", "reverse spec" |
| Redirect from spec-writer | User was writing a forward spec and spec-writer detected existing code |

**Do not activate** when the feature has not been implemented yet — use `intent-ops:spec-writer`.

Extract the Jira key (if present) and the target code scope, then proceed to **Phase 0**.

---

## Phases

### Phase 0 — Context Harvest

**Jira context (if a key was provided):**

1. Call `Atlassian:getAccessibleAtlassianResources` to resolve the `cloudId`.
2. Call `Atlassian:getJiraIssue` with fields: `summary`, `description`, `status`, `issuetype`,
   `priority`, `labels`, `components`, `assignee`, `reporter`, `created`, `updated`, `comment`.
3. If linked issues or subtasks exist, fetch those too (up to 5 hops).
4. Summarize internally. Do not dump raw Jira content to the user.

**Code scope discovery:**

Identify which files implement the feature. In priority order:

1. **Feature branch diff** — if on a non-main branch, run:
   ```bash
   git diff main...HEAD --name-only
   ```
   Use this as the primary file list.
2. **Jira key in commits** — search recent commits for the issue key:
   ```bash
   git log --oneline --all | grep -i "<KEY>"
   ```
3. **User-provided paths** — if the user named specific files or modules, use those.
4. **Ask** — if scope cannot be determined, ask the user: "Which files or modules implement this feature?"

Present the discovered file list to the user and confirm before reading any code.

---

### Phase 0.5 — Spec Language

Ask in which language the SPEC.md should be written:

> "Should the spec be written in **English** or **Portuguese (pt-BR)**?
> This affects the language of requirements, EARS/GEARS keywords, and all spec content."

Wait for the answer and store the chosen language. Apply it consistently from Phase 4 onward.
All phases before Phase 4 are conducted in the same language as the conversation.

---

### Phase 0.6 — Ubiquitous Language Bootstrap

Same process as `intent-ops:spec-writer` Phase 0.6, with one difference: the **primary source
is the codebase** (class names, method names, package structure, constants, enums), not the Jira
ticket. Jira and conversation vocabulary are secondary sources used to detect synonyms and drift.

Present the glossary proposal to the user and wait for confirmation before proceeding.

---

### Phase 1 — Code Analysis

Read every file in the confirmed scope. For each file, extract:

| What to extract | How to express it |
|-----------------|------------------|
| Primary responsibility | One sentence per class/module |
| Public API surface | Method signatures, endpoint paths, event types |
| State mutations | What gets created, updated, or deleted |
| External dependencies | Services called, repositories used, events published |
| Error handling | What conditions are caught and how |
| Idempotency signals | Are writes guarded against duplicates? Any `saveOrUpdate`, `upsert`, `IF NOT EXISTS`, or version checks? |
| Backward compat signals | Any `@Deprecated`, versioned endpoints, migration scripts? |

Produce an internal analysis summary. **Do not dump code analysis to the user.** Surface only
what is needed to frame the first interview question.

**Translate before you draft.** Because the source of truth here is code, every fact you just extracted is phrased in implementation vocabulary (method names, headers, endpoints, mechanisms). None of that vocabulary may reach Context or Outcome directly. Before moving on, restate each extracted fact as a business-level sentence: not "the callback reads the `Origin` header and overrides the default redirect", but "the user returns to the URL where they started the login." This is the single highest-risk moment for retro-spec to fall into the "spec leaked into implementation" anti-pattern — code as the source makes technical phrasing tempting by default.

---

### Phase 1.5 — Gap & Risk Pre-Scan

Before the interview, flag any potential issues found in the code analysis:

| Category | What to look for |
|----------|-----------------|
| **Idempotency gaps** | Writes with no duplicate guard, retryable operations that produce side effects |
| **Backward compat risks** | Removed fields, changed types, tightened validation vs. existing callers |
| **Missing error handling** | Uncaught exceptions that would surface to callers as 500s |
| **Undefined behavior** | Code paths that return null or throw without a documented contract |
| **Scope creep** | Logic that doesn't map to any Jira requirement (if ticket was provided) |

Carry these findings into Phase 2 as targeted interview questions, and into Phase 4 as
open questions or constraint requirements in the spec. Do not present the full list to
the user upfront — weave findings into the interview naturally.

---

### Phase 2 — Intent Validation Interview

**Goal:** confirm that the code's behavior matches the developer's intent. This is not a
discovery interview — it is a validation interview. Ask "is this right?" not "what should this do?"

**Rules:**
- One question per message.
- Frame every question around what the code actually does: "The code does X — is that the intent?"
- When gaps are found, present them clearly: "I see no idempotency guard on this write — is that intentional, or should the spec require it?"
- Use only canonical terms from the confirmed glossary.
- Stop when you have enough to write a complete spec with < 5% behavioral ambiguity remaining.

**Question bank (adapt — do not follow mechanically):**

| # | Area | Sample framing |
|---|------|----------------|
| 1 | Primary intent | "The code appears to do [X]. Is that the complete intended behavior, or are there cases it doesn't yet handle?" |
| 2 | Actor | "Who calls this — internal service, external client, scheduled job?" |
| 3 | Trigger | "What initiates this flow in production? The code is invoked via [endpoint/event/job] — is that the only trigger?" |
| 4 | Happy path | "Walk me through the expected success scenario — does the code's behavior match your mental model?" |
| 5 | Failure modes | "The code handles [errors found]. Are there failure scenarios it should handle but doesn't?" |
| 6 | Idempotency | "If this operation is called twice with the same input, the code [does/doesn't guard against it]. Is idempotency required here?" |
| 7 | Compatibility | "The public interface currently [shape]. Are there clients depending on this that would break if the shape changed?" |
| 8 | NFRs | "Are there latency, availability, security, or compliance constraints the code should honor that aren't visible in the implementation?" |
| 9 | Out of scope | "Is there anything in the code that was added speculatively and shouldn't be in the spec?" |
| 10 | Acceptance | "How would you verify this feature works correctly in production? What would a failing acceptance test look like?" |

**Intent Test:** before locking any Context/Outcome sentence drafted from code, ask: *"If the technical approach changed completely, would this sentence still make sense?"* If a sentence only makes sense given the current implementation, it hasn't been translated far enough yet — go back and restate it in terms of what the actor experiences, not what the code does.

---

### Phase 2.5 — Bounded Context & Context Map

Same process as `intent-ops:spec-writer` Phase 2.5. Use the code's module/package structure
as the primary signal for bounded context identification.

---

### Phase 2.6 — Socratic Refinement (Three Personas)

Same process as `intent-ops:spec-writer` Phase 2.6: switch perspective across **The New Engineer**, **The Malicious Tester**, and **The On-Call Engineer at 2am**, and ask at least 5 questions covering all three gap types — **Ambiguity**, **Rule conflict**, **Exceptional case**. For retro-spec, weight this toward what the code silently assumes rather than what a fresh feature might miss: where would the New Engineer misread the code's intent, what input would the Malicious Tester send that the code doesn't guard against, what would the On-Call Engineer need to know at 2am that only exists in the author's head?

Every answer becomes a new Constraint, Acceptance Criterion, or an entry in the Phase 1.5 gap list — never left as an unresolved note.

---

### Phase 3 — Alignment Assessment

Before authoring the spec, produce an internal alignment table:

| Requirement source | Spec requirement | Code behavior | Status |
|-------------------|-----------------|---------------|--------|
| Jira description | … | Implemented | ✅ |
| Interview answer | … | Missing | ⚠️ Gap |
| Code analysis | … | Implemented (no Jira match) | ℹ️ Scope note |

- **✅ Aligned** — code implements the intent; write as a SHALL requirement.
- **⚠️ Gap** — code does not implement the behavior; write as a SHALL requirement and flag as an open question.
- **ℹ️ Scope note** — code does something not in the ticket; surface to user: "The code also does [X] — should this be in scope for the spec, or out of scope?"

This table drives what goes into the spec. Do not present the table to the user — surface only the scope notes and gaps that require a decision.

---

### Phase 4 — SPEC.md Authoring

Use the same template as `intent-ops:spec-writer` Phase 4. Apply EARS/GEARS syntax.
Load `references/spec-template.md` for the full document structure.

**Retro-spec additions:**

Include a **Section 13 — Implementation Notes** in the spec:

```markdown
## 13. Implementation Notes

> This spec was written from existing code. The implementation is the source of record.
> Deviations between this spec and the code are listed below as open questions.

### Alignment gaps
| Gap | Code behavior | Spec requirement | Resolution needed |
|-----|--------------|------------------|-------------------|
| … | … | … | Fix code / Relax spec / Accept |

### Idempotency coverage
| Operation | Idempotent? | Guard mechanism |
|-----------|------------|-----------------|
| … | ✅ / ⚠️ | … |

### Backward compatibility
| Public contract | Breaking risk | Notes |
|----------------|--------------|-------|
| … | ✅ Safe / ⚠️ Risk | … |
```

If no gaps, idempotency risks, or compat risks exist, omit Section 13.

**Section 12 — Decisions and Deviations:** fill this section when the interview reveals that the developer made a conscious, intentional decision that diverges from what the spec would describe. This is distinct from a gap: a gap is missing or unintended behavior; a deviation is deliberate and reasoned. Record each deviation with: the decision, the reason, the current status, and the risk while the deviation exists. Do not list deviations in the alignment gaps table in Section 13.

---

### Phase 5 — Self-Review Gate

Same checklist as `intent-ops:spec-writer` Phase 5, plus:

| Check | Question |
|-------|----------|
| Code alignment | Does every SHALL requirement correspond to behavior that exists in the code, or is it clearly flagged as a gap? |
| No silent scope | Every behavior observed in the code is either in the spec or explicitly noted as out of scope. |
| Idempotency coverage | Section 13 lists all state-mutating operations and their idempotency status. |
| Compat coverage | Section 13 lists all public contracts and flags any backward compat risks. |
| Intent leak (critical for retro-spec) | Re-run the Intent Test on every Context/Outcome sentence. Scan for the three leak signals: technical verbs ("detect", "override", "intercept"), infra terms outside Constraints ("header", "JWT", "query string"), and Out of Scope entries that list discarded technical approaches instead of excluded behaviors. Because this spec was drafted from code, this check matters more here than in a forward spec — fix every occurrence inline. |

Fix all issues before presenting.

---

### Phase 5.5 — Sub-Agent Spec Review

Same process as `intent-ops:spec-writer` Phase 5.5.
Load `references/spec-reviewer-prompt.md` for the full prompt template.

---

### Phase 6 — User Review Gate

Present the completed spec and ask:

> "Retro spec complete. Please review the requirements and the alignment notes in Section 13.
> For each gap, decide: fix the code, relax the spec, or accept the deviation.
> Let me know if anything needs to change before we finalize."

Wait for explicit approval. If changes are requested, re-run Phase 5 and Phase 5.5 after edits.

---

### Phase 7 — Save & Atlassian Sync

Same process as `intent-ops:spec-writer` Phase 7. Save to:
- Path **with a Jira key**: `docs/specs/<KEY>-<kebab-case-title>.md`
- Path **without a Jira key**: `docs/specs/<kebab-case-title>.md`

The Jira/Confluence sync steps apply only when a Jira issue is linked — skip them if no key was
provided. When creating the Confluence page (if accepted), add a note: "Spec written retroactively from existing implementation."

---

### Phase 8 — Next Steps

After the spec is saved, offer options based on the alignment assessment. `intent-ops:plan-writer`
has model-invocation disabled, so any option that leads there is something the user runs
themselves, not something this skill invokes:

**If no gaps were found:**
> "Spec saved. The code fully aligns with the spec. Options:
> 1. **Plan review** — run `/intent-ops:plan-writer` to produce a plan retroactively (useful for documentation).
> 2. **Done** — no further action needed."

**If gaps were found:**
> "Spec saved with [N] gaps noted in Section 13. Options:
> 1. **Fix gaps** — run `/intent-ops:plan-writer` to produce a plan for the gap fixes only.
> 2. **Accept gaps** — mark them as known deviations and close.
> 3. **Relax spec** — remove the gap requirements from the spec and save the updated version."

Wait for the user's choice. If they pick a plan-writer option, point them at the command —
do not attempt to invoke `plan-writer` yourself.

---

## Key Principles

- **Code is the source of truth — but the spec must not read like code.** Extracted facts are phrased in implementation vocabulary; every one of them gets translated to business language and passes the Intent Test before it reaches Context or Outcome. This is the anti-pattern this skill is most exposed to (intent leaking into implementation) — guard against it deliberately, at every phase, not just at self-review.
- **No silent gaps.** Every deviation between code and intent is surfaced and documented.
- **No code changes.** This skill reads; it does not modify the implementation.
- **Idempotency and compatibility are always checked.** Section 13 is not optional when risks exist.
- **Same spec format.** A retro spec is as rigorous as a forward spec — reviewers should not be able to tell the difference from the spec alone.
- **One question at a time.** Validation interviews follow the same discipline as discovery interviews.

---

## Examples

### Example 1: Developer coded first, wants retroactive spec

User says: "I already built the tenant provisioning flow for PROJ-3400 — can you write the spec from the code?"
Actions: Phase 0 (Jira harvest + discover files from branch diff) → Phase 0.5 (language) → Phase 0.6 (glossary from code) → Phase 1 (code analysis, translate to business language) → Phase 1.5 (gap pre-scan) → Phase 2 (validation interview, Intent Test) → Phase 2.5 (context map) → Phase 2.6 (socratic refinement with the three personas) → Phase 3 (alignment assessment) → Phase 4 (SPEC.md with Sections 12–13 as applicable) → Phase 5 (self-review) → Phase 5.5 (sub-agent review) → Phase 6 (user review gate) → Phase 7 (save) → Phase 8 (offer gap plan).

### Example 2: Retroactive spec with idempotency gap

Code analysis finds: `tenantRepository.save(tenant)` with no duplicate guard.
Phase 1.5 flags it as an idempotency gap.
Phase 2 question: "The save operation has no idempotency guard — if provisioning is triggered twice for the same tenant, it would create a duplicate. Is idempotency required here?"
Phase 4: writes `WHEN a provisioning event is received the system SHALL be idempotent` as a SHALL requirement. Section 13 lists this as a gap: code does not implement it.
Phase 8: suggests `/intent-ops:plan-writer` for the idempotency fix only.

### Example 3: Wrong trigger — do not activate

User says: "Write a spec for the new billing module."
Action: Do not activate — no implementation exists yet. Direct to `intent-ops:spec-writer`.
