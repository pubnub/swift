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

## Architecture Notes

### Dependency Injection

`DependencyContainer` in `Sources/PubNub/DependencyContainer/` uses a key-based registry pattern. Dependencies conform to `DependencyKey` and are resolved with `.container`, `.weak`, or `.transient` storage behavior.

### Networking

- Routers in `Sources/PubNub/Networking/Routers/` build PubNub API requests.
- `HTTPSession` and related types handle execution, retry behavior, and response parsing.
- `SessionReplaceable`, `URLSessionReplaceable`, and `RequestReplaceable` are the main extension and test seams.

### Event Engine and Subscribe

- `Sources/PubNub/EventEngine/` contains the shared state-machine infrastructure for Subscribe and Presence flows.
- Subscribe-related implementation lives under `Sources/PubNub/Subscribe/`.
- `Sources/PubNub/Networking/Session/SessionStream.swift` is transport instrumentation, not subscribe-domain API.

## Validation

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
- Keep `Snippets/` aligned with public API changes.
- Prefer updating tests when changing public behavior.
- Do not expose unreleased, internal, or not-yet-announced features in documentation, snippets, comments intended for users, or user-facing output.
- If you change repository structure, test targets, or validation commands, update this file in the same change.
