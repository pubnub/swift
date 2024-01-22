//
//  LeaveEffectTests.swift
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

class LeaveEffectTests: XCTestCase {
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
  
  func test_LeaveEffect() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
  
    mockResponse(GenericServicePayloadResponse(status: 200))
    
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: 2
    )
    let effect = factory.effect(
      for: .leave(channels: ["c1", "c2"], groups: ["g1", "g2"]),
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
    )
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.isEmpty)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_LeaveEffectForFailedRequest() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
  
    mockResponse(GenericServicePayloadResponse(status: 500))
    
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: 2
    )
    let effect = factory.effect(
      for: .leave(channels: ["c1", "c2"], groups: ["g1", "g2"]),
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
    )
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.isEmpty)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
}

fileprivate extension LeaveEffectTests {
  func mockResponse(_ response: GenericServicePayloadResponse) {
    mockUrlSession.responseForDataTask = { task, id in
      task.mockError = nil
      task.mockData = try? Constant.jsonEncoder.encode(response)
      task.mockResponse = HTTPURLResponse(statusCode: response.status)
      return task
    }
  }
}
