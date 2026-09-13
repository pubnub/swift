//
//  SubscribeRouterTests+Crypto.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

// MARK: - Subscription with CryptoModule enabled

extension SubscribeRouterTests {
  func test_Subscribe_WithCryptoAndNonEncryptedMessage_ReturnsDecryptionFailure() throws {
    let messageExpect = XCTestExpectation(description: "Message Event")
    messageExpect.assertForOverFulfill = true
    messageExpect.expectedFulfillmentCount = 1

    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
    )
    let mockResponses = [
      "subscription_handshake_success",
      "subscription_message_success",
      "cancelled"
    ]
    let container = DependencyContainer(configuration: config).register(
      value: try XCTUnwrap(MockURLSession.mockSession(for: mockResponses).session),
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let pubnub = PubNub(container: container)
    let listener = SubscriptionListener()

    listener.didReceiveMessage = { [weak self, unowned pubnub] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      XCTAssertTrue(message.error?.reason == .decryptionFailure)
      pubnub.unsubscribeAll()
      messageExpect.fulfill()
    }

    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel])

    defer { listener.cancel() }
    wait(for: [messageExpect], timeout: 1.0)
  }

  func test_Subscribe_WithCryptoAndEncryptedMessage_ReturnsDecryptedMessage() throws {
    let messageExpect = XCTestExpectation(description: "Message Event")
    messageExpect.assertForOverFulfill = true
    messageExpect.expectedFulfillmentCount = 1

    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
    )
    let mockResponses = [
      "subscription_handshake_success",
      "subscription_encrypted_message_success",
      "cancelled"
    ]
    let container = DependencyContainer(configuration: config).register(
      value: try XCTUnwrap(MockURLSession.mockSession(for: mockResponses).session),
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let pubnub = PubNub(container: container)
    let listener = SubscriptionListener()

    listener.didReceiveMessage = { [weak self, unowned pubnub] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      XCTAssertNil(message.error)
      pubnub.unsubscribeAll()
      messageExpect.fulfill()
    }

    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel])

    defer { listener.cancel() }
    wait(for: [messageExpect], timeout: 1.0)
  }

  func test_Subscribe_WithMismatchedCryptoKey_ReturnsDecryptionFailure() throws {
    let messageExpect = XCTestExpectation(description: "Message Event")
    messageExpect.assertForOverFulfill = true
    messageExpect.expectedFulfillmentCount = 1

    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "lorem-ipsum-dolor-sit-amet")
    )
    let mockResponses = [
      "subscription_handshake_success",
      "subscription_encrypted_message_success",
      "cancelled"
    ]
    let container = DependencyContainer(configuration: config).register(
      value: try XCTUnwrap(MockURLSession.mockSession(for: mockResponses).session),
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let pubnub = PubNub(container: container)
    let listener = SubscriptionListener()

    listener.didReceiveMessage = { [weak self, unowned pubnub] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.payload.stringOptional, "UE5FRAFBQ1JIEGOmGQMIMXD+91V+5hTxm7p7uEUhEEYohYLQz5fEGITC")
      XCTAssertTrue(message.error?.reason == .decryptionFailure)
      pubnub.unsubscribeAll()
      messageExpect.fulfill()
    }

    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel])

    defer { listener.cancel() }
    wait(for: [messageExpect], timeout: 1.0)
  }
}
