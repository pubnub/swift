# PubNub 9.0 Migration Guide

PubNub Native Swift SDK v9.0 is the latest major release of the PubNub SDK for iOS, tvOS, macOS, watchOS and visionOS written in Swift. As a major release, following [Semantic Versioning](https://semver.org/) conventions, 9.0 introduces API-breaking changes.

This guide is meant to ease the transition to the 9.0 version of the SDK. To read the full set of documentation, please head over to our official [docs page](https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk)

## Breaking API Changes

### `LogWriter`

1. The previous `send(message:)` method of the `LogWriter` protocol has been replaced with `send(message:withType:withCategory:)`, which takes the following parameters:

    - `message:` An autoclosure returning the log message. This allows the log message to be deferred until it is needed
    - `withType:` The severity level of the log
    - `withCategory:` The value of `LogCategory` type to classify the log message, possible values are:
       - `Networking` - logs related to network operations  
       - `PubNub` - logs related to the methods invoked on `PubNub` instance
       - `Crypto` - logs related to `CryptoModule`
       - `EventEngine` - logs related to the internal implementation of Presence and Subscribe handling if the new mechanism is enabled by setting `enableEventEngine` in `PubNubConfiguration`
       - `None` - a default category used when no specific category is provided

2. The `format(prefix:level:date:queue:thread:file:function:line:)` method available in the `PubNubLogger` class has been enhanced to include a `category:` parameter of type `LogCategory`. This change adds a log category, enclosed in square brackets, at the beginning of the log prefix. If you prefer not to include the log category, you can control this behavior using the `prefix` property of your custom `LogWriter` implementation

## Features

The new version of SDK provides `OSLogWriter` as the recommended `LogWriter` to use, utilizing the `os` log framework under the hood for efficient and structured logging. The subsystem name for all logs generated by SDK is `com.pubnub` and the categories are of `LogCategory` type as mentioned in the first point of this document.
