# PubNub 11.0 Migration Guide

PubNub Native Swift SDK v11.0 is the latest major release of the PubNub SDK for iOS, tvOS, macOS, watchOS and visionOS written in Swift. As a major release, following [Semantic Versioning](https://semver.org/) conventions, 11.0 introduces API-breaking changes.

This guide is meant to ease the transition to the 11.0 version of the SDK. To read the full set of documentation, please head over to our official [docs page](https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk)

## Breaking API Changes

### 1. Unified Subscribe Event Model

> **Note:** Skip this section if you use the modern listener API (`onMessage`, `onPresence`, `onAppContext`, …). Only the legacy `SubscriptionListener` / is affected.

The legacy `SubscriptionListener` now emits the unified `PubNubEvent` — the same type the modern API uses — instead of the removed `SubscriptionEvent`. Since the catch-all `didReceiveSubscription` / `didReceiveBatchSubscription` closures are also deprecated in 11.0 (see Deprecations), migrate to the granular callbacks rather than update your `PubNubEvent` switch:

1. Replace `didReceiveSubscription` / `didReceiveBatchSubscription` with the granular closures — `didReceiveMessage`, `didReceivePresence`, `didReceiveAppContextEvent`, `didReceiveMessageAction`, `didReceiveFileUpload`, `didReceiveDataSyncEvent`.
2. Read connection status, subscription changes, and errors from `didReceiveStatus`.

```swift
// Before (10.0):
let listener = SubscriptionListener()
listener.didReceiveSubscription = { (event: SubscriptionEvent) in /* ... */ }
listener.didReceiveSubscriptionChange = { change in /* ... */ }

// Now (11.0) — prefer the granular callbacks:
let listener = SubscriptionListener()
listener.didReceiveMessage = { message in /* ... */ }
listener.didReceiveSignal = { message in /* ... */ }
listener.didReceivePresence = { presence in /* ... */ }
listener.didReceiveStatus = { status in
  switch status {
  case let .success(connection):
    print("Connection status: \(connection)")
  case let .failure(error):
    print("Subscribe error: \(error)")
  }
}
```

Along with the types above, `CoreListener.MessageActionEvent`, `SubscribeResponseHeader`, and the `subscriptionChanged` / `responseReceived` cases of `PubNubSubscribeEvent` are removed.

## Deprecations (Non-Breaking Changes)

### Catch-all Event Callbacks

The callbacks that deliver the whole `PubNubEvent` stream are deprecated in favor of the granular, per-type callbacks. They still work in 11.0 but will be removed in a future release:

- `onEvent` / `onEvents` on `Subscription`, `SubscriptionSet`, `PubNub`, and `EventListener`
- `didReceiveSubscription` / `didReceiveBatchSubscription` on the legacy `CoreListener`

Migrate to the granular callbacks — `onMessage`, `onSignal`, `onPresence` (or the `didReceive…` equivalents on the legacy listener).

> If you relied on `onEvents` to forward every event to a single sink (logging, analytics, a Combine/`AsyncStream` bridge), register one listener with all the granular handlers set instead.
