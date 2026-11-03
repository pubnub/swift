# PubNub Swift migration guide conventions

Use these conventions when drafting or reviewing a major-version migration guide.

## Purpose and scope

A migration guide is an action-oriented document for consumers upgrading from the latest release of the previous major version. It is not a release summary.

Include:

- Source-breaking public API changes.
- Package, product, module, platform, or deployment changes that require consumer action.
- Behavior changes that require consumers to change code or expectations.
- Deprecations introduced in the target major when they have a verified, supported replacement.

Exclude:

- New features that do not affect existing code.
- Bug fixes that restore the existing contract.
- Internal implementation changes.
- Test, build, CI, and repository-maintenance changes.
- KMP-only interoperability changes unless explicitly requested.
- Deprecations that already existed at the baseline.

When an added public enum case can break exhaustive switches, treat it as a breaking-change candidate even though the API change is additive.

## Document shape

Follow the current guide naming convention:

```text
Documentation/PubNub_<major>_0_Migration_Guide.md
```

Use this overall structure, omitting empty sections:

````markdown
# PubNub <major>.0 Migration Guide

<Established introduction describing the major release, supported platforms, Semantic Versioning context, and the purpose of the guide.>

## Breaking API Changes

### 1. <Consumer-facing change>

<Impact, affected users, and required migration.>

```swift
// Before (<previous major>.x):
...

// Now (<major>.0):
...
```

## Deprecations (Non-Breaking Changes)

### <Deprecated API>

<What is deprecated, what replaces it, and whether existing code still works.>
````

The deprecations section is optional. Include it only when the target major introduces relevant deprecations with a verified replacement; otherwise omit the entire section. Do not repeat deprecations that already existed at the baseline.

Derive the supported platform list from the target repository state. Do not copy an older guide's list when platform support changed.

## Writing each change

Start with the consumer-visible difference. Then explain:

1. Who is affected or when the change matters.
2. What no longer compiles or behaves as before.
3. The supported replacement or action.
4. What remains compatible, when that prevents unnecessary migration work.

Use before-and-after Swift examples when they make the required edit clearer. Keep examples focused on the changed API and verify symbol names, argument labels, and defaults against both refs.

Use a note near the start of a section when only a subset of users is affected:

```markdown
> **Note:** Skip this section if you do not use a custom `LogWriter`.
```

Group tightly related changes when consumers will migrate them together. Keep unrelated migration actions in separate sections.

## Tone

- Write directly to SDK consumers.
- Prefer precise statements such as “is no longer public” or “pass the value to the initializer.”
- Explain consequences instead of implementation mechanics.
- Keep headings descriptive and examples practical.
- Wrap prose at 120 characters. Do not force-wrap headings, tables, fenced code, or links.
- When editing an existing guide, do not reflow unchanged paragraphs.
- Avoid promotional language and exhaustive inventories of new functionality.
- Do not claim that a guide is complete; it covers changes that require migration.

## Candidate report

Keep analysis outside the guide. For each candidate, record:

- The affected public API or distribution surface.
- Evidence from the comparison.
- The consumer impact.
- The replacement or migration action.
- Its disposition: include, exclude with reason, or unresolved.

Keep an ambiguous candidate out of the draft, record it as unresolved, and continue. This includes changes whose public status, release scope, compatibility impact, or supported replacement cannot be verified.
