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

Read and follow `CODING_STANDARDS.md` before writing or changing code. It is the only place for code quality and style rules (production Swift library code and Swift SDK test code). This file does not restate them.

## Dependencies

- The SDK has zero external production dependencies. Do not add any.
- Distribution is supported via SPM (primary), CocoaPods, and Carthage.
- The only test dependency is Cucumberish (CocoaPods, for contract tests).

## Testing

### Unit Tests (`Tests/PubNubUnitTests/`)

- Run unit tests through Xcode (`xcodebuild`, see Validation), not `swift test`. The SwiftPM test target is `PubNubTests`.
- Unit tests are part of `PubNub.xcodeproj`. When adding, moving, or renaming test files or shared test helpers, update the Xcode project tree and `PubNubTests` build phase, then run the affected tests.
- Mock all HTTP interactions via `MockURLSession`; do not make real network calls.
- JSON response fixtures live in `Tests/PubNubUnitTests/Support/Responses/{Feature}/`.
- Helpers in `Tests/PubNubUnitTests/Support/`.

### Integration Tests (`Tests/PubNubIntegrationTests/`)

- Require real PubNub API keys loaded from `PubNubTests_Info.plist`.
- Make actual network requests. Run through Xcode / Fastlane only (not `swift test`).
- Helpers in `Tests/PubNubIntegrationTests/Support/`.
- DataSync healthcare classes must already exist on the keyset. If missing, create them with `Scripts/DataSync/`; keep it in step with `Support/DataSyncHealthcareFixtures.swift`.

### Contract Tests (`Tests/PubNubContractTests/`)

- CI-managed BDD tests using Cucumberish; do not modify without coordination.

### Validation

Use the smallest relevant validation step first.

```bash
swift build
xcodebuild test -project PubNub.xcodeproj -scheme PubNub -destination 'platform=macOS' -only-testing:PubNubTests/<TestClassName>
swiftlint
```

Additional CI and Xcode-based validation is defined in `fastlane/Fastfile`.

## Editing Rules

- Preserve existing PubNub copyright headers.
- Swift files must pass `swiftlint --fix` followed by `swiftlint --strict` before a change is complete.
- Snippets in `Snippets/{Area}/` use `// snippet.<id>` / `// snippet.end` markers for doc tooling. Keep markers intact and add snippets for new public API.
- Prefer updating tests when changing public behavior.
- Do not expose unreleased, internal, or not-yet-announced features in documentation, snippets, comments intended for users, or user-facing output.
- If you change repository structure, test targets, or validation commands, update this file in the same change.

## Tooling

- Claude Code runs `.claude/hooks/run-swiftlint.sh` after every Swift edit (`swiftlint --fix`, then `swiftlint --strict`). The edit is already applied; remaining violations are reported back and must be fixed. Re-read the file after a reported reformat.