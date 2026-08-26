//
//  SubscriptionSessionTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest

@testable import PubNubSDK

class SubscriptionSessionTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)
  let testChannel = "TestChannel"

  func testSubscriptionSession_PreviousTimetokenResponse() throws {
    let messageExpect = XCTestExpectation(description: "Message Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let mockResponses = ["subscription_handshake_success", "subscription_message_success", "cancelled"]
    let pubnub = PubNub(configuration: config)
    let subscriptionSession = try mockSubscriptionSession(with: mockResponses, and: config)
    let listener = SubscriptionListener()

    listener.didReceiveMessage = { _ in
      XCTAssertEqual(
        subscriptionSession.previousTokenResponse,
        SubscribeCursor(timetoken: 15614817397807903, region: 2)
      )
      subscriptionSession.unsubscribeAll()
      messageExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .connected {
        XCTAssertEqual(
          subscriptionSession.previousTokenResponse,
          SubscribeCursor(timetoken: 16873352451141050, region: 42)
        )
        statusExpect.fulfill()
      }
    }

    subscriptionSession.add(listener)
    subscriptionSession.subscribe(to: [pubnub.channel(testChannel).subscription()])

    XCTAssertEqual(subscriptionSession.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [messageExpect, statusExpect], timeout: 1.0)
  }

  func testSubscriptionSession_PreviousTimetokenResponseOnError() throws {
    let statusExpect = XCTestExpectation(description: "Status Event")
    statusExpect.assertForOverFulfill = true
    statusExpect.expectedFulfillmentCount = 2

    let mockResponses = ["badURL", "cancelled"]
    let subscriptionSession = try mockSubscriptionSession(with: mockResponses, and: config)
    let listener = SubscriptionListener()
    let pubnub = PubNub(configuration: config)

    listener.didReceiveStatus = { [unowned subscriptionSession] status in
      if case .failure = status {
        XCTAssertNil(subscriptionSession.previousTokenResponse)
        statusExpect.fulfill()
      }
      if case .success(let newStatus) = status {
        if newStatus == .connectionError(PubNubError(.invalidURL)) {
          XCTAssertNil(subscriptionSession.previousTokenResponse)
          statusExpect.fulfill()
        }
      }
    }

    subscriptionSession.add(listener)
    subscriptionSession.subscribe(to: [pubnub.channel(testChannel).subscription()], at: .init(timetoken: 123456, region: 1))

    XCTAssertEqual(subscriptionSession.subscribedChannels, [testChannel])

    defer { listener.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }

  // MARK: - Overlapping Subscriptions

  func testSubscriptionSession_UnsubscribeRetainsNameHeldByAnotherSubscription() throws {
    let mockResponses = ["subscription_handshake_success", "cancelled"]
    let subscriptionSession = try mockSubscriptionSession(with: mockResponses, and: config)
    let pubnub = PubNub(configuration: config)

    let firstSubscription = pubnub.channel(testChannel).subscription()
    let secondSubscription = pubnub.channel(testChannel).subscription()

    subscriptionSession.subscribe(to: [firstSubscription, secondSubscription])
    XCTAssertEqual(subscriptionSession.subscribedChannels, [testChannel])

    // The second subscription still holds the name, so it must stay in the Subscribe loop
    subscriptionSession.internalUnsubscribe(from: [firstSubscription])
    XCTAssertEqual(subscriptionSession.subscribedChannels, [testChannel])

    // With the last subscription holding it gone, the name leaves the Subscribe loop
    subscriptionSession.internalUnsubscribe(from: [secondSubscription])
    XCTAssertTrue(subscriptionSession.subscribedChannels.isEmpty)
  }

  func testSubscriptionSession_UnsubscribeChannelRetainsSameNamedChannelGroup() throws {
    let mockResponses = ["subscription_handshake_success", "cancelled"]
    let subscriptionSession = try mockSubscriptionSession(with: mockResponses, and: config)
    let pubnub = PubNub(configuration: config)

    // A channel and a channel group sharing a name occupy different lists in the Subscribe loop
    let channelSubscription = pubnub.channel(testChannel).subscription()
    let groupSubscription = pubnub.channelGroup(testChannel).subscription()

    subscriptionSession.subscribe(to: [channelSubscription], and: [groupSubscription])
    XCTAssertEqual(subscriptionSession.subscribedChannels, [testChannel])
    XCTAssertEqual(subscriptionSession.subscribedChannelGroups, [testChannel])

    subscriptionSession.internalUnsubscribe(from: [channelSubscription])
    XCTAssertTrue(subscriptionSession.subscribedChannels.isEmpty)
    XCTAssertEqual(subscriptionSession.subscribedChannelGroups, [testChannel])
  }

  func testSubscriptionSession_UnsubscribeRetainsNameHeldBySubscriptionSet() throws {
    let mockResponses = ["subscription_handshake_success", "cancelled"]
    let subscriptionSession = try mockSubscriptionSession(with: mockResponses, and: config)
    let pubnub = PubNub(configuration: config)

    let standaloneSubscription = pubnub.channel(testChannel).subscription()
    let subscriptionSet = pubnub.subscription(targets: [pubnub.channel(testChannel)])

    subscriptionSession.subscribe(to: [standaloneSubscription])
    subscriptionSession.registerAdapter(subscriptionSet.adapter)
    XCTAssertEqual(subscriptionSession.subscribedChannels, [testChannel])

    // The set's topology covers both lists, and it still holds the name
    subscriptionSession.internalUnsubscribe(from: [standaloneSubscription])
    XCTAssertEqual(subscriptionSession.subscribedChannels, [testChannel])
  }
}

fileprivate extension SubscriptionSessionTests {
  func mockSubscriptionSession(
    with responses: [String],
    and configuration: PubNubConfiguration
  ) throws -> SubscriptionSession {
    let dependencyContainer = DependencyContainer(configuration: configuration)
    let mockURLSession = try MockURLSession.mockSession(for: responses).session

    return dependencyContainer.register(
      value: mockURLSession,
      forKey: HTTPSubscribeSessionDependencyKey.self
    ).subscriptionSession
  }
}
