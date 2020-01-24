//
//  SubscriptionIntegrationTests.swift
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

import PubNub
import XCTest

class SubscriptionIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: SubscriptionIntegrationTests.self)

  let testChannel = "SwiftSubscriptionITestsChannel"

  func testSubscribeError() {
    let subscribeExpect = expectation(description: "Subscribe Expectation")
    let connectingExpect = expectation(description: "Connecting Expectation")
    let disconnectedExpect = expectation(description: "Disconnected Expectation")

    // Should return subscription key error
    let configuration = PubNubConfiguration(publishKey: "", subscribeKey: "")
    let pubnub = PubNub(configuration: configuration)

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .connectionStatusChanged(status):
//        print("Status: \(status)")
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
//        print("subscriptionChanged: \(status) for current list \(pubnub.subscribedChannels)")
        switch status {
        case .subscribed(let channels, _):
          XCTAssertTrue(channels.contains(where: { $0.id == self.testChannel }))
          XCTAssertTrue(pubnub.subscribedChannels.contains(self.testChannel))
          subscribeExpect.fulfill()
        case .unsubscribed(let channels, _):
          XCTAssertTrue(channels.contains(where: { $0.id == self.testChannel }))
          XCTAssertFalse(pubnub.subscribedChannels.contains(self.testChannel))
          unsubscribeExpect.fulfill()
        }
      case .messageReceived:
//        print("messageReceived: \(message)")
        pubnub.unsubscribe(from: [self.testChannel])
        publishExpect.fulfill()
      case let .connectionStatusChanged(status):
//        print("connectionStatusChanged: \(status)")
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
