//
//  WaitEffectTests.swift
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

class WaitEffectTests: XCTestCase {
  private var mockUrlSession: MockURLSession!
  private var httpSession: HTTPSession!
  private var delegate: HTTPSessionDelegate!
  private var factory: PresenceEffectFactory!
      
  override func setUp() {
    delegate = HTTPSessionDelegate()
    mockUrlSession = MockURLSession(delegate: delegate)
    httpSession = HTTPSession(session: mockUrlSession, delegate: delegate, sessionQueue: .main)
    factory = PresenceEffectFactory(session: httpSession)
    
    super.setUp()
  }
  
  override func tearDown() {
    mockUrlSession = nil
    delegate = nil
    httpSession = nil
    super.tearDown()
  }
  
  func test_WaitEffect() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
  
    let heartbeatInterval = 2
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: UInt(heartbeatInterval)
    )
            
    let effect = factory.effect(
      for: .wait,
      with: EventEngineCustomInput(value: Presence.EngineInput(configuration: config))
    )
    let startDate = Date()

    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.elementsEqual([.timesUp]))
      XCTAssertTrue(Int(Date().timeIntervalSince(startDate)) == heartbeatInterval)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2.5)
  }
  
  func test_WaitEffectCancellation() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    expectation.isInverted = true
    
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: UInt(2)
    )            
    let effect = factory.effect(
      for: .wait,
      with: EventEngineCustomInput(value: Presence.EngineInput(configuration: config))
    )
    effect.performTask { returnedEvents in
      expectation.fulfill()
    }
    effect.cancelTask()
    
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_WaitEffectFinishesImmediatelyWithEmptyHeartbeatInterval() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: UInt(0)
    )
    let effect = factory.effect(
      for: .wait,
      with: EventEngineCustomInput(value: Presence.EngineInput(configuration: config))
    )
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.isEmpty)
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 0.5)
  }
}
