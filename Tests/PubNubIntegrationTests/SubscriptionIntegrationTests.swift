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

    listener.didReceiveStatus = { statusEvent in
      switch statusEvent {
      case let .success(status):
        switch status {
        case .disconnectedUnexpectedly, .connectionError:
          disconnectedExpect.fulfill()
        default:
          break
        }
      case .failure:
        subscribeExpect.fulfill()
      }
    }

    pubnub.add(listener)
    pubnub.subscribe(to: [randomString()])

    defer { pubnub.disconnect() }
    wait(for: [subscribeExpect, disconnectedExpect], timeout: 10.0)
  }

  func testUnsubscribeResubscribe() {
    let totalLoops = 10
    let testChannel = randomString()

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

    let pubnub = PubNub(configuration: PubNubConfiguration(bundle: testsBundle))
    let listener = SubscriptionListener()

    listener.didReceiveStatus = { [unowned pubnub] statusEvent in
      switch statusEvent {
      case let .success(status):
        switch status {
        case .subscriptionChanged:
          XCTFail("Unexpected condition")
        case .connected:
          pubnub.publish(channel: testChannel, message: "Test") { _ in }
          connectedCount += 1
          connectedExpect.fulfill()
        case .disconnected:
          // Stop reconnecting after N attempts
          if connectedCount < totalLoops {
            pubnub.subscribe(to: [testChannel])
          }
          disconnectedExpect.fulfill()
        default:
          break
        }
      case let .failure(error):
        XCTFail("An error was returned: \(error)")
      }
    }

    listener.didReceiveSubscription = { [unowned pubnub] event in
      if case .messageReceived = event {
        pubnub.unsubscribe(from: [testChannel])
        publishExpect.fulfill()
      }
    }

    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel])

    defer { pubnub.disconnect() }
    wait(for: [publishExpect, connectedExpect, disconnectedExpect], timeout: 30.0)
  }

  func testMixedSubscriptionsToTheSameChannel() {
    let connectedStatusExpect = expectation(description: "Connected Status Expect")
    connectedStatusExpect.assertForOverFulfill = true
    connectedStatusExpect.expectedFulfillmentCount = 1

    let disconnectedStatusExpect = expectation(description: "Disconnected Status Expect")
    disconnectedStatusExpect.assertForOverFulfill = true
    disconnectedStatusExpect.expectedFulfillmentCount = 1

    let pubnub = PubNub(configuration: PubNubConfiguration(bundle: testsBundle))
    let listener = SubscriptionListener()
    let testChannelName = randomString()

    var firstSubscription: Subscription? = pubnub.channel(testChannelName).subscription()
    var secondSubscription: Subscription? = pubnub.channel(testChannelName).subscription()
    var subscriptionSet: SubscriptionSet? = pubnub.subscription(targets: [pubnub.channel(testChannelName)])

    listener.didReceiveStatus = { [unowned pubnub] statusEvent in
      switch statusEvent {
      case let .success(status):
        switch status {
        case .connected:
          XCTAssertTrue(pubnub.subscribedChannels.contains(testChannelName))
          firstSubscription = nil
          secondSubscription = nil
          subscriptionSet = nil
          connectedStatusExpect.fulfill()
          pubnub.unsubscribe(from: [testChannelName])
        case .disconnected:
          XCTAssertFalse(pubnub.subscribedChannels.contains(testChannelName))
          disconnectedStatusExpect.fulfill()
        case .subscriptionChanged:
          XCTFail("Unexpected condition")
        default:
          break
        }
      case let .failure(error):
        XCTFail("An error was returned: \(error)")
      }
    }

    pubnub.add(listener)
    pubnub.subscribe(to: [testChannelName])
    firstSubscription?.subscribe()
    secondSubscription?.subscribe()
    subscriptionSet?.subscribe()

    defer { pubnub.disconnect() }
    wait(
      for: [connectedStatusExpect, disconnectedStatusExpect],
      timeout: 30.0,
      enforceOrder: true
    )
  }

  func testGlobalPubNubSubscription() {
    let messageExpect = expectation(description: "Message Expect")
    messageExpect.assertForOverFulfill = true
    messageExpect.expectedFulfillmentCount = 1

    let statusExpect = expectation(description: "Status Expect")
    statusExpect.assertForOverFulfill = true
    statusExpect.expectedFulfillmentCount = 2

    let pubnub = PubNub(configuration: PubNubConfiguration(bundle: testsBundle))
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

    let pubnub = PubNub(configuration: .init(bundle: testsBundle))
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

    let pubnub = PubNub(configuration: .init(bundle: testsBundle))
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

    let pubnub = PubNub(configuration: .init(bundle: testsBundle))
    let listener = SubscriptionListener()
    let secondListener = SubscriptionListener()
    let testChannelName = randomString()

    listener.didReceiveMessage = { _ in
      expectation.fulfill()
    }
    secondListener.didReceiveMessage = { _ in
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
    let pubnub = PubNub(configuration: .init(bundle: testsBundle))

    let firstSubscription = pubnub.channel(testChannelName).subscription()
    let secondSubscription = pubnub.channel(testChannelName).subscription()

    firstSubscription.onMessage = { _ in
      expectation.fulfill()
    }
    secondSubscription.onMessage = { _ in
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
    let pubnub = PubNub(configuration: .init(bundle: testsBundle))
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

  func testUnsubscribingPresenceOnly() {
    let pubnub = PubNub(configuration: .init(bundle: testsBundle))
    pubnub.subscribe(to: ["A"], withPresence: true)
    XCTAssertEqual(pubnub.subscribedChannels.sorted(by: <), ["A", "A-pnpres"])
    pubnub.unsubscribe(from: ["A-pnpres"])
    XCTAssertEqual(pubnub.subscribedChannels, ["A"])
  }

  func testUnsubscribe() {
    let pubnub = PubNub(configuration: .init(bundle: testsBundle))
    pubnub.subscribe(to: ["A"], withPresence: true)
    XCTAssertEqual(pubnub.subscribedChannels.sorted(by: <), ["A", "A-pnpres"])
    pubnub.subscribe(to: ["B"], withPresence: true)
    XCTAssertEqual(pubnub.subscribedChannels.sorted(by: <), ["A", "A-pnpres", "B", "B-pnpres"])

    // Unsubscribing from the main channel. This should also unsubscribe from the presence channel
    pubnub.unsubscribe(from: ["A"])
    // Ensuring backward compatibility and that the presence channel is unsubscribed along with the main channel
    XCTAssertEqual(pubnub.subscribedChannels.sorted(by: <), ["B", "B-pnpres"])
  }

  func testSubscriptionSetDispose() {
    let expectation = expectation(description: "Test")
    let pubnub = PubNub(configuration: .init(bundle: testsBundle))
    let channel = pubnub.channel("test-channel")
    let channel2 = pubnub.channel("test-channel2")
    let subscriptionSet = pubnub.subscription(targets: [channel, channel2])

    subscriptionSet.subscribe()

    pubnub.onConnectionStateChange = { [unowned subscriptionSet] newStatus in
      switch newStatus {
      case .connected:
        subscriptionSet.dispose()
        XCTAssertTrue(subscriptionSet.isDisposed)
        expectation.fulfill()
      default:
        break
      }
    }

    wait(for: [expectation], timeout: 3)
  }
}

private extension SubscriptionIntegrationTests {
  func presenceConfiguration() -> PubNubConfiguration {
    PubNubConfiguration(
      publishKey: PubNubConfiguration(bundle: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(bundle: testsBundle).subscribeKey,
      userId: randomString(),
      durationUntilTimeout: 11
    )
  }
}
