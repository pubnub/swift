//
//  SubscribeEndpointTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

@testable import PubNub
import XCTest

final class SubscribeEndpointTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")
  let testChannel = "TestChannel"

  // MARK: - Endpoint Tests

  func testSubscribe_Endpoint() {
    let endpoint = Endpoint.subscribe(channels: ["TestChannel"],
                                      groups: [],
                                      timetoken: 0,
                                      region: nil,
                                      state: nil,
                                      heartbeat: nil,
                                      filter: nil)

    XCTAssertEqual(endpoint.description, "Subscribe")
    XCTAssertEqual(endpoint.rawValue, .subscribe)
    XCTAssertEqual(endpoint.operationCategory, .subscribe)
    XCTAssertNil(endpoint.validationError)
  }

  func testSubscribe_Endpoint_ValidationError() {
    let endpoint = Endpoint.subscribe(channels: [],
                                      groups: [],
                                      timetoken: 0,
                                      region: nil,
                                      state: nil,
                                      heartbeat: nil,
                                      filter: nil)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PNError.invalidEndpointType(endpoint))
  }

  func testSubscribe_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.subscribe(channels: ["SomeChannel"],
                                      groups: ["SomeGroup"],
                                      timetoken: 0,
                                      region: "1",
                                      state: ["Channel": [:]],
                                      heartbeat: 2,
                                      filter: "Filter")

    XCTAssertEqual(endpoint.associatedValues["channels"] as? [String], ["SomeChannel"])
    XCTAssertEqual(endpoint.associatedValues["groups"] as? [String], ["SomeGroup"])
    XCTAssertEqual(endpoint.associatedValues["timetoken"] as? Timetoken, 0)
    XCTAssertEqual(endpoint.associatedValues["region"] as? String, "1")
    XCTAssertNotNil(endpoint.associatedValues["state"] as? ChannelPresenceState)
    XCTAssertEqual(endpoint.associatedValues["heartbeat"] as? Int, 2)
    XCTAssertEqual(endpoint.associatedValues["filter"] as? String, "Filter")
  }

  // MARK: - Message Response

  func testSubscribe_Message() {
    let messageExpect = XCTestExpectation(description: "Message Event")
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_message_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveMessage = { [weak self] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.messageType, .message)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      messageExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .cancelled {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [messageExpect, statusExpect], timeout: 1.0)
  }

  // MARK: - Presence Response

  func testSubscribe_Presence() {
    let presenceExpect = XCTestExpectation(description: "Presence Event")
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_presence_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceivePresence = { [weak self] presence in
      XCTAssertEqual(presence.channel, self?.testChannel)
      XCTAssertEqual(presence.event, .interval)
      XCTAssertEqual(presence.join, ["db9c5e39-7c95-40f5-8d71-125765b6f561"])
      presenceExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .cancelled {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [presenceExpect, statusExpect], timeout: 1.0)
  }

  func testSubscribe_Presence_Failure() {}

  // MARK: - Signal Response

  func testSubscribe_Signal() {
    let signalExpect = XCTestExpectation(description: "Signal Event")
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_signal_success",
                                                              "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveSignal = { [weak self] signal in
      XCTAssertEqual(signal.channel, self?.testChannel)
      XCTAssertEqual(signal.messageType, .signal)
      XCTAssertEqual(signal.publisher, "TestUser")
      XCTAssertEqual(signal.payload.stringOptional, "Test Signal")
      signalExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .cancelled {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [signalExpect, statusExpect], timeout: 1.0)
  }

  // MARK: - Mixed Response

  func testSubscribe_Mixed() {
    let messageExpect = XCTestExpectation(description: "Message Event")
    let presenceExpect = XCTestExpectation(description: "Presence Event")
    let signalExpect = XCTestExpectation(description: "Signal Event")
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_mixed_success", "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveMessage = { [weak self] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.messageType, .message)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      messageExpect.fulfill()
    }
    listener.didReceivePresence = { [weak self] presence in
      XCTAssertEqual(presence.channel, self?.testChannel)
      XCTAssertEqual(presence.join, ["db9c5e39-7c95-40f5-8d71-125765b6f561"])
      presenceExpect.fulfill()
    }
    listener.didReceiveSignal = { [weak self] signal in
      XCTAssertEqual(signal.channel, self?.testChannel)
      XCTAssertEqual(signal.messageType, .signal)
      XCTAssertEqual(signal.payload.stringOptional, "Test Signal")
      signalExpect.fulfill()
    }
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .cancelled {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])

    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    defer { token.cancel() }
    wait(for: [signalExpect, statusExpect], timeout: 1.0)
  }

  // MARK: - Unsubscribe

  func testUnsubscribe() {
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_mixed_success", "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .connected {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel])
    XCTAssertEqual(subscription.subscribedChannels, [testChannel])

    subscription.unsubscribe(from: [testChannel])
    XCTAssertEqual(subscription.subscribedChannels, [])

    defer { token.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }

  func testUnsubscribeAll() {
    let statusExpect = XCTestExpectation(description: "Status Event")

    guard let session = try? MockURLSession.mockSession(for: ["subscription_mixed_success", "cancelled"]).session else {
      return XCTFail("Could not create mock url session")
    }

    let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)

    let listener = SubscriptionListener()
    listener.didReceiveStatus = { status in
      if let status = try? status.get(), status == .connected {
        statusExpect.fulfill()
      }
    }
    let token = subscription.add(listener)

    subscription.subscribe(to: [testChannel, "OtherChannel"])
    let diff = subscription.subscribedChannels
      .symmetricDifference([testChannel, "OtherChannel"])
    XCTAssertTrue(diff.isEmpty)

    subscription.unsubscribeAll()
    XCTAssertEqual(subscription.subscribedChannels, [])

    defer { token.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }
}
