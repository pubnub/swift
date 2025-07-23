//
//  SubscriptionIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

class SubscriptionIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: SubscriptionIntegrationTests.self)
  
  func testSubscribeError() {
    let configuration = PubNubConfiguration(
      publishKey: "",
      subscribeKey: "",
      userId: UUID().uuidString
    )
    
    let subscribeExpect = expectation(description: "Subscribe Expectation")
    subscribeExpect.assertForOverFulfill = true
    subscribeExpect.expectedFulfillmentCount = 1
    
    let disconnectedExpect = expectation(description: "Disconnected Expectation")
    disconnectedExpect.assertForOverFulfill = true
    disconnectedExpect.expectedFulfillmentCount = 1
    
    // Should return subscription key error
    let pubnub = PubNub(configuration: configuration)
    let listener = SubscriptionListener()
    
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        switch status {
        case .disconnectedUnexpectedly:
          disconnectedExpect.fulfill()
        case .connectionError:
          disconnectedExpect.fulfill()
        default:
          XCTFail("Only should emit these two states")
        }
      case .subscribeError:
        subscribeExpect.fulfill()
      default:
        break
      }
    }
    
    pubnub.add(listener)
    pubnub.subscribe(to: [randomString()])
    
    defer { pubnub.disconnect() }
    wait(for: [subscribeExpect, disconnectedExpect], timeout: 10.0)
  }

  // swiftlint:disable:next function_body_length cyclomatic_complexity
  func testUnsubscribeResubscribe() {
    let totalLoops = 10
    let testChannel = randomString()

    let subscribeExpect = expectation(description: "Subscribe Expectation")
    subscribeExpect.assertForOverFulfill = true
    subscribeExpect.expectedFulfillmentCount = totalLoops
    
    let unsubscribeExpect = expectation(description: "Unsubscribe Expectation")
    unsubscribeExpect.assertForOverFulfill = true
    unsubscribeExpect.expectedFulfillmentCount = totalLoops
    
    let publishExpect = expectation(description: "Publish Expectation")
    publishExpect.assertForOverFulfill = true
    publishExpect.expectedFulfillmentCount = totalLoops
    
    let connectedExpect = expectation(description: "Connected Expectation")
    connectedExpect.assertForOverFulfill = true
    connectedExpect.expectedFulfillmentCount = totalLoops
    
    let disconnectedExpect = expectation(description: "Disconnected Expectation")
    disconnectedExpect.assertForOverFulfill = true
    disconnectedExpect.expectedFulfillmentCount = totalLoops

    // Stores the current number of times the client has connected
    var connectedCount = 0
    
    let pubnub = PubNub(configuration: PubNubConfiguration(from: testsBundle))
    let listener = SubscriptionListener()
    
    listener.didReceiveSubscription = { [unowned pubnub] event in
      switch event {
      case let .subscriptionChanged(status):
        switch status {
        case let .subscribed(channels, _):
          XCTAssertTrue(channels.contains(where: { $0.id == testChannel }))
          XCTAssertTrue(pubnub.subscribedChannels.contains(testChannel))
          subscribeExpect.fulfill()
        case let .responseHeader(channels, _, _, next):
          XCTAssertTrue(channels.contains(where: { $0.id == testChannel }))
          XCTAssertEqual(pubnub.previousTimetoken, next?.timetoken)
        case let .unsubscribed(channels, _):
          XCTAssertTrue(channels.contains(where: { $0.id == testChannel }))
          XCTAssertFalse(pubnub.subscribedChannels.contains(testChannel))
          unsubscribeExpect.fulfill()
        }
      case .messageReceived:
        pubnub.unsubscribe(from: [testChannel])
        publishExpect.fulfill()
      case let .connectionStatusChanged(status):
        switch status {
        case .connected:
          pubnub.publish(channel: testChannel, message: "Test") { _ in }
          connectedCount += 1
          connectedExpect.fulfill()
        case .disconnected:
          // Stop reconneced after N attempts
          if connectedCount < totalLoops {
            pubnub.subscribe(to: [testChannel])
          }
          disconnectedExpect.fulfill()
        default:
          break
        }
      case let .subscribeError(error):
        XCTFail("An error was returned: \(error)")
      default:
        break
      }
    }
    
    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel])
    
    defer { pubnub.disconnect() }
    wait(for: [subscribeExpect, unsubscribeExpect, publishExpect, connectedExpect, disconnectedExpect], timeout: 30.0)
  }
  
  func testMixedSubscriptionsToTheSameChannel() {
    let subscribedEventExpect = expectation(description: "Subscribed Event Expect")
    subscribedEventExpect.assertForOverFulfill = true
    subscribedEventExpect.expectedFulfillmentCount = 1
    
    let responseHeaderExpect = expectation(description: "Response Received Event Expect")
    responseHeaderExpect.assertForOverFulfill = true
    responseHeaderExpect.expectedFulfillmentCount = 1

    let usubscribeEventExpect = expectation(description: "Unsubscribed Event Expect")
    usubscribeEventExpect.assertForOverFulfill = true
    usubscribeEventExpect.expectedFulfillmentCount = 1
    
    let disconnectedStatusExpect = expectation(description: "Disconnected Status Expect")
    disconnectedStatusExpect.assertForOverFulfill = true
    disconnectedStatusExpect.expectedFulfillmentCount = 1

    let pubnub = PubNub(configuration: PubNubConfiguration(from: testsBundle))
    let listener = SubscriptionListener()
    let testChannelName = randomString()
    
    var firstSubscription: Subscription? = pubnub.channel(testChannelName).subscription()
    var secondSubscription: Subscription? = pubnub.channel(testChannelName).subscription()
    var subscriptionSet: SubscriptionSet? = pubnub.subscription(entities: [pubnub.channel(testChannelName)])
    
    listener.didReceiveSubscription = { [unowned pubnub] event in
      switch event {
      case let .subscriptionChanged(status):
        switch status {
        case let .subscribed(channels, _):
          XCTAssertTrue(channels.contains(where: { $0.id == testChannelName }))
          XCTAssertTrue(pubnub.subscribedChannels.contains(testChannelName))
          subscribedEventExpect.fulfill()
        case let .responseHeader(channels, _, _, _):
          XCTAssertTrue(channels.contains(where: { $0.id == testChannelName }))
          responseHeaderExpect.fulfill()
        case let .unsubscribed(channels, _):
          XCTAssertTrue(channels.contains(where: { $0.id == testChannelName }))
          XCTAssertFalse(pubnub.subscribedChannels.contains(testChannelName))
          usubscribeEventExpect.fulfill()
        }
      case let .connectionStatusChanged(status):
        switch status {
        case .connected:
          firstSubscription = nil
          secondSubscription = nil
          subscriptionSet = nil
          pubnub.unsubscribe(from: [testChannelName])
        case .disconnected:
          disconnectedStatusExpect.fulfill()
        default:
          break
        }
      case let .subscribeError(error):
        XCTFail("An error was returned: \(error)")
      default:
        break
      }
    }
    
    pubnub.add(listener)
    pubnub.subscribe(to: [testChannelName])
    firstSubscription?.subscribe()
    secondSubscription?.subscribe()
    subscriptionSet?.subscribe()
    
    defer { pubnub.disconnect() }
    wait(for: [subscribedEventExpect, responseHeaderExpect, usubscribeEventExpect, disconnectedStatusExpect], timeout: 30.0, enforceOrder: true)
  }
  
  func testGlobalPubNubSubscription() {
    let messageExpect = expectation(description: "Message Expect")
    messageExpect.assertForOverFulfill = true
    messageExpect.expectedFulfillmentCount = 1
    
    let statusExpect = expectation(description: "Status Expect")
    statusExpect.assertForOverFulfill = true
    statusExpect.expectedFulfillmentCount = 2

    let pubnub = PubNub(configuration: PubNubConfiguration(from: testsBundle))
    let testChannelName = randomString()
    
    // Tracks the number of times the status has changed
    var statusCounter = 0
    
    pubnub.onMessage = { [unowned pubnub] message in
      XCTAssertEqual(message.payload.stringOptional, "This is a message")
      messageExpect.fulfill()
      pubnub.unsubscribe(from: [testChannelName])
    }
    pubnub.onConnectionStateChange = { [unowned pubnub] change in
      if statusCounter == 0 {
        XCTAssertTrue(change == .connected)
        pubnub.publish(channel: testChannelName, message: "This is a message", completion: nil)
      } else if statusCounter == 1 {
        XCTAssertTrue(change == .disconnected)
      } else {
        XCTFail("Unexpected condition")
      }
      statusCounter += 1
      statusExpect.fulfill()
    }
    
    pubnub.subscribe(to: [testChannelName])
    
    defer { pubnub.disconnect() }
    wait(for: [statusExpect, messageExpect], timeout: 30.0)
  }

  func testSubscriptionsWithCustomTimetoken() {
    let expectation = expectation(description: "Expectation")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 4
            
    let pubnub = PubNub(configuration: .init(from: testsBundle))
    let customTimetoken = Timetoken(Int(Date().timeIntervalSince1970 * 10000000))
    
    let testChannelName = randomString()
    let anotherTestChannelName = testChannelName.appending("2")
    let listener = SubscriptionListener()
    let expectedMessagesSet = ["First message", "Second message", "Third message", "Fourth message"]
    
    // Listens for messages on all currently subscribed channels.
    // We expect the listener to receive all the messages newer than the `customTimetoken` property.
    listener.didReceiveMessage = { message in
      XCTAssertTrue(expectedMessagesSet.contains(message.payload.stringOptional ?? ""))
      XCTAssertTrue([testChannelName, anotherTestChannelName].contains(message.channel))
      expectation.fulfill()
    }
    
    // Closure to call after the channel is populated with messages
    let performSubscribeCall = { [unowned pubnub] in
      // Adds the listener to the PubNub client
      pubnub.add(listener)
      // Subscribes to the channel with the timetoken prior to populating the channel with test messages
      pubnub.subscribe(to: [testChannelName], at: customTimetoken)
      // Adds another channel to subscribe to
      pubnub.subscribe(to: [anotherTestChannelName])
      pubnub.publish(channel: testChannelName, message: "Third message", completion: nil)
      pubnub.publish(channel: anotherTestChannelName, message: "Fourth message", completion: nil)
    }

    // Populates the channel with messages
    pubnub.publish(channel: testChannelName, message: "First message", completion: { [unowned pubnub] _ in
      pubnub.publish(channel: testChannelName, message: "Second message", completion: { _ in
        performSubscribeCall()
      })
    })
    
    defer { pubnub.disconnect() }
    wait(for: [expectation], timeout: 10.0)
  }
  
  func testSimultaneousSubscriptionsToTheSameChannel() {
    let expectation = expectation(description: "Test Simultaneous Subscriptions")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 1
    
    let pubnub = PubNub(configuration: .init(from: testsBundle))
    let testChannelName = randomString()
    
    // We expect the long-polling connection won't be interrupted by the second subscription, which is 
    // subscribing to the same channel
    pubnub.onConnectionStateChange = {
      switch $0 {
      case .connected:
        expectation.fulfill()
      default:
        XCTFail("Unexpected connection status")
      }
    }
    
    pubnub.subscribe(to: [testChannelName])
    pubnub.subscribe(to: [testChannelName])
    
    XCTAssertEqual(pubnub.subscribedChannels, [testChannelName])
    wait(for: [expectation], timeout: 5.0)
  }
  
  func testAddingNextLegacyListenerInTheMeantime() {
    let expectation = expectation(description: "Message expectation")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2

    let pubnub = PubNub(configuration: .init(from: testsBundle))
    let listener = SubscriptionListener()
    let secondListener = SubscriptionListener()
    let testChannelName = randomString()
    
    listener.didReceiveMessage = { message in
      expectation.fulfill()
    }
    secondListener.didReceiveMessage = { message in
      expectation.fulfill()
    }
    
    listener.didReceiveStatus = { [unowned pubnub] statusChange in
      if case .success(let status) = statusChange, status == .connected {
        pubnub.add(secondListener)
        pubnub.publish(channel: testChannelName, message: "Message", completion: nil)
      }
    }
    
    pubnub.add(listener)
    pubnub.subscribe(to: [testChannelName])
    
    wait(for: [expectation], timeout: 10.0)
  }
  
  func testAddingNextListenerUsingSubscriptionObjects() {
    let expectation = XCTestExpectation(description: "Message expectation")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2

    let testChannelName = randomString()
    let pubnub = PubNub(configuration: .init(from: testsBundle))
    
    let firstSubscription = pubnub.channel(testChannelName).subscription()
    let secondSubscription = pubnub.channel(testChannelName).subscription()

    firstSubscription.onMessage = { message in
      expectation.fulfill()
    }
    secondSubscription.onMessage = { message in
      expectation.fulfill()
    }
    
    pubnub.onConnectionStateChange = { [unowned pubnub] newStatus in
      if newStatus == .connected {
        secondSubscription.subscribe()
        pubnub.publish(channel: testChannelName, message: "Message", completion: nil)
      }
    }
    
    firstSubscription.subscribe()
    
    wait(for: [expectation], timeout: 5.0)
  }
  
  func testSubscribingToPresenceChannelOnly() {
    let presenceExpectation = XCTestExpectation(description: "Presence expectation")
    presenceExpectation.assertForOverFulfill = true
    presenceExpectation.expectedFulfillmentCount = 1
    
    let messageExpectation = XCTestExpectation(description: "Message expectation")
    messageExpectation.isInverted = true
    
    let mainChannelName = randomString()
    let presenceChannelName = mainChannelName + "-pnpres"
    
    let pubnub = PubNub(configuration: presenceConfiguration())
    let subscription = pubnub.channel(presenceChannelName).subscription()
    let anotherPubNub = PubNub(configuration: presenceConfiguration())
    
    subscription.onPresence = { presenceEvent in
      if case let .join(userIds) = presenceEvent.actions.first {
        if userIds.count == 1 && userIds.first == anotherPubNub.configuration.userId {
          presenceExpectation.fulfill()
        } else {
          XCTFail("Unexpected condition")
        }
      } else {
        XCTFail("Unexpected condition")
      }
    }
    subscription.onMessage = { _ in
      messageExpectation.fulfill()
    }
    
    pubnub.onConnectionStateChange = { [weak pubnub] newStatus in
      if newStatus == .connected {
        pubnub?.publish(channel: mainChannelName, message: "Some message") { _ in
          anotherPubNub.subscribe(to: [mainChannelName])
        }
      }
    }
    
    subscription.subscribe()
    
    wait(for: [presenceExpectation, messageExpectation], timeout: 10.0)
  }
  
  func testSubscribedChannels() {
    let pubnub = PubNub(configuration: .init(from: testsBundle))
    let channelA = "A"
    let channelB = "B"
    
    var firstSubscriptionToChannelA: Subscription? = pubnub.channel(channelA).subscription()
    var secondSubscriptionToChannelA: Subscription? = pubnub.channel(channelA).subscription()
    var subscriptionToChannelB: Subscription? = pubnub.channel(channelB).subscription()
    
    firstSubscriptionToChannelA?.subscribe()
    secondSubscriptionToChannelA?.subscribe()
    
    XCTAssertEqual(pubnub.subscribedChannels, ["A"])
    subscriptionToChannelB?.subscribe()
    XCTAssertEqual(pubnub.subscribedChannels.sorted(by: <), ["A", "B"])

    firstSubscriptionToChannelA = nil
    XCTAssertEqual(pubnub.subscribedChannels.sorted(by: <), ["A", "B"])
    secondSubscriptionToChannelA = nil
    XCTAssertEqual(pubnub.subscribedChannels, ["B"])
    subscriptionToChannelB = nil
    XCTAssertTrue(pubnub.subscribedChannels.isEmpty)
  }
}

private extension SubscriptionIntegrationTests {
  func presenceConfiguration() -> PubNubConfiguration {
    PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: randomString(),
      durationUntilTimeout: 11
    )
  }
}
