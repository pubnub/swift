//
//  SubscriptionSetTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

class SubscriptionSetTests: XCTestCase {
  func testSubscriptionSet_OnMessage() {
    let expectation = XCTestExpectation(description: "Message")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let subscription = pubnub.subscription(targets: [pubnub.channel("c1"), pubnub.channel("c2")])

    subscription.onMessage = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockMessagePayload(channel: "c1"), mockMessagePayload(channel: "c2")
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_OnSignal() {
    let expectation = XCTestExpectation(description: "Signal")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let subscription = pubnub.subscription(targets: [pubnub.channel("c1"), pubnub.channel("c2")])

    subscription.onSignal = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockSignalPayload(channel: "c1"), mockSignalPayload(channel: "c2")
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_OnPresence() {
    let expectation = XCTestExpectation(description: "Presence")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let subscription = pubnub.subscription(targets: [pubnub.channel("c1"), pubnub.channel("c2")])

    subscription.onPresence = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockPresenceChangePayload(channel: "c1"), mockPresenceChangePayload(channel: "c2")
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_OnAppContext() {
    let expectation = XCTestExpectation(description: "App Context")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let subscription = pubnub.subscription(targets: [pubnub.channel("c1"), pubnub.channel("c2")])

    subscription.onAppContext = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockAppContextPayload(channel: "c1"), mockAppContextPayload(channel: "c2")
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_OnFileEvent() {
    let expectation = XCTestExpectation(description: "File")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let subscription = pubnub.subscription(targets: [pubnub.channel("c1"), pubnub.channel("c2")])

    subscription.onFileEvent = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockFilePayload(channel: "c1"), mockFilePayload(channel: "c2")
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_OnMessageAction() {
    let expectation = XCTestExpectation(description: "Message Action")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let subscription = pubnub.subscription(targets: [pubnub.channel("c1"), pubnub.channel("c2")])

    subscription.onMessageAction = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockMessageActionPayload(channel: "c1"), mockMessageActionPayload(channel: "c2")
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_OnEvents() {
    let expectation = XCTestExpectation(description: "All Events")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let subscription = pubnub.subscription(targets: [pubnub.channel("c1"), pubnub.channel("c2")])

    subscription.onEvents = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(
      payloads: [
        mockMessagePayload(channel: "c1"),
        mockMessagePayload(channel: "c2"),
        mockSignalPayload(channel: "c1"),
        mockSignalPayload(channel: "c2"),
        mockPresenceChangePayload(channel: "c1"), mockPresenceChangePayload(channel: "c2"),
        mockAppContextPayload(channel: "c1"),
        mockAppContextPayload(channel: "c2"),
        mockFilePayload(channel: "c1"),
        mockFilePayload(channel: "c2"),
        mockMessageActionPayload(channel: "c1"),
        mockMessageActionPayload(channel: "c2")
      ]
    )

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSetTopology() throws {
    let pubnub = TestPubNubFactory.make(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId"
    )

    let subscriptionSet = pubnub.subscription(
      targets: [
        pubnub.channel("c1"),
        pubnub.channel("c2"),
        pubnub.channelGroup("g1")
      ], options: ReceivePresenceEvents()
    )

    // The set iterates an unordered collection of subscriptions, so compare each list sorted
    let actualTopology = subscriptionSet.subscriptionTopology

    XCTAssertEqual(
      actualTopology.channels.sorted(by: <),
      ["c1", "c1-pnpres", "c2", "c2-pnpres"]
    )
    XCTAssertEqual(
      actualTopology.channelGroups.sorted(by: <),
      ["g1", "g1-pnpres"]
    )
  }

  func testSubscriptionSet_WithListeners_OnMessage() {
    let expectation = XCTestExpectation(description: "Message")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscriptionSet = pubnub.subscription(targets: [channel, pubnub.channel("test-channel2")])

    let listener = EventListener(onMessage: { _ in
      expectation.fulfill()
    })

    subscriptionSet.addEventListener(listener)
    subscriptionSet.onPayloadsReceived(payloads: [
      mockMessagePayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_WithListeners_OnSignal() {
    let expectation = XCTestExpectation(description: "Signal")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscriptionSet = pubnub.subscription(targets: [channel, pubnub.channel("test-channel2")])

    let listener = EventListener(onSignal: { _ in
      expectation.fulfill()
    })

    subscriptionSet.addEventListener(listener)
    subscriptionSet.onPayloadsReceived(payloads: [
      mockSignalPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_WithListeners_OnPresence() {
    let expectation = XCTestExpectation(description: "Presence")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscriptionSet = pubnub.subscription(targets: [channel, pubnub.channel("test-channel2")])

    let listener = EventListener(onPresence: { _ in
      expectation.fulfill()
    })

    subscriptionSet.addEventListener(listener)
    subscriptionSet.onPayloadsReceived(payloads: [
      mockPresenceChangePayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_WithListeners_OnMessageAction() {
    let expectation = XCTestExpectation(description: "Message Action")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscriptionSet = pubnub.subscription(targets: [channel, pubnub.channel("test-channel2")])

    let listener = EventListener(onMessageAction: { _ in
      expectation.fulfill()
    })

    subscriptionSet.addEventListener(listener)
    subscriptionSet.onPayloadsReceived(payloads: [
      mockMessageActionPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_WithListeners_OnFileEvent() {
    let expectation = XCTestExpectation(description: "File")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscriptionSet = pubnub.subscription(targets: [channel, pubnub.channel("test-channel2")])

    let listener = EventListener(onFileEvent: { _ in
      expectation.fulfill()
    })

    subscriptionSet.addEventListener(listener)
    subscriptionSet.onPayloadsReceived(payloads: [
      mockFilePayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscriptionSet_WithListeners_OnAppContext() {
    let expectation = XCTestExpectation(description: "App Context")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscriptionSet = pubnub.subscription(targets: [channel, pubnub.channel("test-channel2")])

    let listener = EventListener(onAppContext: { _ in
      expectation.fulfill()
    })

    subscriptionSet.addEventListener(listener)
    subscriptionSet.onPayloadsReceived(payloads: [
      mockAppContextPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }
}
