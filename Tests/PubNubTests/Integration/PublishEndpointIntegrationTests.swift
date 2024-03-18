//
//  PublishEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
import XCTest

class PublishEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: PublishEndpointIntegrationTests.self)

  func testPublishEndpoint() {
    let publishExpect = expectation(description: "Publish Response")
    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.publish(channel: "SwiftITest", message: "TestPublish") { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      publishExpect.fulfill()
    }

    wait(for: [publishExpect], timeout: 10.0)
  }

  func testSignalTooLong() {
    let publishExpect = expectation(description: "Publish Response")
    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    client.signal(
      channel: "SwiftITest",
      message: ["$": "35.75", "HI": "b62", "t": "BO"]
    ) { result in
      switch result {
      case .success:
        XCTFail("Publish should fail")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, PubNubError.Reason.messageTooLong)
      }
      publishExpect.fulfill()
    }

    wait(for: [publishExpect], timeout: 10.0)
  }

  func testCompressedPublishEndpoint() {
    let compressedPublishExpect = expectation(description: "Compressed Publish Response")
    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.publish(
      channel: "SwiftITest",
      message: "TestCompressedPublish",
      shouldCompress: true
    ) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      compressedPublishExpect.fulfill()
    }

    wait(for: [compressedPublishExpect], timeout: 10.0)
  }

  func testFireEndpoint() {
    let fireExpect = expectation(description: "Fire Response")
    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.fire(channel: "SwiftITest", message: "TestFire") { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fireExpect.fulfill()
    }

    wait(for: [fireExpect], timeout: 10.0)
  }

  func testSignalEndpoint() {
    let signalExpect = expectation(description: "Signal Response")
    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.signal(channel: "SwiftITest", message: "TestSignal") { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      signalExpect.fulfill()
    }

    wait(for: [signalExpect], timeout: 10.0)
  }

  func testPushblishEscapedString() {
    let message = "{\"text\": \"bob\", \"duckName\": \"swiftduck\"}"
    let publishExpect = expectation(description: "Publish Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.publish(channel: "SwiftITest", message: message) { result in
      switch result {
      case .success:
        XCTFail("Publish should fail")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, PubNubError.Reason.requestContainedInvalidJSON)
      }
      publishExpect.fulfill()
    }

    wait(for: [publishExpect], timeout: 10.0)
  }

  func testPublishPushPayload() {
    let publishExpect = expectation(description: "Publish Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let pushMessage = PubNubPushMessage(
      apns: PubNubAPNSPayload(
        aps: APSPayload(alert: .object(.init(title: "Apple Message")), badge: 1, sound: .string("default")),
        pubnub: [.init(targets: [.init(topic: "com.pubnub.swift", environment: .production)], collapseID: "SwiftSDK")],
        payload: "Push Message from PubNub Swift SDK"
      ),
      fcm: PubNubFCMPayload(
        payload: "Push Message from PubNub Swift SDK",
        target: .topic("com.pubnub.swift"),
        notification: FCMNotificationPayload(title: "Android Message"),
        android: FCMAndroidPayload(collapseKey: "SwiftSDK", notification: FCMAndroidNotification(sound: "default"))
      ),
      additional: "Push Message from PubNub Swift SDK"
    )

    // Publish a simple message to the demo_tutorial channel
    client.publish(channel: "SwiftITest", message: pushMessage) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      publishExpect.fulfill()
    }

    wait(for: [publishExpect], timeout: 10.0)
  }

  func testPublish_WithCryptoModulesFromDifferentClients() {
    let firstClient = PubNub(configuration: PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId,
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "someKey")
    ))
    let secondClient = PubNub(configuration: PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId,
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "anotherKey")
    ))

    let channelForFistClient = "ChannelA"
    let channelForSecondClient = "ChannelB"

    let publishExpect = expectation(description: "Publish Response")
    publishExpect.assertForOverFulfill = true
    publishExpect.expectedFulfillmentCount = 2

    let subscribeExpect = expectation(description: "Subscribe Response")
    subscribeExpect.assertForOverFulfill = true
    subscribeExpect.assertForOverFulfill = true

    for client in [firstClient, secondClient] {
      client.onConnectionStateChange = { [unowned client] newStatus in
        if newStatus == .connected {
          client.publish(
            channel: client === firstClient ? channelForFistClient : channelForSecondClient,
            message: "This is a message"
          ) { result in
            switch result {
            case .success:
              publishExpect.fulfill()
            case let .failure(error):
              XCTFail("Unexpected failure: \(error)")
            }
          }
        }
      }
    }

    let subscription = firstClient.channel(channelForFistClient).subscription()
    let subscriptionFromSecondClient = secondClient.channel(channelForSecondClient).subscription()

    subscription.onMessage = { message in
      XCTAssertEqual(message.payload.stringOptional, "This is a message")
      subscribeExpect.fulfill()
    }
    subscriptionFromSecondClient.onMessage = { message in
      XCTAssertEqual(message.payload.stringOptional, "This is a message")
      subscribeExpect.fulfill()
    }
    subscription.subscribe()
    subscriptionFromSecondClient.subscribe()

    wait(for: [publishExpect, subscribeExpect], timeout: 10.0)
  }
}
