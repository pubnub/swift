//
//  SubscriptionSessionTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
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

import XCTest

@testable import PubNub

class SubscriptionSessionTests: XCTestCase {
  let config = PubNubConfiguration(
    publishKey: "FakeTestString",
    subscribeKey: "FakeTestString",
    userId: UUID().uuidString
  )
  let eeEnabledConfig = PubNubConfiguration(
    publishKey: "FakeTestString",
    subscribeKey: "FakeTestString",
    userId: UUID().uuidString,
    enableEventEngine: true
  )
  let testChannel = "TestChannel"
  
  func testSubscriptionSession_PreviousTimetokenResponse() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let messageExpect = XCTestExpectation(description: "Message Event")
        let statusExpect = XCTestExpectation(description: "Status Event")

        guard let session = try? MockURLSession.mockSession(
          for: ["subscription_handshake_success", "subscription_message_success", "cancelled"]
        ).session else {
          return XCTFail("Could not create mock url session")
        }

        let subscription = SubscribeSessionFactory.shared.getSession(from: configuration, with: session)
        let listener = SubscriptionListener()
        
        listener.didReceiveMessage = { message in
          XCTAssertEqual(
            subscription.previousTokenResponse,
            SubscribeCursor(timetoken: 15614817397807903, region: 2)
          )
          subscription.unsubscribeAll()
          messageExpect.fulfill()
        }
        listener.didReceiveStatus = { status in
          if let status = try? status.get(), status == .connected {
            XCTAssertEqual(
              subscription.previousTokenResponse,
              SubscribeCursor(timetoken: 16873352451141050, region: 42)
            )
            statusExpect.fulfill()
          }
        }
        
        subscription.add(listener)
        subscription.subscribe(to: [testChannel])

        XCTAssertEqual(subscription.subscribedChannels, [testChannel])

        defer { listener.cancel() }
        wait(for: [messageExpect, statusExpect], timeout: 1.0)
        
      }
    }
  }
  
  func testSubscriptionSession_PreviousTimetokenResponseOnError() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let statusExpect = XCTestExpectation(description: "Status Event")
        statusExpect.assertForOverFulfill = true
        statusExpect.expectedFulfillmentCount = configuration.enableEventEngine ? 2 : 1
        
        guard let session = try? MockURLSession.mockSession(
          for: ["badURL", "cancelled"]
        ).session else {
          return XCTFail("Could not create mock url session")
        }

        let subscription = SubscribeSessionFactory.shared.getSession(from: config, with: session)
        let listener = SubscriptionListener()

        listener.didReceiveStatus = { [unowned subscription] status in
          if case .failure(_) = status {
            XCTAssertNil(subscription.previousTokenResponse)
            statusExpect.fulfill()
          }
          if case .success(let newStatus) = status {
            if newStatus == .connectionError(PubNubError(.invalidURL)) {
              XCTAssertNil(subscription.previousTokenResponse)
              statusExpect.fulfill()
            }
          }
        }
        
        subscription.add(listener)
        subscription.subscribe(to: [testChannel], at: SubscribeCursor(timetoken: 123456, region: 1))

        XCTAssertEqual(subscription.subscribedChannels, [testChannel])

        defer { listener.cancel() }
        wait(for: [statusExpect], timeout: 1.0)
      }
    }
  }
}
