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
    
  func testEmitStatus_FromDisconnectedToConnecting() {
    testEffect(from: .disconnected, to: .connecting) { result in
      XCTAssertTrue(result == .connecting)
    }
  }
  
  func testEmitStatus_FromConnectingToConnected() {
    testEffect(from: .connecting, to: .connected) { result in
      XCTAssertTrue(result == .connected)
    }
  }
  
  func testEmitStatus_FromConnectingToDisconnected() {
    testEffect(from: .connecting, to: .disconnected) { result in
      XCTAssertTrue(result == .disconnected)
    }
  }
  
  func testEmitStatus_FromConnectedToReconnecting() {
    testEffect(from: .connected, to: .reconnecting) { result in
      XCTAssertTrue(result == .reconnecting)
    }
  }
  
  func testEmitStatus_FromConnectedToDisconnected() {
    testEffect(from: .connected, to: .disconnected) { result in
      XCTAssertTrue(result == .disconnected)
    }
  }
  
  func testEmitStatus_FromReconnectingToDisconnected() {
    testEffect(from: .reconnecting, to: .disconnected) { result in
      XCTAssertTrue(result == .disconnected)
    }
  }
  
  func testEmitStatus_FromConnectingToDisconnectedUnexpectedly() {
    testEffect(from: .connecting, to: .disconnectedUnexpectedly) { result in
      XCTAssertTrue(result == .disconnectedUnexpectedly)
    }
  }
  
  func testEmitStatus_FromConnectedToDisconnectedUnexpectedly() {
    testEffect(from: .connected, to: .disconnectedUnexpectedly) { result in
      XCTAssertTrue(result == .disconnectedUnexpectedly)
    }
  }
  
  func testEmitStatus_FromReconnectingToDisconnectedUnexpectedly() {
    testEffect(from: .reconnecting, to: .disconnectedUnexpectedly) { result in
      XCTAssertTrue(result == .disconnectedUnexpectedly)
    }
  }
  
  private func testEffect(
    from currentStatus: ConnectionStatus,
    to newStatus: ConnectionStatus,
    verifyResult: @escaping (ConnectionStatus) -> Void
  ) {
    let expectation = XCTestExpectation(description: "Emit Status Effect")
    expectation.expectedFulfillmentCount = listeners.count
    expectation.assertForOverFulfill = true
    
    let effect = EmitStatusEffect(
      currentStatus: currentStatus,
      newStatus: newStatus,
      listeners: listeners
    )
    
    listeners.forEach {
      $0.onEmitSubscribeEventCalled = { event in
        if case let .connectionChanged(status) = event {
          verifyResult(status)
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
}
