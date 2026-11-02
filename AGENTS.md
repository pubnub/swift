# AGENTS.md

This file provides guidance to AI coding tools working in this repository.

## Scope

This repository contains the official PubNub Swift SDK. The main supported public SDK surface is `PubNubSDK`.

Prefer guidance in this file over assumptions from source layout alone. If repository structure and this file disagree, update this file as part of the change.

## Public Surface

- The primary public entry point is `PubNub` in `Sources/PubNub/PubNub.swift`.
- Client configuration is provided through `PubNubConfiguration`.
- The Swift Package Manager product imported by clients is `PubNubSDK`.

## Coding Standards

Read and follow `CODING_STANDARDS.md` before writing or changing production Swift library code. It is the only place for production code quality and style rules. This file does not restate them.

## Dependencies

- The SDK has zero external production dependencies. Do not add any.
- Distribution is supported via SPM (primary), CocoaPods, and Carthage.
- The only test dependency is Cucumberish (CocoaPods, for contract tests).

## Testing

To write, change, or review a unit or integration test, use the `swift-test-writer` skill (`.agents/skills/swift-test-writer/SKILL.md`). It is the only place for test code rules and the test-writing procedure.

### Unit Tests (`Tests/PubNubUnitTests/`)

- SwiftPM test target `PubNubTests`; also part of `PubNub.xcodeproj`, which is what CI runs.
- Helpers in `Tests/PubNubUnitTests/Support/`.

### Integration Tests (`Tests/PubNubIntegrationTests/`)

- Require real PubNub API keys and make actual network requests. Run through Xcode / Fastlane only (not `swift test`).
- Helpers in `Tests/PubNubIntegrationTests/Support/`.

### Contract Tests (`Tests/PubNubContractTests/`)

- CI-managed BDD tests using Cucumberish; do not modify without coordination.

### Validation

Use the smallest relevant validation step first. For unit tests that is `swift test`; use `xcodebuild` when test files were added, moved, or renamed, when the Xcode project changed, or for platform-specific changes. `MACOSX_DEPLOYMENT_TARGET=12.0` is required because the project's own 10.15 target is rejected by current Xcode. If the project target is raised, drop the override here.

```bash
swift build
swift test --filter <TestClassName>
xcodebuild test -project PubNub.xcodeproj -scheme PubNub -destination 'platform=macOS' -only-testing:PubNubTests/<TestClassName> MACOSX_DEPLOYMENT_TARGET=12.0
swiftlint
```

`test_Constant_PubnubSwiftSDKVersion_MatchesBundleVersion` is skipped under `swift test`; only Xcode builds carry the bundle version.

Additional CI and Xcode-based validation is defined in `fastlane/Fastfile`.

## Pull Requests

To write a PR title or PR description, or to open or edit a PR, use the `swift-pr-writer` skill (`.agents/skills/swift-pr-writer/SKILL.md`). It is the only place for PR text rules. Pull requests are squash-merged, so branch commit messages are free-form.

## Editing Rules

- Preserve existing PubNub copyright headers.
- Swift files must pass `swiftlint --fix` followed by `swiftlint --strict` before a change is complete.
- Snippets in `Snippets/{Area}/` use `// snippet.<id>` / `// snippet.end` markers for doc tooling. Keep markers intact and add snippets for new public API.
- Prefer updating tests when changing public behavior.
- Do not expose unreleased, internal, or not-yet-announced features in documentation, snippets, comments intended for users, or user-facing output.
- If you change repository structure, test targets, or validation commands, update this file in the same change.

## Tooling

Hooks in `.claude/hooks/` (registered in `.claude/settings.json`) are silent on success; they write to stderr and exit 2 only when Claude must act, and never block on their own failures.

- `run-swiftlint.sh`: after every Swift edit, runs `swiftlint --fix` then `--strict`. The edit is already applied; fix remaining violations and re-read the file after a reformat.
- `check-test-registered.sh`: after a unit or integration test edit, reports if the file is missing from `project.pbxproj`.
- `run-swift-build.sh` (`Stop`): runs `swift build --build-tests` when `Sources/` changed and reports errors only. Passing does not guarantee the Xcode build compiles.