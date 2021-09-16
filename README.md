# PubNub Swift SDK

[![Platform](https://img.shields.io/cocoapods/p/PubNubSwift.svg?style=flat)](https://img.shields.io/cocoapods/p/PubNubSwift.svg)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/PubNubSwift.svg)](https://img.shields.io/cocoapods/v/PubNubSwift.svg)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/pubnub/swift.svg?branch=master)](https://travis-ci.org/pubnub/swift)
[![Codacy Coverage Grade Badge](https://api.codacy.com/project/badge/Grade/d6dbd8cad97d42bbb72c47137e94d6f5)](https://www.codacy.com?utm_source=github.com&utm_medium=referral&utm_content=pubnub/swift&utm_campaign=Badge_Grade)

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

* iOS 9.0+ / macOS 10.11+ / Mac Catalyst 13.0+ / tvOS 9.0+ / watchOS 2.0+
* Xcode 11+
* Swift 5+

The PubNub Swift SDK doesn't contain any external dependencies.

## Get keys

You will need the publish and subscribe keys to authenticate your app. Get your keys from the [Admin Portal](https://dashboard.pubnub.com/).

## Set up your project

You have several options to set up your project. We provide instructions here for [Swift Package Manager](#swift-package-manager), [CocoaPods](#cocoapods), and [Carthage](#carthage).

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

1. Create or open your project inside of Xcode
1. Navigate to File > Swift Packages > Add Package Dependency
1. Search for PubNub and select the swift package owned by pubnub, and hit the Next button
1. Use the `Up to Next Major Version` rule spanning from `4.0.0` < `5.0.0`, and hit the Next button

For more information see Apple's guide on [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
  pod 'PubNubSwift', '~> 4.0'
end
```

> Note: Replace `YOUR_TARGET_NAME` with your target's name.

In the directory containing your `Podfile`. execute the following:

```bash
pod install
```

### [Carthage](https://github.com/Carthage/Carthage)

Officially supported: Carthage 0.33 and up.

Add the following to `Cartfile`:

```ruby
github "pubnub/swift" ~> 4.0
```

Then in the directory containing your `Cartfile`, execute the following:

```bash
carthage update
```

## Configure PubNub

1. Import the module named `PubNub` inside your AppDelegate:

    ```swift
    import UIKit
    import PubNub // <- Here is our PubNub module import.
    ```

1. Create and configure a PubNub object:

    ```swift
    var config = PubNubConfiguration(
      publishKey: "myPublishKey",
      subscribeKey: "mySubscribeKey",
      uuid: "myUniqueUUID"
    )
    let pubnub = PubNub(configuration: config)
    ```

## Add event listeners

```swift
// Create a new listener instance
let listener = SubscriptionListener()

// Add listener event callbacks
listener.didReceiveSubscription = { event in
  switch event {
  case let .messageReceived(message):
    print("Message Received: \(message) Publisher: \(message.publisher ?? "defaultUUID")")
  case let .connectionStatusChanged(status):
    print("Status Received: \(status)")
  case let .presenceChanged(presence):
    print("Presence Received: \(presence)")
  case let .subscribeError(error):
    print("Subscription Error \(error)")
  default:
    break
  }
}

// Start receiving subscription events
pubnub.add(listener)
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
* [PubNub Swift SDK 3.x Migration Guide](https://github.com/pubnub/swift/blob/master/Documentation/PubNub_3_0_Migration_Guide.md)

## Support

If you **need help** or have a **general question**, contact <support@pubnub.com>.

## License

The PubNub Swift SDK is released under the MIT license.
[See LICENSE](https://github.com/pubnub/swift/blob/master/LICENSE) for details.
