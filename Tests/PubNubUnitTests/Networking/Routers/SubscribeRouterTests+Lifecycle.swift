//
//  SubscribeRouterTests+Lifecycle.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

// MARK: - Unsubscribe

extension SubscribeRouterTests {
  func test_Unsubscribe_WithSingleChannel_RemovesChannelFromSubscription() throws {
    let pubnub = PubNub(configuration: config)
    let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    let mock = try mockSubscription(responses: mockResponses, configuration: config)
    let connectedExpect = expectation(description: "Connected")
    let disconnectedExpect = expectation(description: "Disconnected")

    mock.listener.didReceiveStatus = { status in
      do {
        let status = try status.get()
        switch status {
        case .connected:
          connectedExpect.fulfill()
        case .disconnected:
          disconnectedExpect.fulfill()
        default:
          break
        }
      } catch {
        XCTFail("Unexpected status error: \(error)")
      }
    }

    mock.session.subscribe(to: [pubnub.channel(testChannel).subscription()])
    wait(for: [connectedExpect], timeout: 1.0)

    XCTAssertEqual(mock.session.subscribedChannels, [testChannel])
    mock.session.unsubscribe(from: [testChannel])
    XCTAssertEqual(mock.session.subscribedChannels, [])

    wait(for: [disconnectedExpect], timeout: 1.0)
    mock.listener.cancel()
  }

  func test_UnsubscribeAll_WithMultipleChannels_RemovesAllChannels() throws {
    let otherChannel = "OtherChannel"
    let pubnub = PubNub(configuration: config)
    let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    let mock = try mockSubscription(responses: mockResponses, configuration: config)
    let connectedExpect = expectation(description: "Connected")
    let disconnectedExpect = expectation(description: "Disconnected")

    mock.listener.didReceiveStatus = { status in
      do {
        let status = try status.get()
        switch status {
        case .connected:
          connectedExpect.fulfill()
        case .disconnected:
          disconnectedExpect.fulfill()
        default:
          break
        }
      } catch {
        XCTFail("Unexpected status error: \(error)")
      }
    }

    mock.session.subscribe(to: [
      pubnub.channel(testChannel).subscription(),
      pubnub.channel(otherChannel).subscription()
    ])

    wait(for: [connectedExpect], timeout: 1.0)

    XCTAssertTrue(mock.session.subscribedChannels.contains(testChannel))
    XCTAssertTrue(mock.session.subscribedChannels.contains(otherChannel))
    mock.session.unsubscribeAll()
    XCTAssertEqual(mock.session.subscribedChannels, [])

    wait(for: [disconnectedExpect], timeout: 1.0)
    mock.listener.cancel()
  }
}

// MARK: - Error Handling

extension SubscribeRouterTests {
  func test_Subscribe_WithInvalidJSON_ReturnsDecodingError() throws {
    let corruptBase64Response = [
      "eyJ0Ijp7InQiOiIxNTkxMjE4MzQ0MTUyNjM1MCIsInIiOjF9LCJtIjpbeyJhIjoiMyIsImYiOjUx",
      "MiwicCI6eyJ0IjoiMTU5MTIxODM0NDE1NTQyMDAiLCJyIjoxfSwiayI6ImRlbW8tMzYiLCJjIjoi",
      "c3dpZnRJbnZhbGlkSlNPTi7/IiwiZCI6ImhlbGxvIiwiYiI6InN3aWZ0SW52YWxpZEpTT04uKiJ9",
      "XX0="
    ].joined()

    let corruptedData = try XCTUnwrap(Data(base64Encoded: corruptBase64Response))
    let mockResponses = ["subscription_handshake_success", "subscription_invalid_json", "cancelled"]
    let mock = try mockSubscription(responses: mockResponses, rawData: [corruptedData], configuration: config)
    let pubnub = PubNub(configuration: config)
    let errorExpect = expectation(description: "Subscribe error")
    let disconnectExpect = expectation(description: "Connection error")

    mock.listener.didReceiveSubscription = { [mock] event in
      if case let .subscribeError(error) = event {
        XCTAssertEqual(error.reason, .jsonDataDecodingFailure)
        mock.session.unsubscribeAll()
        errorExpect.fulfill()
      } else if case .connectionStatusChanged(.connectionError) = event {
        disconnectExpect.fulfill()
      }
    }

    mock.session.subscribe(to: [pubnub.channel(testChannel).subscription()])
    defer { mock.listener.cancel() }
    wait(for: [errorExpect, disconnectExpect], timeout: 1.0, enforceOrder: true)
  }
}
