# AGENTS.md

This file provides guidance to AI coding tools working in this repository.

## Scope

This repository contains the official PubNub Swift SDK. The main supported public SDK surface is `PubNubSDK`.

Prefer guidance in this file over assumptions from source layout alone. If repository structure and this file disagree, update this file as part of the change.

## Public Surface

- The primary public entry point is `PubNub` in `Sources/PubNub/PubNub.swift`.
- Client configuration is provided through `PubNubConfiguration`.
- The Swift Package Manager product imported by clients is `PubNubSDK`.

## Repository Layout

- `Sources/PubNub/` — main SDK implementation
- `Tests/PubNubUnitTests/` — primary Swift unit tests
- `Tests/PubNubIntegrationTests/` — integration tests
- `Tests/PubNubContractTests/` — contract and acceptance tests
- `Examples/` — sample Xcode applications
- `Snippets/` — documentation code snippets organized by API area
- `Documentation/` — guides and migration docs
- `fastlane/` — CI and release automation
- `PubNub.xcodeproj` / `PubNub.xcworkspace` — Xcode project and workspace

## Dependencies

- The SDK has zero external production dependencies. Do not add any.
- Distribution is supported via SPM (primary), CocoaPods, and Carthage.
- The only test dependency is Cucumberish (CocoaPods, for contract tests).
- Platform minimums: iOS 12+, macOS 10.15+, tvOS 12+, watchOS 4+, visionOS 1+. Swift 5.9+.

## Architecture Notes

### Networking

- Routers in `Sources/PubNub/Networking/Routers/` build `URLRequest`s, `HTTPSession` executes them, and response decoders in `Networking/Response/` handle parsing.
- Retry logic lives in `Request`.

### Event Engine

- `Sources/PubNub/EventEngine/` contains the shared state-machine infrastructure.
- Subscribe implementation lives under `Sources/PubNub/EventEngine/Subscribe/` and `Sources/PubNub/Subscribe/`.
- Presence heartbeat and leave logic lives under `Sources/PubNub/EventEngine/Presence/`.

## Testing

### Unit Tests (`Tests/PubNubUnitTests/`)

- The only test target in `Package.swift` (`PubNubTests`). Run with `swift test`.
- Mock all HTTP interactions via `MockURLSession`; do not make real network calls.
- JSON response fixtures live in `Tests/PubNubUnitTests/Support/Responses/{Feature}/`.
- Helpers in `Tests/PubNubUnitTests/Support/`.

### Integration Tests (`Tests/PubNubIntegrationTests/`)

- Require real PubNub API keys loaded from `PubNubTests_Info.plist`.
- Make actual network requests. Run through Xcode / Fastlane only (not `swift test`).
- Helpers in `Tests/PubNubIntegrationTests/Support/`.

### Contract Tests (`Tests/PubNubContractTests/`)

- CI-managed BDD tests using Cucumberish; do not modify without coordination.

### Validation

Use the smallest relevant validation step first.

```bash
swift build
swift test
swift test --filter PubNubConfigurationTests
swift test --filter PubNubConfigurationTests/testDefaultValues
swiftlint
```

Additional CI and Xcode-based validation is defined in `fastlane/Fastfile`.

## Editing Rules

- Preserve existing PubNub copyright headers.
- Snippets in `Snippets/{Area}/` use `// snippet.<id>` / `// snippet.end` markers for doc tooling. Keep markers intact and add snippets for new public API.
- Prefer updating tests when changing public behavior.
- Do not expose unreleased, internal, or not-yet-announced features in documentation, snippets, comments intended for users, or user-facing output.
- If you change repository structure, test targets, or validation commands, update this file in the same change.
