# PubNub Swift SDK

[![Platform](https://img.shields.io/cocoapods/p/PubNubSwift.svg?style=flat)](https://img.shields.io/cocoapods/p/PubNubSwift.svg)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/PubNubSwift.svg)](https://img.shields.io/cocoapods/v/PubNubSwift.svg)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/pubnub/swift.svg?branch=master)](https://travis-ci.org/pubnub/swift)
[![Codacy Coverage Grade Badge](https://api.codacy.com/project/badge/Grade/d6dbd8cad97d42bbb72c47137e94d6f5)](https://www.codacy.com?utm_source=github.com&utm_medium=referral&utm_content=pubnub/swift&utm_campaign=Badge_Grade)
[![Codacy Badge](https://api.codacy.com/project/badge/Coverage/d6dbd8cad97d42bbb72c47137e94d6f5)](https://www.codacy.com?utm_source=github.com&utm_medium=referral&utm_content=pubnub/swift&utm_campaign=Badge_Coverage)

-   [Requirements](#requirements)
-   [Installation](#installation)
-   [Communication](#communication)
-   [Documentation](#documentation)
-   [License](#license)

## Requirements

-   iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
-   Xcode 10.2+
-   Swift 5+

## Installation

The PubNub Swift SDK doesn't contain any external dependencies.

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
  pod 'PubNubSwift', '~> 1.0.0'
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
github "pubnub/swift" ~> 1.0
```

Then in the directory containing your `Cartfile`, execute the following:

```bash
carthage update
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

Create or edit a `Package.swift` file to include:

-   Inside your root level `dependencies` array add:

```swift
.package(url: "https://github.com/pubnub/swift.git", from: "1.0.0")
```

-   Inside your `targets` array add `PubNub` as a dependency:

```swift
.target(name: "YOUR_TARGET_NAME", dependencies: ["PubNub"])
```

When you are finished it should looked similar to the example below:

```swift
// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "YOUR_TARGET_NAME",
  dependencies: [
    .package(url: "https://github.com/pubnub/swift.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "YOUR_TARGET_NAME", dependencies: ["PubNub"])
  ]
)
```

> Note: Ensure that you replace `YOUR_TARGET_NAME` with your target's name

Then in the directory containing your `Package.swift`, execute the following:

```bash
swift build
```

## Documentation

Check out our official [docs page](https://www.pubnub.com/docs/swift/pubnub-swift-sdk).

## Communication

If you **need help** or have a **general question**, contact [support](mailto:support@pubnub.com)

## License

The PubNub Swift SDK is released under the MIT license.
[See LICENSE](https://github.com/pubnub/swift/blob/master/LICENSE) for details.
