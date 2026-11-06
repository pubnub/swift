---
name: swift-pr-writer
description: Write or change a PR title or PR description in the PubNub Swift SDK, and open the PR. Holds the repository's PR text rules, which the release bot parses into the changelog.
---

# Swift PR writer

The release bot (`@pubnub-release-bot`) builds the changelog and picks the next version from the PR body. Treat the body as machine input, not as free prose.

## Rules

- The title is free-form: no `type(scope):` prefix, about 60 characters, summarizing the net change against `master`.
- The description holds one entry per user-visible change, separated by blank lines, and nothing else. Put reviewer context in a PR comment.
- Write each entry as `<type>(<scope>): <subject>`.
- `type` is exactly one of `build`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `style`, `test`. It picks the changelog section and the bump: `feat` is minor, `fix` and `perf` are patch, the rest are not user-visible.
- `scope` is an optional short lowercase area name (`crypto`, `subscribe`); omit the parentheses when none fits.
- Make the subject imperative and as short as the change allows; about 60 characters is a ceiling, not a target.
- Default to one line. Add a body after a blank line only for essential behavior or migration details. Use one or two plain-prose sentences, wrapped at 100 characters; no headings, bullets, or code blocks, as the bot joins lines.
- When the change breaks public API, end the entry with a body, a blank line, and `BREAKING CHANGES: <short description>`, whatever its type. Never choose a type to avoid it.
- Add `Closes #N` only when the user asks.

## Opening the PR

1. Run `git diff master...HEAD` and write the title and entries from the net diff.
2. Apply one `type:` label for the highest-priority entry: `feat`, `fix`, `perf`, then any other. Use `type: <type>`, mapping `feat` to `feature`, `docs` to `documentation`, `perf` to `performance`, and `ci` or `style` to `chore`.
3. Use `priority: none` unless the user names another priority (`high`, `medium`, `low`).
4. Run `gh pr create` with the title, description, and labels.
5. Run `gh pr view`, check that title, body, and labels match your intent, and tell the user the title, the entries, and any `BREAKING CHANGES:` footer.

## Editing an existing PR

Rewrite the title or description from the net diff, apply it with `gh pr edit` without waiting for approval (edits are reversible), then do step 5.
