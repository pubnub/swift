# PubNub 10.0 Migration Guide

PubNub Native Swift SDK v10.0 is the latest major release of the PubNub SDK for iOS, tvOS, macOS, watchOS and visionOS written in Swift. As a major release, following [Semantic Versioning](https://semver.org/) conventions, 10.0 introduces API-breaking changes.

This guide is meant to ease the transition to the 10.0 version of the SDK. To read the full set of documentation, please head over to our official [docs page](https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk)

## Breaking API Changes

### Logging System

#### 1. `LogWriter` Protocol Changes

The `LogWriter` protocol method signature has changed. You must update your custom `LogWriter` implementations (if any):

```swift
// Before (9.0):
func send(message: @escaping @autoclosure () -> String, withType logType: LogType, withCategory category: LogCategory)

// Now (10.0):
func send(message: @escaping @autoclosure () -> LogMessage, metadata: LogMetadata)
```

Key changes:

- `LogType` has been renamed to `LogLevel`, and a new `trace` log level has been added

- A log message is now a structured `LogMessage` object. Its `message` property represents what's actually being logged:

  - `.text(String)` - Simple text messages
  - `.networkRequest(NetworkRequest)` - HTTP request details
  - `.networkResponse(NetworkResponse)` - HTTP response details  
  - `.customObject(CustomObject)` - A method call or an event 

- `LogMetadata` provides data you can use for routing decisions in your custom `LogWriter` implementation, enabling efficient filtering without evaluating log content

#### 2. Logger Configuration

The way to attach a logger to PubNub has changed. The static `log` and `logLog` properties have been removed. As an example, the snippets below show how to configure a logger for troubleshooting: 

```swift
// Before (9.0):
PubNub.log.levels = [.all]

// Now (10.0):
let pubnub = PubNub(configuration: ..., logger: PubNubLogger(levels: .all))
```

#### 3. `PubNubLogger` Methods No Longer Public

The logging methods (`debug`, `info`, `warn`, `error`, etc.) on `PubNubLogger` are no longer public. This change ensures the SDK maintains control over its internal logging mechanism. The SDK's logging system is now properly encapsulated and designed exclusively for internal SDK operations. This ensures better separation of concerns and maintains SDK control over its logging behavior.

```swift
// Before (9.0):
PubNub.log.debug("Custom debug message") // This worked

// Now (10.0):
pubNub.logger.debug("Custom debug message") // ❌ No longer available
```