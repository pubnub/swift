# PubNub Swift SDK

[![Platform](https://img.shields.io/cocoapods/p/PubNubSwift.svg?style=flat)](https://img.shields.io/cocoapods/p/PubNubSwift.svg)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/PubNubSwift.svg)](https://img.shields.io/cocoapods/v/PubNubSwift.svg)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/pubnub/swift.svg?branch=master)](https://travis-ci.org/pubnub/swift)
[![Codacy Coverage Grade Badge](https://api.codacy.com/project/badge/Grade/d6dbd8cad97d42bbb72c47137e94d6f5)](https://www.codacy.com?utm_source=github.com&utm_medium=referral&utm_content=pubnub/swift&utm_campaign=Badge_Grade)

-   [Requirements](#requirements)
-   [Installation](#installation)
-   [Migration](#migration)
-   [Communication](#communication)
-   [Documentation](#documentation)
-   [License](#license)

## Requirements

-   iOS 8.0+ / macOS 10.10+ / Mac Catalyst 13.0+ / tvOS 9.0+ / watchOS 2.0+
-   Xcode 11+
-   Swift 5+

## Installation

The PubNub Swift SDK doesn't contain any external dependencies.

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

- Create or open your project inside of Xcode
- Select File -> Swift Packages -> Add Package Dependency...
- Search for PubNub and select the swift package owned by pubnub, and hit the Next button
- Use the `Up to Next Major Version` rule spanning from `3.0.0` < `4.0.0`, and hit the Next button

For more information see Apple's guide on [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
  pod 'PubNubSwift', '~> 3.0'
end
```

> Note: Replace `YOUR_TARGET_NAME` with your target's name.

In the directory containing your `Podfile`. execute the following:

```bash
pod install
```

### [Carthage](https://github.com/Carthage/Carthage)

Officially supported: Carthage 0.33 and up.

Add this to `Cartfile`

```ruby
github "pubnub/swift" ~> 3.0
```

Then in the directory containing your `Cartfile`, execute the following:

```bash
carthage update
```

## Migration Guides
[PubNub 3.0 Migration Guide](https://github.com/pubnub/swift/blob/master/Documentation/PubNub_3_0_Migration_Guide.md)

## Documentation

Check out our official [docs page](https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk).

## Communication

If you **need help** or have a **general question**, contact [support](mailto:support@pubnub.com)

## License

The PubNub Swift SDK is released under the MIT license.
[See LICENSE](https://github.com/pubnub/swift/blob/master/LICENSE) for details.
