//
//  SubscriptionIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
import XCTest

class SubscriptionIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: SubscriptionIntegrationTests.self)
  let testChannel = "SwiftSubscriptionITestsChannel"
  
  func testSubscribeError() {
    let configuration = PubNubConfiguration(
      publishKey: "",
      subscribeKey: "",
      userId: UUID().uuidString,
      enableEventEngine: false
    )
    let eeConfiguration = PubNubConfiguration(
      publishKey: "",
      subscribeKey: "",
      userId: UUID().uuidString,
      enableEventEngine: true
    )
    
    for config in [configuration, eeConfiguration] {
      XCTContext.runActivity(named: "Testing configuration with enableEventEngine=\(config.enableEventEngine)") { _ in
        let subscribeExpect = expectation(description: "Subscribe Expectation")
        let connectingExpect = expectation(description: "Connecting Expectation")
        
        let disconnectedExpect = expectation(description: "Disconnected Expectation")
        disconnectedExpect.assertForOverFulfill = true
        disconnectedExpect.expectedFulfillmentCount = 1
        
        // Should return subscription key error
        let pubnub = PubNub(configuration: config)
        let listener = SubscriptionListener()
        
        listener.didReceiveSubscription = { event in
          switch event {
          case let .connectionStatusChanged(status):
            switch status {
            case .connecting:
              connectingExpect.fulfill()
            case .disconnectedUnexpectedly:
              disconnectedExpect.fulfill()
            case .connectionError:
              disconnectedExpect.fulfill()
            default:
              XCTFail("Only should emit these two states")
            }
          case .subscribeError:
            subscribeExpect.fulfill() // 8E988B17-C0AA-42F1-A6F9-1461BF51C82C
          default:
            break
          }
        }
        
        pubnub.add(listener)
        pubnub.subscribe(to: [testChannel])
        
        defer { pubnub.disconnect() }
        wait(for: [subscribeExpect, connectingExpect, disconnectedExpect], timeout: 10.0)
      }
    }
  }
  
  // swiftlint:disable:next function_body_length cyclomatic_complexity
  func testUnsubscribeResubscribe() {
    let configurationFromBundle = PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId,
      enableEventEngine: false
    )
    let configWithEventEngineEnabled = PubNubConfiguration(
      publishKey: configurationFromBundle.publishKey,
      subscribeKey: configurationFromBundle.subscribeKey,
      userId: configurationFromBundle.userId
    )
    
    for config in [configurationFromBundle, configWithEventEngineEnabled] {
      XCTContext.runActivity(named: "Testing configuration with enableEventEngine=\(config.enableEventEngine)") { _ in
        let totalLoops = 10
        let subscribeExpect = expectation(description: "Subscribe Expectation")
        subscribeExpect.expectedFulfillmentCount = totalLoops
        let unsubscribeExpect = expectation(description: "Unsubscribe Expectation")
        unsubscribeExpect.expectedFulfillmentCount = totalLoops
        let publishExpect = expectation(description: "Publish Expectation")
        publishExpect.expectedFulfillmentCount = totalLoops
        let connectedExpect = expectation(description: "Connected Expectation")
        connectedExpect.expectedFulfillmentCount = totalLoops
        let disconnectedExpect = expectation(description: "Disconnected Expectation")
        disconnectedExpect.expectedFulfillmentCount = totalLoops
        
        let pubnub = PubNub(configuration: config)
        var connectedCount = 0
        
        let listener = SubscriptionListener()
        listener.didReceiveSubscription = { [unowned self, unowned pubnub] event in
          switch event {
          case let .subscriptionChanged(status):
            switch status {
            case let .subscribed(channels, _):
              XCTAssertTrue(channels.contains(where: { $0.id == self.testChannel }))
              XCTAssertTrue(pubnub.subscribedChannels.contains(self.testChannel))
              subscribeExpect.fulfill()
            case let .responseHeader(channels, _, _, next):
              XCTAssertTrue(channels.contains(where: { $0.id == self.testChannel }))
              XCTAssertEqual(pubnub.previousTimetoken, next?.timetoken)
            case let .unsubscribed(channels, _):
              XCTAssertTrue(channels.contains(where: { $0.id == self.testChannel }))
              XCTAssertFalse(pubnub.subscribedChannels.contains(self.testChannel))
              unsubscribeExpect.fulfill()
            }
          case .messageReceived:
            pubnub.unsubscribe(from: [self.testChannel])
            publishExpect.fulfill()
          case let .connectionStatusChanged(status):
            switch status {
            case .connected:
              pubnub.publish(channel: self.testChannel, message: "Test") { _ in }
              connectedCount += 1
              connectedExpect.fulfill()
            case .disconnected:
              // Stop reconneced after N attempts
              if connectedCount < totalLoops {
                pubnub.subscribe(to: [self.testChannel])
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
    }
  }
  
  func test_MixedSubscriptions() {
    let configurationFromBundle = PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId,
      enableEventEngine: false
    )
    let configWithEventEngineEnabled = PubNubConfiguration(
      publishKey: configurationFromBundle.publishKey,
      subscribeKey: configurationFromBundle.subscribeKey,
      userId: configurationFromBundle.userId
    )
    
    for config in [configurationFromBundle, configWithEventEngineEnabled] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(config.enableEventEngine)") { _ in
        let subscribedEventExpect = XCTestExpectation(description: "SubscribedEvent")
        subscribedEventExpect.assertForOverFulfill = true
        subscribedEventExpect.expectedFulfillmentCount = 1
        
        let responseHeaderExpect = XCTestExpectation(description: "ResponseReceivedEvent")
        responseHeaderExpect.assertForOverFulfill = true
        responseHeaderExpect.expectedFulfillmentCount = 1

        let usubscribeEventExpect = XCTestExpectation(description: "UnsubscribedEvent")
        usubscribeEventExpect.assertForOverFulfill = true
        usubscribeEventExpect.expectedFulfillmentCount = 1

        let pubnub = PubNub(configuration: config)
        let listener = SubscriptionListener()
        var firstSubscription: Subscription? = pubnub.channel(testChannel).subscription()
        var secondSubscription: Subscription? = pubnub.channel(testChannel).subscription()
        var subscriptionSet: SubscriptionSet? = pubnub.subscription(entities: [pubnub.channel(testChannel)])
        
        listener.didReceiveSubscription = { [unowned self, unowned pubnub] event in
          switch event {
          case let .subscriptionChanged(status):
            switch status {
            case let .subscribed(channels, _):
              XCTAssertTrue(channels.contains(where: { $0.id == self.testChannel }))
              XCTAssertTrue(pubnub.subscribedChannels.contains(self.testChannel))
              subscribedEventExpect.fulfill()
            case let .responseHeader(channels, _, _, _):
              XCTAssertTrue(channels.contains(where: { $0.id == self.testChannel }))
              responseHeaderExpect.fulfill()
            case let .unsubscribed(channels, _):
              XCTAssertTrue(channels.contains(where: { $0.id == self.testChannel }))
              XCTAssertFalse(pubnub.subscribedChannels.contains(self.testChannel))
              usubscribeEventExpect.fulfill()
            }
          case let .connectionStatusChanged(status):
            switch status {
            case .connected:
              firstSubscription = nil
              secondSubscription = nil
              pubnub.unsubscribe(from: [self.testChannel])
              subscriptionSet?.unsubscribe()
              subscriptionSet = nil
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
        firstSubscription?.subscribe()
        secondSubscription?.subscribe()
        subscriptionSet?.subscribe()
        
        defer { pubnub.disconnect() }
        wait(for: [subscribedEventExpect, responseHeaderExpect, usubscribeEventExpect], timeout: 30.0)
      }
    }
  }
  
  func test_GlobalSubscription() {
    let configurationFromBundle = PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId,
      enableEventEngine: false
    )
    let configWithEventEngineEnabled = PubNubConfiguration(
      publishKey: configurationFromBundle.publishKey,
      subscribeKey: configurationFromBundle.subscribeKey,
      userId: configurationFromBundle.userId
    )
    
    for config in [configurationFromBundle, configWithEventEngineEnabled] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(config.enableEventEngine)") { _ in
        let messageExpect = XCTestExpectation(description: "Message")
        messageExpect.assertForOverFulfill = true
        messageExpect.expectedFulfillmentCount = 1
        
        let statusExpect = XCTestExpectation(description: "StatusExpect")
        statusExpect.assertForOverFulfill = true
        statusExpect.expectedFulfillmentCount = 3

        let pubnub = PubNub(configuration: config)
        var statusCounter = 0
        
        pubnub.onMessage = { [unowned pubnub] message in
          XCTAssertTrue(message.payload.stringOptional == "This is a message")
          messageExpect.fulfill()
          pubnub.unsubscribe(from: [self.testChannel])
        }
        pubnub.onConnectionStateChange = { [unowned pubnub] change in
          if statusCounter == 0 {
            XCTAssertTrue(change == .connecting)
          } else if statusCounter == 1 {
            XCTAssertTrue(change == .connected)
            pubnub.publish(channel: self.testChannel, message: "This is a message", completion: nil)
          } else if statusCounter == 2 {
            XCTAssertTrue(change == .disconnected)
          } else {
            XCTFail("Unexpected condition")
          }
          statusCounter += 1
          statusExpect.fulfill()
        }
        pubnub.subscribe(to: [testChannel])
        
        defer { pubnub.disconnect() }
        wait(for: [statusExpect, messageExpect], timeout: 30.0)
      }
    }
  }
  
  func test_SimultaneousSubscriptionToDifferentChannels() {
    let expectation = XCTestExpectation(description: "Expectation")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 3
    
    let publishExpectation = XCTestExpectation(description: "Publish")
    publishExpectation.assertForOverFulfill = true
    publishExpectation.expectedFulfillmentCount = 1
        
    let pubnub = PubNub(configuration: PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId
    ))
    let timetoken = Timetoken(Int(Date().timeIntervalSince1970 * 10000000))

    pubnub.publish(channel: testChannel, message: "Message", completion: { [unowned pubnub, unowned self] _ in
      pubnub.publish(channel: self.testChannel, message: "Second message", completion: { _ in
        publishExpectation.fulfill()
      })
    })
    
    wait(for: [publishExpectation], timeout: 1.5)
    
    let anotherChannel = testChannel.appending("2")
    let listener = SubscriptionListener()
   
    listener.didReceiveMessage = { _ in
      expectation.fulfill()
    }
    
    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel], at: timetoken)
    pubnub.publish(channel: testChannel, message: "Third message", completion: nil)
    pubnub.subscribe(to: [anotherChannel])
    
    defer { pubnub.disconnect() }
    wait(for: [expectation], timeout: 10)
  }
  
  func test_SimultaneousSubscriptionsToTheSameChannel() {
    let expectation = XCTestExpectation(description: "Test Simultaneous Subscriptions")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 2
    
    let pubnub = PubNub(configuration: PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId
    ))
    
    pubnub.onConnectionStateChange = { newStatus in
      switch newStatus {
      case .connecting:
        expectation.fulfill()
      case .connected:
        expectation.fulfill()
      default:
        XCTFail("Unexpected connection status")
      }
    }
    
    pubnub.subscribe(to: ["channel"])
    pubnub.subscribe(to: ["channel"])
    
    XCTAssertEqual(pubnub.subscribedChannels, ["channel"])
    wait(for: [expectation], timeout: 5.0)
  }
  
  func test_SimultaneousSubscriptionsToTheSameChannelWithTimetoken() {
    let expectation = XCTestExpectation(description: "Test Simultaneous Subscriptions With Timetoken")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 3
    
    let pubnub = PubNub(configuration: PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId
    ))
    
    pubnub.onConnectionStateChange = { newStatus in
      switch newStatus {
      case .connecting:
        expectation.fulfill()
      case .connected:
        expectation.fulfill()
      default:
        XCTFail("Unexpected connection status")
      }
    }
    
    pubnub.subscribe(to: ["channel"])
    pubnub.subscribe(to: ["channel"], at: Timetoken(Int(Date().timeIntervalSince1970 * 10000000)))
    
    wait(for: [expectation], timeout: 5.0)
  }
}
