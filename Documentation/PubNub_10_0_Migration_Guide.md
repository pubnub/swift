# PubNub 10.0 Migration Guide

PubNub Native Swift SDK v10.0 is the latest major release of the PubNub SDK for iOS, tvOS, macOS, watchOS and visionOS written in Swift. As a major release, following [Semantic Versioning](https://semver.org/) conventions, 10.0 introduces API-breaking changes.

This guide is meant to ease the transition to the 10.0 version of the SDK. To read the full set of documentation, please head over to our official [docs page](https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk)

## Breaking API Changes

### 1. Logging System

#### 1.1 LogWriter Protocol Changes

> **Note:** Skip this point if you haven't implemented a custom `LogWriter`.

The `LogWriter` protocol method signature has changed. You must update your custom `LogWriter` implementations:

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

1. **`LogType` renamed to `LogLevel`**:
   - **Type name change**: `LogType` is now `LogLevel`
   - **New level added**: `trace` level as the lowest severity for detailed debugging
2. **Structured Messages** - `LogMessage` objects replace simple strings. Its `message` property contains rich data:
   - `.text(String)` - Simple text messages
   - `.networkRequest(NetworkRequest)` - HTTP request details with ID, URL, headers, body, and status
   - `.networkResponse(NetworkResponse)` - HTTP response details with status code, headers, and body
   - `.customObject(CustomObject)` - Method calls/events with operation name and arguments
3. **New `metadata` parameter** - The `LogMetadata` type contains the `level` and `category` of the message being logged. This allows your log writer to inspect these properties for filtering specific log messages without evaluating the potentially expensive `LogMessage`:

#### 1.2 Logger Configuration

The way to attach a logger to PubNub has changed. The static `log` and `logLog` properties have been removed. **Logging is now disabled by default** and must be configured through the PubNub initializer:

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

The logging methods (`debug`, `info`, `event`, `warn`, `error`) on `PubNubLogger` are no longer public API. You can no longer use `PubNubLogger` to log your own application messages. The SDK's logging system is designed exclusively for internal SDK operations.

```swift
// Before (9.0):
PubNub.log.debug("Custom debug message") // ✅ This worked

// Now (10.0):
pubnub.logger.debug("Custom debug message") // ❌ No longer available
```
___

### 2. Presence API Changes

#### 2.1 HereNow Changes

The `hereNow` method now returns a **maximum of 1,000 occupants per channel**. Previously, it would return all occupants regardless of count. If you have channels with more than 1,000 occupants, you must use pagination to retrieve the complete list.

**Key Changes:**

1. **New Parameters** - Two pagination parameters added:
   - `limit: Int` (default: 1000, maximum: 1000) - Maximum occupants per channel
   - `offset: Int?` (default: 0) - Starting position for pagination

```swift
// Before (9.0) - returned ALL occupants:
pubnub.hereNow(
  on: ["channel1", "channel2"],
  and: ["group1"],
  includeUUIDs: true,
  includeState: false
) { result in
  switch result {
  case let .success(presenceByChannel):
    for (channel, presence) in presenceByChannel {
      print("Channel: \(channel), Occupancy: \(presence.occupancy)")
      print("All occupants: \(presence.occupants.count)") // Could be > 1000
    }
  case let .failure(error):
    print("Error: \(error)")
  }
}

// Now (10.0) - returns up to 1,000 occupants (per channel):
pubnub.hereNow(
  on: ["channel1", "channel2"],
  and: ["group1"],
  includeUUIDs: true,
  includeState: false,
  limit: 1000, // Maximum number of occupants to return (per channel)
  offset: 0 // Starting position for pagination
) { result in
  switch result {
  case let .success(presenceByChannel):
    for (channel, presence) in presenceByChannel {
      print("Channel: \(channel), Occupancy: \(presence.occupancy)")
    }
  case let .failure(error):
    print("Error: \(error)")
  }
}
```
___

## Deprecations (Non-Breaking Changes)

The following APIs are deprecated but still functional. They will continue to work in 10.0 but will be removed in the future. You should migrate to the recommended alternatives at your convenience.

### 1. Configuration Changes

#### 1.1 PubNubConfiguration: UUID Parameter Renamed to UserID

The `uuid` parameter in `PubNubConfiguration` has been deprecated in favor of `userId` to better reflect PubNub's terminology.

**Configuration Initializers:**

```swift
// Deprecated (still works):
let config = PubNubConfiguration(
  publishKey: "pub-key",
  subscribeKey: "sub-key",
  uuid: "my-user-id"
)

// Recommended:
let config = PubNubConfiguration(
  publishKey: "pub-key",
  subscribeKey: "sub-key",
  userId: "my-user-id"
)
```

**Bundle-based Configuration:**

```swift
// Deprecated (still works):
let config = PubNubConfiguration(from: .main)

// Recommended:
let config = PubNubConfiguration(bundle: .main)
```

> **Note:** If using Info.plist configuration, the default key name remains `PubNubUuid` for backward compatibility. You can continue using this key, or optionally migrate to `PubNubUserId` by passing `userIdAt: "PubNubUserId"` parameter.

**Configuration Properties:**

```swift
// Deprecated (still works):
let userId = config.uuid

// Recommended:
let userId = config.userId
```

#### 1.2 CipherKey Parameter Deprecated

The `cipherKey` parameter in `PubNubConfiguration` is deprecated in favor of `cryptoModule`.

```swift
// Deprecated (still works, but not recommended due to security concerns):
let config = PubNubConfiguration(
  publishKey: "pub-key",
  subscribeKey: "sub-key",
  userId: "my-user-id",
  cipherKey: Crypto(key: "my-cipher-key")
)

// Recommended - Secure encryption with backward compatibility:
let config = PubNubConfiguration(
  publishKey: "pub-key",
  subscribeKey: "sub-key",
  userId: "my-user-id",
  cryptoModule: CryptoModule.aesCbcCryptoModule(with: "my-cipher-key")
)
```
