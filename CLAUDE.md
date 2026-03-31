# CLAUDE.md

This file provides guidance to AI coding tools working in this repository.

## Project Overview

This is the official PubNub Swift SDK. The main supported public SDK surface in this repository is `PubNubSDK`.

Platform requirements: iOS 12+, macOS 10.15+, tvOS 12+, watchOS 4+, visionOS 1+. Swift 5+, Xcode 15+.

## Repository Layout

- `Sources/PubNub/` — main SDK implementation
- `Tests/PubNubTests/` — primary Swift test suite
- `Tests/PubNubContractTest/` — contract/acceptance tests
- `Examples/` — sample Xcode applications
- `Snippets/` — documentation code snippets organized by API area
- `Documentation/` — guides and migration docs
- `fastlane/` — CI/test automation
- `PubNub.xcodeproj` / `PubNub.xcworkspace` — Xcode project and workspace

## Architecture

### Core Entry Point

`PubNub` (`Sources/PubNub/PubNub.swift`) is the main public API. Configuration is provided through `PubNubConfiguration`.

### Dependency Injection

`DependencyContainer` (`Sources/PubNub/DependencyContainer/`) uses a key-based registry pattern. Dependencies conform to `DependencyKey` and are resolved from the container with `.container`, `.weak`, or `.transient` storage behavior.

### Networking Layer

- Routers in `Sources/PubNub/Networking/Routers/` build PubNub API requests.
- `HTTPSession` and related types handle execution, retry behavior, and response parsing.
- `SessionReplaceable`, `URLSessionReplaceable`, and `RequestReplaceable` are the main extension points for customers who need to override the default network session behavior. They are also the primary seams used for dependency injection and test mocking.

### EventEngine

`Sources/PubNub/EventEngine/` contains the generic state machine used for Subscribe and Presence flows. Concrete implementations live under `EventEngine/Subscribe/` and `EventEngine/Presence/`.

### Subscription System

`Sources/PubNub/Subscription/` manages subscribe flow through `SubscriptionSessionStrategy`.

`PubNubConfiguration.enableEventEngine` selects between:
- `EventEngineSubscriptionSessionStrategy`
- `LegacySubscriptionSessionStrategy`

Two event-listening APIs coexist:
- Legacy listeners in `Events/Old/`
- Entity-based subscriptions in `Events/New/`

## Validation

```bash
swift build
swift test
swift test --filter PubNubTests.PubNubConfigurationTests
swift test --filter PubNubTests.PubNubConfigurationTests/testDefaultValues
swiftlint
```

Fastlane is used for CI and Xcode-based validation:
- `bundle exec fastlane test --env <platform>`
- `bundle exec fastlane contract_test --env <contract-env>`
- `bundle exec fastlane integration_test`
- `bundle exec fastlane build_example --env ios`

Integration tests require PubNub test credentials via environment configuration. See `fastlane/Fastfile` and `fastlane/README.md`.

## Snippets

`Snippets/` contains documentation examples organized by API area. Keep snippets aligned with public API changes.

## Conventions

- The SPM product imported by clients is `PubNubSDK`; source lives under `Sources/PubNub/`.
- `Tests/PubNubTests/` generally mirrors SDK source areas, while contract tests live separately in `Tests/PubNubContractTest/`.
- All source files should preserve the existing PubNub copyright header.
- SwiftLint config is in `.swiftlint.yml`; notable exclusions include `Tests/`, `Examples/`, `fastlane/`, `.build/`, and `Pods/`.
