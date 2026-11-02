---
name: swift-pr-writer
description: Write or change a PR title or PR description in the PubNub Swift SDK, and open the PR. Holds the repository's PR text rules, which the release bot parses into the changelog.
---

# Swift PR writer

The release bot (`@pubnub-release-bot`) builds the changelog and picks the next version from the PR body. Treat the body as machine input, not as free prose.

## Rules

- The PR title is free-form: no `type(scope):` prefix, about 60 characters, summarizing the net change against `master`.
- The PR description holds one entry per user-visible change, separated by blank lines, and nothing else. Put reviewer context in a PR comment.
- Write each entry as `<type>(<scope>): <subject>`, then a blank line, then an optional `<body>`.
- `type` is exactly one of `build`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `style`, `test`. No other types (not `chore`, not `tests`).
- `scope` is an optional short lowercase area name (`crypto`, `subscribe`); omit the parentheses when none fits.
- Make the first line imperative and as short as the change allows; about 60 characters is a ceiling, not a target.
- Omit `body` when the first line is self-explanatory. When you do write one, make it a sentence or two of plain prose, wrapped at 100 characters at most. The bot joins its lines into one, so use no headings, bullets, or code blocks.
- Size the text to the change: a trivial change gets a one-line entry and a short PR description. Do not pad with detail the diff already shows.
- The type picks the changelog section and the bump: `feat` is minor, `fix` and `perf` are patch, the rest are not user-visible.
- When the change breaks public API, end the entry with a body, a blank line, and `BREAKING CHANGES: <short description>`, whatever its type. Never choose a type to avoid it.
- Add `Closes #N` only when the user asks.

## Opening the PR

1. Run `git diff master...HEAD` and write the title and entries from the net diff.
2. Apply one `type:` label, taken from the most significant entry type (`feat`, then `fix`, then `perf`, then the rest). Types map to labels by name (`fix` is `type: fix`), except:
   - `feat` is `type: feature`
   - `docs` is `type: documentation`
   - `perf` is `type: performance`
   - `ci` and `style` are `type: chore`
3. Use `priority: none` unless the user names another priority (`high`, `medium`, `low`).
4. Run `gh pr create` with the title, description, and labels.
5. Run `gh pr view` and check that title, body, and labels match what you intended. Tell the user the title, the entries, and any `BREAKING CHANGES:` footer.

## Editing an existing PR

Rewrite the title or description from the net diff against `master` and apply it with `gh pr edit` without waiting for approval; edits are reversible. Then run `gh pr view`, check it as in step 5 above, and tell the user what changed.
