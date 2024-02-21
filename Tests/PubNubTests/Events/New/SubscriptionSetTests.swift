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
@testable import PubNub

class SubscriptionSetTests: XCTestCase {
  private let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId"
    )
  )
  
  func testSubscriptionSet_VariousPayloads() {
    let messagesExpectation = XCTestExpectation(description: "Message")
    messagesExpectation.assertForOverFulfill = true
    messagesExpectation.expectedFulfillmentCount = 2

    let signalExpectation = XCTestExpectation(description: "Signal")
    signalExpectation.assertForOverFulfill = true
    signalExpectation.expectedFulfillmentCount = 2

    let messageAction = XCTestExpectation(description: "Message Action")
    messageAction.assertForOverFulfill = true
    messageAction.expectedFulfillmentCount = 2

    let presenceChangeExpectation = XCTestExpectation(description: "Presence")
    presenceChangeExpectation.assertForOverFulfill = true
    presenceChangeExpectation.expectedFulfillmentCount = 2

    let appContextExpectation = XCTestExpectation(description: "App Context")
    appContextExpectation.assertForOverFulfill = true
    appContextExpectation.expectedFulfillmentCount = 2

    let fileExpectation = XCTestExpectation(description: "File")
    fileExpectation.assertForOverFulfill = true
    fileExpectation.expectedFulfillmentCount = 2

    let allEventsExpectation = XCTestExpectation(description: "All Events")
    allEventsExpectation.assertForOverFulfill = true
    allEventsExpectation.expectedFulfillmentCount = 2
    
    let singleEventExpectation = XCTestExpectation(description: "Single Event")
    singleEventExpectation.expectedFulfillmentCount = 12
    singleEventExpectation.assertForOverFulfill = true
    
    let subscription = pubnub.subscription(entities: [
      pubnub.channel("c1"),
      pubnub.channel("c2")
    ])
    
    subscription.onEvents = { _ in
      allEventsExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onMessage = { _ in
      messagesExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onSignal = { _ in
      signalExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onMessageAction = { _ in
      messageAction.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onPresence = { _ in
      presenceChangeExpectation.fulfill()
    }
    subscription.onAppContext = { _ in
      appContextExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onFileEvent = { _ in
      fileExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockMessagePayload(channel: "c1"), mockMessagePayload(channel: "c1"),
      mockSignalPayload(channel: "c1"), mockSignalPayload(channel: "c2"),
      mockPresenceChangePayload(channel: "c1"), mockPresenceChangePayload(channel: "c2"),
      mockAppContextPayload(channel: "c1"), mockAppContextPayload(channel: "c2"),
      mockFilePayload(channel: "c1"), mockFilePayload(channel: "c2"),
      mockMessageActionPayload(channel: "c1"), mockMessageActionPayload(channel: "c2")
    ])
    
    let allExpectations = [
      messagesExpectation, signalExpectation, presenceChangeExpectation,
      messageAction, fileExpectation, appContextExpectation,
      allEventsExpectation, singleEventExpectation
    ]
    
    wait(for: allExpectations, timeout: 1.0)
  }
  
  func testSubscriptionSetTopology() {
    let subscriptionSet = pubnub.subscription(
      entities: [
        pubnub.channel("c1"),
        pubnub.channel("c2"),
        pubnub.channelGroup("g1"),
      ], options: ReceivePresenceEvents()
    )
    let expectedTopology: [SubscribableType: [String]] = [
      .channel : ["c1", "c1-pnpres", "c2", "c2-pnpres"],
      .channelGroup: ["g1", "g1-pnpres"]
    ]
        
    XCTAssertEqual(
      subscriptionSet.subscriptionTopology[.channel]!.sorted(by: <),
      expectedTopology[.channel]!.sorted(by: <)
    )
    XCTAssertEqual(
      subscriptionSet.subscriptionTopology[.channelGroup]!.sorted(by: <),
      expectedTopology[.channelGroup]!.sorted(by: <)
    )
  }
}
