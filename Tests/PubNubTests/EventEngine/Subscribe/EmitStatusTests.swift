//
//  EmitStatusTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
        error: PubNubError(.unknown)
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
