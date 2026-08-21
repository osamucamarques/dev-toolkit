Generate a conventional commit message following https://www.conventionalcommits.org/en/v1.0.0/ specification, optionally prefixed with a Jira issue ID, and create the commit automatically. The Jira ID is optional — when none is provided, a plain conventional commit is generated.

## Steps

1. If a Jira issue ID was passed as an argument (e.g. `/commit PROJ-123`), use it directly. Otherwise ask: **"Jira issue ID? (e.g. PROJ-123 — leave blank to skip)"**
2. Analyze the current git changes using `git status` and `git diff --staged`
3. Determine the appropriate commit type (feat, fix, docs, style, refactor, test, chore, etc.)
4. Identify the scope if applicable (component, module, or area affected)
5. Write a concise description in imperative mood (50 chars or less)
6. Add a detailed body if the change is complex (wrap at 72 chars)
7. Include breaking change footer if applicable
8. Format the message:
   - **With Jira ID:** `[PROJ-123] type(scope): description`
   - **Without Jira ID:** `type(scope): description`
9. Create the commit with the generated message

## Example formats

- `[PROJ-123] feat(auth): add OAuth2 login support`
- `[PROJ-456] fix(api): resolve null pointer in user endpoint`
- `[PROJ-789] refactor(payment): extract retry logic into PaymentRetryService`
- `docs: update installation instructions`
- `chore(deps): bump lodash to 4.17.21`

Generate the most appropriate commit message based on the changes and commit automatically.
