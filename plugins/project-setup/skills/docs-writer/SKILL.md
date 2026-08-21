---
name: docs-writer
description: 'Markdown documentation writer that applies the project style guide. Use when writing or editing README, guides, /docs/* pages, CONTRIBUTING.md, ARCHITECTURE.md, or any .md file, and after implementing features that need documenting. Not for code comments, JSDoc, or OpenAPI specs.'
license: CC-BY-4.0
derived_from: 'tech-leads-club/agent-skills — (development)/docs-writer'
source_url: 'https://github.com/tech-leads-club/agent-skills/blob/main/packages/skills-catalog/skills/%28development%29/docs-writer/SKILL.md'
metadata:
  author: Samuel Marques
  version: 1.0.0
---

# Documentation Writer

> **Attribution.** Derived from [`docs-writer`](https://github.com/tech-leads-club/agent-skills/blob/main/packages/skills-catalog/skills/%28development%29/docs-writer/SKILL.md) in the [Tech Leads Club agent-skills](https://github.com/tech-leads-club/agent-skills) catalog, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
> **Changes made:** added the `CONTRIBUTING.md` pre-read, the `references/style-guide.md` handoff, and the formatting-script offer in Step 4.

As an expert technical writer and editor, your goal is to produce and refine documentation that is accurate, clear, consistent, and easy for users to understand. If a `CONTRIBUTING.md` exists in the project root, read it first for any project-specific documentation conventions before proceeding.

## Step 1: Understand the goal and create a plan

1. **Clarify the request:** Fully understand the user's documentation request. Identify the core feature, command, or concept that needs work.
2. **Differentiate the task:** Determine if the request is primarily for **writing** new content or **editing** existing content. If the request is ambiguous (e.g., "fix the docs"), ask the user for clarification.
3. **Formulate a plan:** Create a clear, step-by-step plan for the required changes.

## Step 2: Investigate and gather information

1. **Read the code:** Thoroughly examine the relevant source code to ensure your work is backed by the implementation and to identify any gaps.
2. **Identify files:** Locate the specific documentation files that need to be modified. Always read the latest version of a file before you begin work.
3. **Check for connections:** Consider related documentation. If you change a command's behavior, check for other pages that reference it. If you add a new page, check whether any navigation index or sidebar configuration file needs updating. Make sure all links are up to date.

## Step 3: Write or edit the documentation

1. **Follow the style guide:** Adhere to the rules in `references/style-guide.md`. Read this file to understand the project's documentation standards.
2. Ensure the new documentation accurately reflects the features in the code.
3. **Use `Edit` and `Write`:** Use file system tools to apply your planned changes. For small edits, `Edit` is preferred. For new files or large rewrites, `Write` is more appropriate.

### Sub-step: Editing existing documentation (as clarified in Step 1)

- **Gaps:** Identify areas where the documentation is incomplete or no longer reflects existing code.
- **Tone:** Ensure the tone is active and engaging, not passive.
- **Clarity:** Correct awkward wording, spelling, and grammar. Rephrase sentences to make them easier for users to understand.
- **Consistency:** Check for consistent terminology and style across all edited documents.

## Step 4: Verify and finalize

1. **Review your work:** After making changes, re-read the files to ensure the documentation is well-formatted, and the content is correct based on existing code.
2. **Link verification:** Verify the validity of all links in the new content. Verify the validity of existing links leading to the page with the new content or deleted content.
3. **Offer to format:** If the project has a formatting script (e.g., `npm run format`, `make fmt`), offer to run it once all changes are complete.
