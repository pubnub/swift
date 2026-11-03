---
name: swift-migration-guide-writer
description: Draft or review a major-version migration guide for the PubNub Swift SDK. Use for Documentation/PubNub_X_0_Migration_Guide.md; not for release notes, changelogs, or minor releases.
---

# Swift migration guide writer

Create a complete migration guide that tells SDK consumers what they must change when moving from the latest release of the previous major version.

## Workflow

1. Read the repository's `AGENTS.md` and [the migration guide conventions](references/migration-guide-conventions.md).
2. Establish the comparison before inspecting changes:
   - Use the target major version and Git ref supplied in the request.
   - If no target ref is supplied, use the current worktree. If no target major is supplied, use the major immediately after the highest stable release tag.
   - Use the latest stable release of the immediately preceding major as the baseline.
   - Record inferred versions, refs, and release scope as assumptions and continue.
3. Read the closest existing migration guides, giving the latest guide the most weight. Use them for structure, scope, and tone, not as evidence that a change applies to the target release.
4. Build a candidate inventory from independent repository sources:
   - **Swift API diagnostic**
     - Run from the target checkout or worktree: `swift package diagnose-api-breaking-changes <baseline-ref> --products PubNubSDK`
     - Treat diagnostics as candidates, not verified migration claims.
     - Consolidate related symbol, accessor, and conformance diagnostics into consumer-level changes.
     - Consider a nonzero exit status successful when breakage diagnostics were produced.
     - If the command cannot complete, record the failure and continue.
   - **Public API source comparison**
     - Compare `Sources/PubNub/` between the baseline and target.
     - Verify diagnostic candidates and find unreported changes, including deprecations and behavior changes.
     - Inspect removals, visibility changes, renamed symbols or labels, changed types or defaults, protocol requirements, conformances, and enum cases.
   - **Distribution and compatibility**
     - Compare `Package.swift`, `PubNubSwift.podspec`, the Xcode project, module and product names, supported platforms, and deployment targets.
   - **Focused history**
     - Inspect source history only when needed to establish intent, consumer impact, or the supported replacement.
   - **Excluded sources**
     - Do not use `.pubnub.yml` or generated release metadata as evidence.
5. Classify every candidate:
   - Include a breaking change when existing consumer code, configuration, packaging, or documented behavior requires action.
   - Include a deprecation introduced by the target release when consumers should start migrating to a supported replacement.
   - Include an additive API change only when it can break valid source, such as adding a case to an exhaustively switched public enum.
   - Exclude ordinary features, fixes that restore existing behavior, implementation refactors, tests, tooling, and changes that require no consumer migration.
   - Exclude `Sources/PubNub/KMP/` by default because it is interoperability infrastructure, unless the request explicitly includes it.
6. Verify each included claim against the target source and its consumer-facing usage. Confirm the old form, the replacement, affected conditions, and any behavior that remains compatible. Do not infer a migration from a symbol name or diff alone.
7. Draft the guide at `Documentation/PubNub_<major>_0_Migration_Guide.md`, unless the request provides another destination. Preserve an existing draft's accurate content and unrelated edits.
8. Report the candidate inventory with the draft:
   - Included changes and their evidence.
   - Excluded candidates and the reason for exclusion.
   - Assumptions and unresolved candidates.

## Boundaries

- Never silently include an ambiguous or internal item. Keep it out of the draft, record it as unresolved, and complete the remaining workflow.
- Do not turn the guide into release notes or a complete list of changes.
- Do not describe internal mechanisms when a consumer-visible consequence is sufficient.
- Do not promise compatibility, behavior, or replacement APIs that the source does not verify.
- Limit documentation changes to the target migration guide. Do not modify changelogs, release configuration, or other migration guides.
