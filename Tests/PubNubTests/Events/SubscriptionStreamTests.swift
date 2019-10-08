//
//  SubscriptionListenerTests.swift
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

class SubscriptionListenerTests: XCTestCase {
  struct MockStatusStream: SubscriptionStream {
    let uuid: UUID = UUID()

    var statusEvent: ((StatusEvent) -> Void)?

    func emitDidReceive(status event: StatusEvent) {
      statusEvent?(event)
    }
  }

  struct MockMessageStream: SubscriptionStream {
    let uuid: UUID = UUID()

    var messageEvent: ((MessageEvent) -> Void)?

    func emitDidReceive(message event: MessageEvent) {
      messageEvent?(event)
    }
  }

  struct MockMessageEvent: MessageEvent, Equatable {
    var messageType: MessageType = .message
    var publisher: String? = "Sender"
    var payload: AnyJSON = "Message"
    var channel: String = "Channel"
    var subscription: String? = "Channel"
    var timetoken: Timetoken = 0
    var userMetadata: AnyJSON? = "Message"
  }

  let messageEvent: MessageEvent = MockMessageEvent()
  let connectionEvent: ConnectionStatus = .connected
  let statusEvent: StatusEvent = .success(.connected)
  let presenceEvent: PresenceEvent = PresenceEventPayload(channel: "Channel",
                                                          subscriptionMatch: "Channel",
                                                          senderTimetoken: 0,
                                                          presenceTimetoken: 0,
                                                          metadata: "Metadata",
                                                          event: .join,
                                                          occupancy: 1,
                                                          join: ["User"],
                                                          leave: [],
                                                          timeout: [],
                                                          stateChange: ["Channel": ["StateKey": "StateValue"]])

  // MARK: - Subscription Stream Defaults

  func testSessionStream_Default_Messages() {
    var stream = MockStatusStream()
    stream.statusEvent = { [weak self] event in
      XCTAssertEqual(event, self?.statusEvent)
    }

    stream.emitDidReceive(subscription: .connectionStatusChanged(connectionEvent))
    stream.emitDidReceive(subscription: .messageReceived(messageEvent))
    stream.emitDidReceive(subscription: .presenceChanged(presenceEvent))
  }

  func testSessionStream_Default_StatusPresence() {
    var stream = MockMessageStream()
    stream.messageEvent = { [weak self] event in
      XCTAssertEqual(event as? MockMessageEvent, self?.messageEvent as? MockMessageEvent)
    }

    stream.emitDidReceive(subscription: .connectionStatusChanged(connectionEvent))
    stream.emitDidReceive(subscription: .messageReceived(messageEvent))
    stream.emitDidReceive(subscription: .presenceChanged(presenceEvent))
  }

  func testEmitDidReceiveMessage() {
    let expectation = XCTestExpectation(description: "didReceiveMessage")

    let listener = SubscriptionListener(queue: .main)
    listener.didReceiveMessage = { [weak self] event in
      XCTAssertNotNil(event as? MockMessageEvent)
      XCTAssertEqual(event as? MockMessageEvent, self?.messageEvent as? MockMessageEvent)
      expectation.fulfill()
    }

    listener.emitDidReceive(subscription: .messageReceived(messageEvent))

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - SubscriptionListener

  func testEmitDidReceiveStatus() {
    let expectation = XCTestExpectation(description: "didReceiveStatus")
    let listener = SubscriptionListener()
    listener.didReceiveStatus = { [weak self] event in
      XCTAssertEqual(event, self?.statusEvent)
      expectation.fulfill()
    }

    listener.emitDidReceive(subscription: .connectionStatusChanged(connectionEvent))

    wait(for: [expectation], timeout: 1.0)
  }

  func testEmitDidReceivePresence() {
    let expectation = XCTestExpectation(description: "didReceivePresence")
    let listener = SubscriptionListener()
    listener.didReceivePresence = { [weak self] event in
      XCTAssertNotNil(event as? PresenceEventPayload)
      XCTAssertEqual(event as? PresenceEventPayload, self?.presenceEvent as? PresenceEventPayload)
      expectation.fulfill()
    }

    listener.emitDidReceive(subscription: .presenceChanged(presenceEvent))

    wait(for: [expectation], timeout: 1.0)
  }

  func testEquatable() {
    let listener = SubscriptionListener()
    let copy = listener
    XCTAssertEqual(listener, copy)
    XCTAssertNotEqual(SubscriptionListener(), SubscriptionListener())
  }
}
