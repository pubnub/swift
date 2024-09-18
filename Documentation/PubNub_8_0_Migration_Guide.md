# PubNub 8.0 Migration Guide
PubNub Native Swift SDK v8.0 is the latest major release of the PubNub SDK for iOS, tvOS, macOS and watchOS written in Swift. As a major release, following [Semantic Versioning](https://semver.org/) conventions, 8.0 introduces API-breaking changes.

This guide is meant to ease the transition to the 8.0 version of the SDK. To read the full set of documentation, please head over to our official [docs page](https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk)

## Breaking API Changes
___

### Module name

* The module name has been changed to `PubNubSDK` due to a compiler error that occurs when a public type shares the same name as a module. As a result, you will need to replace `import PubNub` with `import PubNubSDK` in your Swift code. Additionally, ensure that `PubNubSDK` is listed in the `Frameworks, Libraries, and Embedded Content` section under the `General` tab in Xcode

### `ReconnectionPolicy`

* The `.legacyExponential(base, scale, maxDelay)` enumeration case from `AutomaticRetry.ReconnectionPolicy` is no longer supported. Use `.exponential(minDelay, maxDelay)` instead
* `PubNubConfiguration` uses default `AutomaticRetry` with an exponential reconnection policy to retry Subscribe requests in case of failure. If this behavior doesn’t suit your use case, you can pass custom `AutomaticRetry` object

### `ConnectionStatus`

* The following cases of the `ConnectionStatus` enumeration are no longer supported: `.connecting` and `.reconnecting`.
* This version introduces a new `.subscriptionChanged(channels, groups)` connection status, indicating that the SDK has subscribed to new channels or channel groups. This status is triggered each time the channel or channel group mix changes after the initial connection, and it provides all currently subscribed channels and channel groups. Additionally, you can check your current activity status locally by accessing the `isActive` property on `ConnectionStatus`
