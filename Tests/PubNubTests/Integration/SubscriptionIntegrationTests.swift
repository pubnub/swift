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

  // swiftlint:disable:next function_body_length
  func testUnsubscribeResubscribe() {
    let subscribeExpect = expectation(description: "Subscribe Expectation")
    subscribeExpect.expectedFulfillmentCount = 2
    let unsubscribeExpect = expectation(description: "Unsubscribe Expectation")

    let connectedExpect = expectation(description: "Connected Expectation")
    connectedExpect.expectedFulfillmentCount = 2
    let disconnectedExpect = expectation(description: "Disconnected Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let pubnub = PubNub(configuration: configuration)

    var connectedCount = 0

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { [unowned self] event in
      switch event {
      case let .subscriptionChanged(status):
        print("Status: \(status)")
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
      case let .connectionStatusChanged(status):
        print("Status: \(status)")
        switch status {
        case .connected:
          if connectedCount == 0 {
            pubnub.unsubscribe(from: [self.testChannel])
          }
          connectedCount += 1
          connectedExpect.fulfill()
        case .disconnected:
          pubnub.subscribe(to: [self.testChannel])
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

    wait(for: [subscribeExpect, unsubscribeExpect, connectedExpect, disconnectedExpect], timeout: 10.0)
  }
}
