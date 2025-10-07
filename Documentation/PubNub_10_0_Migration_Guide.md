# PubNub 10.0 Migration Guide

PubNub Native Swift SDK v10.0 is the latest major release of the PubNub SDK for iOS, tvOS, macOS, watchOS and visionOS written in Swift. As a major release, following [Semantic Versioning](https://semver.org/) conventions, 10.0 introduces API-breaking changes.

This guide is meant to ease the transition to the 10.0 version of the SDK. To read the full set of documentation, please head over to our official [docs page](https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk)

## Breaking API Changes

### 1. Logging System

#### 1.1 LogWriter Protocol Changes

The `LogWriter` protocol method signature has changed. You must update your custom `LogWriter` implementations (if any):

```swift
// Before (9.0):
func send(
  message: @escaping @autoclosure () -> String,
  withType logType: LogType, 
  withCategory category: LogCategory
)

// Now (10.0):
func send(
  message: @escaping @autoclosure () -> LogMessage,
  metadata: LogMetadata
)
```

**Key Changes:**

1. **`LogType` renamed to `LogLevel`** - A new `trace` level has been added as the lowest severity level for detailed debugging
2. **Structured Messages** - `LogMessage` objects replace simple strings with rich data:
   - `.text(String)` - Simple text messages
   - `.networkRequest(NetworkRequest)` - HTTP request details with ID, URL, headers, body, and status
   - `.networkResponse(NetworkResponse)` - HTTP response details with status code, headers, and body
   - `.customObject(CustomObject)` - Method calls/events with operation name and arguments
3. **Efficient Filtering** - `LogMetadata` (containing level and category) lets log writers check whether to log before evaluating the `@autoclosure` message parameter, avoiding expensive message construction for filtered logs

#### 1.2 Logger Configuration

The way to attach a logger to PubNub has changed. The static `log` and `logLog` properties have been removed. **Logging is now disabled by default**, so you must explicitly enable it:

```swift
// Before (9.0):
PubNub.log.levels = [.all]

// Now (10.0):
let pubnub = PubNub(configuration: ..., logger: PubNubLogger(levels: .all))
```

You can also change log levels during runtime:

```swift
// Change log levels at runtime
pubnub.logLevel = [.error, .warn]
```

#### 1.3 PubNubLogger Methods No Longer Public

The logging methods (`debug`, `info`, `event`, `warn`, `error`, `custom`) on `PubNubLogger` are no longer public. The SDK's logging system is designed exclusively for internal SDK operations. If you were using these methods for custom application logging, use your own logging solution instead.

```swift
// Before (9.0):
PubNub.log.debug("Custom debug message") // ✅ This worked

// Now (10.0):
pubNub.logger.debug("Custom debug message") // ❌ No longer available
```

### 2. Presence API Changes

#### 2.1 HereNow Method Pagination

**Key Changes:**

1. **New Parameters** - Two pagination parameters added:
   - `limit: Int` (default: 1000) - Maximum occupants per request
   - `offset: Int?` (default: 0) - Starting position for pagination
2. **Response Format** - Changed from `[String: PubNubPresence]` to tuple `(presenceByChannel: [String: PubNubPresence], nextOffset: Int?)`
3. **Pagination Control** - `nextOffset` provides the exact value for subsequent calls; `nil` means no more data

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
  limit: 1000, // Maximum number of occupants to return per request
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
