//
//  SubscribeRouterTests+CoreEvents.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

// MARK: - Message Response

extension SubscribeRouterTests {
  func test_Subscribe_WithMessageEvent_ReceivesExpectedMessage() throws {
    let event = try decodeEvent(from: "subscription_message_success")
    let message = try XCTUnwrap(event.message)

    XCTAssertEqual(message.channel, testChannel)
    XCTAssertEqual(message.payload.stringOptional, "Test Message")
  }
}

// MARK: - Signal Response

extension SubscribeRouterTests {
  func test_Subscribe_WithSignalEvent_ReceivesExpectedSignal() throws {
    let event = try decodeEvent(from: "subscription_signal_success")
    let signal = try XCTUnwrap(event.signal)

    XCTAssertEqual(signal.channel, testChannel)
    XCTAssertEqual(signal.publisher, "TestUser")
    XCTAssertEqual(signal.payload.stringOptional, "Test Signal")
  }
}

// MARK: - Presence Response

extension SubscribeRouterTests {
  func test_Subscribe_WithPresenceEvent_ReceivesJoinAndLeaveActions() throws {
    let event = try decodeEvent(from: "subscription_presence_success")
    let presence = try XCTUnwrap(event.presence)

    XCTAssertEqual(presence.channel, testChannel)
    XCTAssertEqual(presence.actions, [
      .join(uuids: ["db9c5e39-7c95-40f5-8d71-125765b6f561", "vqwqvae39-7c95-40f5-8d71-25234165142"]),
      .leave(uuids: ["234vq2343-7c95-40f5-8d71-125765b6f561", "42vvsge39-7c95-40f5-8d71-25234165142"])
    ])
  }
}

// MARK: - Unrecognized Message Types

extension SubscribeRouterTests {
  func test_Subscribe_WithUnrecognizedMessageType_DropsMessageAndKeepsRestOfBatch() throws {
    let response = try decodeSubscribeResponse(from: "subscription_unknownMessageType_success")

    XCTAssertEqual(response.messages.map { $0.messageType }, [.message, .signal])
    XCTAssertEqual(response.messages.map { $0.payload.stringOptional }, ["Test Message", "Test Signal"])
    XCTAssertEqual(response.cursor, SubscribeCursor(timetoken: 15_614_817_397_807_903, region: 2))
  }

  func test_Subscribe_WithMissingMessageType_InfersTypeFromChannel() throws {
    let response = try decodeSubscribeResponse(from: "subscription_mixed_success")

    // The first message of the batch omits `e` entirely, and the last one arrives on a presence channel without `e`
    XCTAssertEqual(response.messages.map { $0.messageType }, [.message, .signal, .presence])
  }

  func test_Subscribe_WithUnrecognizedMessageType_EmitsNoMessageEvent() throws {
    let messageExpect = XCTestExpectation(description: "Message Event")
    messageExpect.assertForOverFulfill = true
    messageExpect.expectedFulfillmentCount = 1

    let mockResponses = [
      "subscription_handshake_success",
      "subscription_unknownMessageType_success",
      "cancelled"
    ]
    let container = DependencyContainer(configuration: config).register(
      value: try XCTUnwrap(MockURLSession.mockSession(for: mockResponses).session),
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let pubnub = PubNub(container: container)
    let listener = SubscriptionListener()

    // Unrecognized message types would otherwise be delivered as regular messages,
    // over-fulfilling this expectation
    listener.didReceiveMessage = { [weak self, unowned pubnub] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      pubnub.unsubscribeAll()
      messageExpect.fulfill()
    }

    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel])

    defer { listener.cancel() }
    wait(for: [messageExpect], timeout: 1.0)
  }
}

// MARK: Helpers

private extension PubNubEvent {

  var signal: PubNubMessage? {
    guard case let .signalReceived(s) = self else { return nil }
    return s
  }

  var presence: PubNubPresenceChange? {
    guard case let .presenceChanged(p) = self else { return nil }
    return p
  }
}
