//
//  SubscriptionStreamTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class SubscriptionListenerTests: XCTestCase {
  let pubnubMessage = PubNubMessageBase(
    payload: "Message",
    actions: [],
    publisher: "Sender",
    channel: "Channel",
    subscription: "Channel",
    published: 0,
    metadata: "Message"
  )
  let connectionEvent: ConnectionStatus = .connected
  let statusEvent: SubscriptionListener.StatusEvent = .success(.connected)

  let presenceEvent = PubNubPresenceChangeBase(
    actions: [.join(uuids: ["User"]), .stateChange(uuid: "User", state: ["StateKey": "StateValue"])],
    occupancy: 1,
    timetoken: 0,
    refreshHereNow: false,
    channel: "Channel",
    subscription: "Channel"
  )

  // MARK: - Subscription Stream Defaults

  func testSessionStream_Default_Messages() {
    let stream = SubscriptionListener()
    stream.didReceiveStatus = { [weak self] event in
      XCTAssertEqual(event, self?.statusEvent)
    }

    stream.emitDidReceive(subscription: .connectionStatusChanged(connectionEvent))
    stream.emitDidReceive(subscription: .messageReceived(pubnubMessage))
    stream.emitDidReceive(subscription: .presenceChanged(presenceEvent))
  }

  func testSessionStream_Default_StatusPresence() {
    let stream = SubscriptionListener()
    stream.didReceiveMessage = { [weak self] event in
      XCTAssertEqual(try? event.transcode(), self?.pubnubMessage)
    }

    stream.emitDidReceive(subscription: .connectionStatusChanged(connectionEvent))
    stream.emitDidReceive(subscription: .messageReceived(pubnubMessage))
    stream.emitDidReceive(subscription: .presenceChanged(presenceEvent))
  }

  func testEmitDidReceiveMessage() {
    let expectation = XCTestExpectation(description: "didReceiveMessage")

    let listener = SubscriptionListener(queue: .main)
    listener.didReceiveMessage = { [weak self] event in
      XCTAssertEqual(try? event.transcode(), self?.pubnubMessage)
      expectation.fulfill()
    }

    listener.emitDidReceive(subscription: .messageReceived(pubnubMessage))

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
      XCTAssertEqual(try? event.transcode(), self?.presenceEvent)
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
