//
//  EmitStatusTests.swift
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

import Foundation
import XCTest

@testable import PubNub

fileprivate class MockListener: BaseSubscriptionListener {
  var onEmitSubscribeEventCalled: ((PubNubSubscribeEvent) -> Void) = { _ in }
  
  override func emit(subscribe: PubNubSubscribeEvent) {
    onEmitSubscribeEventCalled(subscribe)
  }
}

class EmitStatusTests: XCTestCase {
  private var listeners: [MockListener] = []
  
  override func setUp() {
    listeners = (0...2).map { _ in MockListener() }
    super.setUp()
  }
  
  override func tearDown() {
    listeners = []
    super.tearDown()
  }
  
  func testEmitStatus_FromDisconnectedToConnected() {
    let expectation = XCTestExpectation(description: "Emit Status Effect")
    expectation.expectedFulfillmentCount = listeners.count
    expectation.assertForOverFulfill = true
    
    let effect = EmitStatusEffect(
      statusChange: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .connected,
        error: nil
      ),
      listeners: listeners
    )
    listeners.forEach {
      $0.onEmitSubscribeEventCalled = { event in
        if case let .connectionChanged(status) = event {
          XCTAssertEqual(status, .connected)
          expectation.fulfill()
        } else {
          XCTFail("Unexpected event")
        }
      }
    }
    
    effect.performTask(completionBlock: { _ in
      PubNub.log.debug("Did finish performing EmitStatus effect")
    })
    
    wait(for: [expectation], timeout: 0.1)
  }
  
  func testEmitStatus_WithError() {
    let expectation = XCTestExpectation(description: "Emit Status Effect")
    expectation.expectedFulfillmentCount = listeners.count
    expectation.assertForOverFulfill = true
    
    let errorExpectation = XCTestExpectation(description: "Emit Status Effect - Error Listener")
    errorExpectation.expectedFulfillmentCount = listeners.count
    errorExpectation.assertForOverFulfill = true
    
    let effect = EmitStatusEffect(
      statusChange: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .connected,
        error: SubscribeError(underlying: PubNubError(.unknown))
      ),
      listeners: listeners
    )
    listeners.forEach {
      $0.onEmitSubscribeEventCalled = { event in
        if case let .connectionChanged(status) = event {
          XCTAssertEqual(status, .connected)
          expectation.fulfill()
        }
        if case let .errorReceived(error) = event {
          XCTAssertEqual(error, PubNubError(.unknown))
          errorExpectation.fulfill()
        }
      }
    }
    
    effect.performTask(completionBlock: { _ in
      PubNub.log.debug("Did finish performing EmitStatus effect")
    })
    
    wait(for: [expectation, errorExpectation], timeout: 0.1)    
  }
}
