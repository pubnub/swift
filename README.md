<img width="1920" height="600" alt="swift-header" src="https://github.com/user-attachments/assets/1cb177eb-a540-421e-b6dd-89d52e740c28" />

# PubNub Swift SDK

[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpubnub%2Fswift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pubnub/swift)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/PubNubSwift.svg)](https://cocoapods.org/pods/PubNubSwift)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/ea96a32a311944eaa09b4c452db4d397)](https://app.codacy.com?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

PubNub provides global infrastructure for real-time, interactive applications.

Publish and receive messages in Swift. Use this SDK for iOS, macOS, tvOS, watchOS, and visionOS applications.

[Documentation](https://www.pubnub.com/docs/sdks/swift) · [API reference](https://www.pubnub.com/docs/sdks/swift/api-reference/publish-and-subscribe) · [Changelog](https://www.pubnub.com/docs/sdks/swift/changelog) · [Support](https://support.pubnub.com/)

## Requirements

| Requirement | Supported version or setup |
| --- | --- |
| Xcode | [Xcode 15.0 or later](https://www.pubnub.com/docs/sdks/swift) |
| Apple platforms | [iOS, macOS, tvOS, watchOS, and visionOS targets supported by the Swift SDK](https://www.pubnub.com/docs/sdks/swift/platform-support) |
| Swift Package Manager | Add `https://github.com/pubnub/swift.git`, select Up to Next Major Version from `11.0.0`, and link the `PubNubSDK` product to the application target. |

## Installation

In Xcode, choose File > Add Package Dependencies and add:

```text
https://github.com/pubnub/swift.git
```

For other installation methods, see [environment setup](https://www.pubnub.com/docs/sdks/swift).

## Quickstart

This example runs in an iOS Swift application. It subscribes to `hello_world`, publishes one message, and prints the received text.

### Get your keys

1. Open the [PubNub Admin Portal](https://admin.pubnub.com/).
2. Create an app and a keyset for development, or select an existing development keyset.
3. Copy its publish key and subscribe key.

If Access Manager is enabled, obtain a token from your trusted backend and call `pubnub.set(token: token)`. Keep the secret key on the backend.

### Send and receive a message

Place the following in an application-owned model or controller and call `start()` once during application startup:

Replace the key placeholders. Use a User ID that identifies the user or device in your app.

```swift
import Foundation
import PubNubSDK

final class PubNubHelloWorld {
  private let pubnub: PubNub
  private var subscription: Subscription?
  
  init() {
    let configuration = PubNubConfiguration(
      publishKey: "YOUR_PUBLISH_KEY",
      subscribeKey: "YOUR_SUBSCRIBE_KEY",
      userId: "hello-world-user"
    )
    
    pubnub = PubNub(configuration: configuration)
  }
  
  func start() {
    pubnub.onConnectionStateChange = { [weak self] status in
      guard status.isConnected else {
        return 
      }
      
      self?.pubnub.publish(
        channel: "hello_world",
        message: "Hello world"
      ) { result in
        if case let .failure(error) = result {
          print("Publish failed: \(error)")
        }
      }
    }
    
    subscription = pubnub
      .channel("hello_world")
      .subscription()
    
    subscription?.onMessage = { [weak self] message in
      print(message.payload)
      
      // Done with the example: release the connection listener and the subscription.
      self?.pubnub.onConnectionStateChange = nil
      self?.subscription?.unsubscribe()
    }
    
    subscription?.subscribe()
  }
}
```

### Run the example

```text
Run the application target from Xcode.
```

The Xcode console should show:

```text
Hello world
```

Keep a strong reference to the active subscription, and call `subscription.unsubscribe()` and clear `pubnub.onConnectionStateChange` when they are no longer needed.

For a complete application, see the [getting started guide](https://www.pubnub.com/docs/sdks/swift).

## Next steps

| Task | Documentation |
| --- | --- |
| Configure the client | [Configuration](https://www.pubnub.com/docs/sdks/swift/api-reference/configuration) |
| Work with subscriptions and messages | [Publish & Subscribe](https://www.pubnub.com/docs/sdks/swift/api-reference/publish-and-subscribe) |
| Check channel occupancy | [Presence](https://www.pubnub.com/docs/sdks/swift/api-reference/presence) |
| Read message history | [Message Persistence](https://www.pubnub.com/docs/sdks/swift/api-reference/storage-and-playback) |

## Build with an AI coding assistant

The [PubNub MCP server](https://www.pubnub.com/docs/ai/pubnub-mcp-server) gives an AI coding assistant access to PubNub SDK documentation and PubNub APIs. Connect the assistant to the hosted server at `https://mcp.pubnub.com`, or run `npx @pubnub/mcp@latest` locally.

The [server repository](https://github.com/pubnub/pubnub-mcp-server) has setup steps for VS Code, Cursor, Claude Code, Claude Desktop, Codex, Gemini CLI, and OpenCode.

## Before production

Use [Access Manager](https://www.pubnub.com/docs/sdks/swift/api-reference/access-manager) to grant each client the permissions it needs. Keep the secret key on your backend. Never include it in a distributed client.

Create one PubNub client and reuse it for the lifetime of the user/session. Keep strong references to active subscriptions and call `subscription.unsubscribe()` when an individual subscription is no longer needed.

Live delivery through PubNub SDKs is at-most-once. A subscriber can miss messages while disconnected or if its buffer overflows. For longer-gap recovery, see [Message Persistence](https://www.pubnub.com/docs/sdks/swift/api-reference/storage-and-playback).

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Xcode reports `No such module 'PubNubSDK'` | Add the Swift package to the correct application target and link the `PubNubSDK` product. See the [Swift SDK setup](https://www.pubnub.com/docs/sdks/swift). |
| A publish succeeds but no message appears | Check the message handler, subscription readiness, keyset, and channel name. |
| Callbacks are duplicated after recreating a SwiftUI view | Keep PubNub and its subscriptions in an owning model/service instead of constructing them from a repeatedly evaluated SwiftUI `body`. See [Publish & Subscribe](https://www.pubnub.com/docs/sdks/swift/api-reference/publish-and-subscribe). |
| Extra clients or duplicate messages during development | Do not create subscriptions from repeated SwiftUI view rendering. Own the PubNub client and subscriptions in a model/application object and unsubscribe during lifecycle cleanup. |

For setup help, see [troubleshooting](https://www.pubnub.com/docs/sdks/swift). Check [network status](https://status.pubnub.com/) for service incidents.

## Releases

Read the [changelog](https://www.pubnub.com/docs/sdks/swift/changelog) before upgrading.

For a major version change, review the migration material in the [Swift SDK repository](https://github.com/pubnub/swift/tree/master/Documentation) and the [Swift SDK changelog](https://www.pubnub.com/docs/sdks/swift/changelog).

## Support and contributions

For setup or account help, contact [PubNub Support](https://support.pubnub.com/).

For a reproducible SDK bug, use [GitHub Issues](https://github.com/pubnub/swift/issues). Include the SDK version, runtime, and a small reproduction with credentials removed.

Build the Swift package and affected Apple targets, run the repository test suite, and include tests for behavioral changes before opening a pull request.

## License

See the [PubNub Software Development Kit License](https://github.com/pubnub/swift/blob/master/LICENSE).
