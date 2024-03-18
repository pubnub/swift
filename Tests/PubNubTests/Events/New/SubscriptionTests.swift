//
//  SubscriptionTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class SubscriptionTests: XCTestCase {
  private let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId"
    )
  )
  
  func testSubscription_VariousPayloads() {
    let messagesExpectation = XCTestExpectation(description: "Message")
    messagesExpectation.assertForOverFulfill = true
    messagesExpectation.expectedFulfillmentCount = 1
    
    let signalExpectation = XCTestExpectation(description: "Signal")
    signalExpectation.assertForOverFulfill = true
    signalExpectation.expectedFulfillmentCount = 1
    
    let messageAction = XCTestExpectation(description: "Message Action")
    messageAction.assertForOverFulfill = true
    messageAction.expectedFulfillmentCount = 1
    
    let presenceChangeExpectation = XCTestExpectation(description: "Presence")
    presenceChangeExpectation.assertForOverFulfill = true
    presenceChangeExpectation.expectedFulfillmentCount = 1
    
    let appContextExpectation = XCTestExpectation(description: "App Context")
    appContextExpectation.assertForOverFulfill = true
    appContextExpectation.expectedFulfillmentCount = 1
    
    let fileExpectation = XCTestExpectation(description: "File")
    fileExpectation.assertForOverFulfill = true
    fileExpectation.expectedFulfillmentCount = 1
    
    let allEventsExpectation = XCTestExpectation(description: "All Events")
    allEventsExpectation.assertForOverFulfill = true
    allEventsExpectation.expectedFulfillmentCount = 1
    
    let singleEventExpectation = XCTestExpectation(description: "Single Event")
    singleEventExpectation.expectedFulfillmentCount = 6
    singleEventExpectation.assertForOverFulfill = true
    
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()
    
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
      mockMessagePayload(channel: channel.name), mockSignalPayload(channel: channel.name),
      mockPresenceChangePayload(channel: channel.name), mockAppContextPayload(channel: channel.name),
      mockFilePayload(channel: channel.name), mockMessageActionPayload(channel: channel.name)
    ])
    
    let allExpectations = [
      messagesExpectation, signalExpectation, presenceChangeExpectation,
      messageAction, fileExpectation, appContextExpectation,
      allEventsExpectation, singleEventExpectation
    ]
    
    wait(for: allExpectations, timeout: 1.0)
  }
  
  func testSubscription_PayloadsFromDifferentChannel() {
    let messagesExpectation = XCTestExpectation(description: "Message")
    messagesExpectation.isInverted = true
    messagesExpectation.assertForOverFulfill = true
    
    let signalExpectation = XCTestExpectation(description: "Signal")
    signalExpectation.isInverted = true
    signalExpectation.assertForOverFulfill = true
    
    let messageAction = XCTestExpectation(description: "Message Action")
    messageAction.isInverted = true
    messageAction.assertForOverFulfill = true
    
    let presenceChangeExpectation = XCTestExpectation(description: "Presence")
    presenceChangeExpectation.isInverted = true
    presenceChangeExpectation.assertForOverFulfill = true
    presenceChangeExpectation.expectedFulfillmentCount = 1
    
    let appContextExpectation = XCTestExpectation(description: "App Context")
    appContextExpectation.isInverted = true
    appContextExpectation.assertForOverFulfill = true
    
    let fileExpectation = XCTestExpectation(description: "File")
    fileExpectation.isInverted = true
    fileExpectation.assertForOverFulfill = true
    
    let allEventsExpectation = XCTestExpectation(description: "All Events")
    allEventsExpectation.isInverted = true
    allEventsExpectation.assertForOverFulfill = true
    
    let singleEventExpectation = XCTestExpectation(description: "Single Event")
    singleEventExpectation.isInverted = true
    singleEventExpectation.expectedFulfillmentCount = 6
    
    let channel = pubnub.channel("channel")
    let subscription = channel.subscription()
    
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
      mockMessagePayload(channel: "diff"), mockSignalPayload(channel: "diff"),
      mockPresenceChangePayload(channel: "diff"), mockAppContextPayload(channel: "diff"),
      mockFilePayload(channel: "diff"), mockMessageActionPayload(channel: "diff")
    ])
    
    let allExpectations = [
      messagesExpectation, signalExpectation, presenceChangeExpectation,
      messageAction, fileExpectation, appContextExpectation,
      allEventsExpectation, singleEventExpectation
    ]
    
    wait(for: allExpectations, timeout: 0.5)
  }
  
  func testSubscription_WildcardSubscription() {
    let expectation = XCTestExpectation(description: "Message")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 1
    
    let channel = pubnub.channel("channel.item.*")
    let subscription = channel.subscription()
    
    subscription.onMessage = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(
      payloads: [mockMessagePayload(channel: "channel.item.x")]
    )
    wait(for: [expectation], timeout: 0.5)
  }
  
  func testSubscription_WithFilterOption() {
    let expectation = XCTestExpectation(description: "Message")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 1
    
    let channel = pubnub.channel("channel")
    let subscription = channel.subscription(options: FilterOption(predicate: { event in
      guard case let .messageReceived(message) = event else {
        return false
      }
      if message.payload.stringOptional == "Hey!" {
        expectation.fulfill(); return true
      } else {
        return false
      }
    }))
    
    subscription.onPayloadsReceived(payloads: [
      mockMessagePayload(channel: channel.name, message: "This is a message"),
      mockMessagePayload(channel: channel.name, message: "Hey!")
    ])
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testSubscription_ReceivePresenceEvents() {
    let channel = pubnub.channel("c")
    let subscription = channel.subscription(options: ReceivePresenceEvents())
    
    XCTAssertEqual(subscription.subscriptionNames, ["c", "c-pnpres"])
    XCTAssertEqual(subscription.subscriptionType, .channel)
    XCTAssertEqual(subscription.subscriptionTopology, [.channel: ["c", "c-pnpres"]])
  }
  
  func testSubscription_ReceivePresenceEventsForChannelGroup() {
    let channel = pubnub.channelGroup("g")
    let subscription = channel.subscription(options: ReceivePresenceEvents())
    
    XCTAssertEqual(subscription.subscriptionNames, ["g", "g-pnpres"])
    XCTAssertEqual(subscription.subscriptionType, .channelGroup)
    XCTAssertEqual(subscription.subscriptionTopology, [.channelGroup: ["g", "g-pnpres"]])
  }
}
