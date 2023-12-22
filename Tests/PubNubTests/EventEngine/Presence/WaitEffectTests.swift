//
//  WaitEffectTests.swift
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

class WaitEffectTests: XCTestCase {
  private var mockUrlSession: MockURLSession!
  private var httpSession: HTTPSession!
  private var delegate: HTTPSessionDelegate!
  private var factory: PresenceEffectFactory!
      
  override func setUp() {
    delegate = HTTPSessionDelegate()
    mockUrlSession = MockURLSession(delegate: delegate)
    httpSession = HTTPSession(session: mockUrlSession, delegate: delegate, sessionQueue: .main)
    factory = PresenceEffectFactory(session: httpSession, presenceStateContainer: .shared)
    
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
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
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
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
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
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
    )
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.isEmpty)
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 0.5)
  }
}
