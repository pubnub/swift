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
  let configuration = PubNubConfiguration(publishKey: "", subscribeKey: "", userId: UUID().uuidString)

  func testSubscribeError() {
    let subscribeExpect = expectation(description: "Subscribe Expectation")
    let connectingExpect = expectation(description: "Connecting Expectation")
    let disconnectedExpect = expectation(description: "Disconnected Expectation")

    // Should return subscription key error
    let configuration = PubNubConfiguration(publishKey: "", subscribeKey: "", userId: UUID().uuidString)
    let pubnub = PubNub(configuration: configuration)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
        switch status {
        case .connecting:
          connectingExpect.fulfill()
        case .disconnectedUnexpectedly:
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

    wait(for: [subscribeExpect, connectingExpect, disconnectedExpect], timeout: 10.0)
  }

  // swiftlint:disable:next function_body_length cyclomatic_complexity
  func testUnsubscribeResubscribe() {
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

    let configuration = PubNubConfiguration(from: testsBundle)
    let pubnub = PubNub(configuration: configuration)

    var connectedCount = 0

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { [unowned self] event in
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

    wait(for: [subscribeExpect, unsubscribeExpect, publishExpect, connectedExpect, disconnectedExpect], timeout: 20.0)
  }
}
