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

**Key changes:**

- `LogType` has been renamed to `LogLevel`, and a new `trace` log level has been added

- A log message is now a structured `LogMessage` object. Its `message` property represents what's actually being logged:

  - `.text(String)` - Simple text messages
  - `.networkRequest(NetworkRequest)` - HTTP request details
  - `.networkResponse(NetworkResponse)` - HTTP response details  
  - `.customObject(CustomObject)` - A method call or an event 

- `LogMetadata` provides data you can use for routing decisions in your custom `LogWriter` implementation, enabling efficient filtering without evaluating log content

#### 2. Logger Configuration

The way to attach a logger to PubNub has changed. The static `log` and `logLog` properties have been removed. **Logging is now disabled by default**, so you must explicitly enable it.

```swift
// Before (9.0):
PubNub.log.levels = [.all]

// Now (10.0):
let pubnub = PubNub(configuration: ..., logger: PubNubLogger(levels: .all))
```

You can also change log levels during runtime:

```swift
// Change log levels at runtime
pubnub.logger.levels = [.error, .warn] // Only show errors and warnings
```

#### 3. `PubNubLogger` Methods No Longer Public

The logging methods (`debug`, `info`, `warn`, `error`, etc.) on `PubNubLogger` are no longer public. This change ensures the SDK maintains control over its internal logging mechanism. The SDK's logging system is now properly encapsulated and designed exclusively for internal SDK operations. This ensures better separation of concerns and maintains SDK control over its logging behavior.

```swift
// Before (9.0):
PubNub.log.debug("Custom debug message") // This worked

// Now (10.0):
pubNub.logger.debug("Custom debug message") // ❌ No longer available
```

### Presence API Changes

#### HereNow Method Pagination Added

The `hereNow` method now includes pagination support with new `limit` and `offset` parameters:

```swift
// Before (9.0) - no pagination support:
pubnub.hereNow(
  on: ["channel1", "channel2"],
  and: ["group1"],
  includeUUIDs: true,
  includeState: false
) { result in
  switch result {
  case let .success(presenceByChannel):
    // Direct dictionary access - [String: PubNubPresence]
    for (channel, presence) in presenceByChannel {
      print("Channel: \(channel), Occupancy: \(presence.occupancy)")
    }
  case let .failure(error):
    print("Error: \(error)")
  }
}

// Now (10.0) - with pagination support:
pubnub.hereNow(
  on: ["channel1", "channel2"],
  and: ["group1"],
  includeUUIDs: true,
  includeState: false,
  limit: 1000, // Maximum number of occupants to return per request (maximum = 1000)
  offset: 0 // Starting position for pagination (0 = first page)
) { result in
  switch result {
  case let .success(response):
    // Tuple response with pagination info
    let presenceByChannel = response.presenceByChannel // [String: PubNubPresence]
    let nextOffset = response.nextOffset // Int? - offset for next page
    
    for (channel, presence) in presenceByChannel {
      print("Channel: \(channel), Occupancy: \(presence.occupancy)")
    }    
    if let nextOffset = nextOffset {
      print("More results available at offset: \(nextOffset)")
    }
  case .failure(let error):
    print("Error: \(error)")
  }
}
```

**Key changes:**

- **New `limit: Int` parameter** (default: 1000) - Maximum number of occupants returned per request
- **New `offset: Int?` parameter** (default: 0) - Starting position for pagination (use `nextOffset` from response for subsequent pages)
- **Response format change** - Returns tuple `(presenceByChannel: [String: PubNubPresence], nextOffset: Int?)` instead of direct `[String: PubNubPresence]` dictionary