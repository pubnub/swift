# PubNub Swift SDK

[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpubnub%2Fswift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pubnub/swift)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/PubNubSwift.svg)](https://img.shields.io/cocoapods/v/PubNubSwift.svg)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/pubnub/swift.svg?branch=master)](https://travis-ci.org/pubnub/swift)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/ea96a32a311944eaa09b4c452db4d397)](https://app.codacy.com?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

This is the official PubNub Swift SDK repository.

PubNub takes care of the infrastructure and APIs needed for the realtime communication layer of your application. Work on your app's logic and let PubNub handle sending and receiving data across the world in less than 100ms.

* [Requirements](#requirements)
* [Get keys](#get-keys)
* [Set up your project](#set-up-your-project)
* [Configure PubNub](#configure-pubnub)
* [Add event listeners](#add-event-listeners)
* [Publish and subscribe](#publish-and-subscribe)
* [Documentation](#documentation)
* [Support](#support)
* [License](#license)

## Requirements

* iOS 12.0+ / macOS 10.15+ / tvOS 12.0+ / watchOS 4.0+ / visionOS 1.0+
* Xcode 15+
* Swift 5+

The PubNub Swift SDK doesn't contain any external dependencies.

## Get keys

You will need the publish and subscribe keys to authenticate your app. Get your keys from the [Admin Portal](https://dashboard.pubnub.com/).

## Set up your project

You have several options to set up your project. We provide instructions here for [Swift Package Manager](#swift-package-manager), [CocoaPods](#cocoapods), and [Carthage](#carthage).

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

1. Create or open your project inside of Xcode
2. Navigate to **File** > **Add Package Dependencies...**
3. Enter the package URL: `https://github.com/pubnub/swift.git`
4. Use the `Up to Next Major Version` rule spanning from `9.0.0` < `10.0.0`
5. Click `Add Package`
6. From the list of package products, assign `PubNubSDK` to your target application

For more information see Apple's guide on [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
  pod 'PubNubSwift', '~> 9.0'
end
```

> Note: Replace `YOUR_TARGET_NAME` with your target's name.

In the directory containing your `Podfile` execute the following:

```bash
pod install
```

### [Carthage](https://github.com/Carthage/Carthage)

Officially supported: Carthage 0.39.1 and up.

Add the following to `Cartfile`:

```ruby
github "pubnub/swift" ~> 9.0
```

Then in the directory containing your `Cartfile`, execute the following:

```bash
carthage update --use-xcframeworks
```

## Configure PubNub

1. Import the module named `PubNub` inside your AppDelegate:

    ```swift
    import UIKit
    import PubNubSDK // <- Here is our PubNub module import.
    ```

1. Create and configure a PubNub object:

    ```swift
    let config = PubNubConfiguration(
      publishKey: "myPublishKey",
      subscribeKey: "mySubscribeKey",
      userId: "myUniqueUserId"
    )
    let pubnub = PubNub(configuration: config)
    ```

## Add event listeners

```swift
// Create a new listener instance
let subscription = pubnub.channel("channelName").subscription()

// Add listener event callbacks
subscription.onEvent = { event in
  switch event {
  case .messageReceived(let message):
    print("Message Received: \(message) Publisher: \(message.publisher ?? "defaultUserID")")
  case .presenceChanged(let presenceChange):
    print("Presence Received: \(presenceChange)")
  case .appContextChanged(let appContextEvent):
    print("App Context Event: \(appContextEvent)")
  case .messageActionChanged(let messageActionEvent):
    print("Message Action Event: \(messageActionEvent)")
  case .fileChanged(let fileEvent):
    print("File Event: \(fileEvent)")
  case .signalReceived(let message):
    print("Signal Received: \(message) Publisher: \(message.publisher ?? "defaultUserID")")
  }
}

// Start receiving subscription events
subscription.subscribe()
```

> NOTE: You can check the UUID of the publisher of a particular message by checking the `message.publisher` property in the subscription listener. You must also provide a default value for `publisher`, as the `UUID` parameter is optional.

## Publish and subscribe

```swift
pubnub.publish(channel: "my_channel", message: "Test Message!") { result in
  switch result {
  case let .success(timetoken):
    print("The message was successfully published at: \(timetoken)")
  case let .failure(error):
    print("Handle response error: \(error.localizedDescription)")
  }
}

pubnub.subscribe(to: ["my_channel"])
```

## Documentation

* [Build your first realtime Swift app with PubNub](https://www.pubnub.com/docs/platform/quickstarts/swift)
* [API reference for Swift](https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk)
* [PubNub Swift SDK 8.x Migration Guide](https://github.com/pubnub/swift/blob/master/Documentation/PubNub_8_0_Migration_Guide.md)

## Support

If you **need help** or have a **general question**, contact <support@pubnub.com>.

## License

The PubNub Swift SDK is released under the `PubNub Software Development Kit License`.

[See LICENSE](https://github.com/pubnub/swift/blob/master/LICENSE) for details.
