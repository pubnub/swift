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

- A log message is now a structured `LogMessage` object. Its `message` property represents what's actually being logged:

  - `.text(String)` - Simple text messages
  - `.networkRequest(NetworkRequest)` - HTTP request details
  - `.networkResponse(NetworkResponse)` - HTTP response details  
  - `.customObject(CustomObject)` - A method call or an event 

- `LogMetadata` provides data you can use for routing decisions in your custom `LogWriter` implementation, enabling efficient filtering without evaluating expensive log content

#### 2. Logger Configuration

The way to attach a logger to PubNub has changed:

```swift
// Before (9.0):
PubNub.log.levels = [.all]

// Now (10.0) - attach logger via constructor:
let config = PubNubConfiguration(publishKey: "your-key", subscribeKey: "your-key", userId: "user-id")
let logger = PubNubLogger(levels: .all)
let pubnub = PubNub(configuration: config, logger: logger)
```
