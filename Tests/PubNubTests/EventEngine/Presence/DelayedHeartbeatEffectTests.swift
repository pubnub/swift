//
//  DelayedHeartbeatEffectTests.swift
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

class DelayedHeartbeatEffectTests: XCTestCase {
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
    delegate = nil
    mockUrlSession = nil
    httpSession = nil
    factory = nil
    super.tearDown()
  }
  
  func test_DelayedHeartbeatEffect() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    mockResponse(GenericServicePayloadResponse(status: 200))
    
    let delayRange = 2.0...3.0
    let automaticRetry = AutomaticRetry(retryLimit: 3, policy: .linear(delay: delayRange.lowerBound), excluded: [])
    let effect = configureEffectToTest(retryAttempt: 0, automaticRetry: automaticRetry, dueTo: PubNubError(.unknown))
    let startDate = Date()
    
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.elementsEqual([.heartbeatSuccess]))
      XCTAssertTrue(Int(Date().timeIntervalSince(startDate)) <= Int(delayRange.upperBound))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 2 * delayRange.upperBound)
  }
  
  func test_DelayedHeartbeatEffectFailure() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    mockResponse(GenericServicePayloadResponse(status: 500))
    
    let delayRange = 2.0...3.0
    let automaticRetry = AutomaticRetry(retryLimit: 3, policy: .linear(delay: delayRange.lowerBound), excluded: [])
    let error = PubNubError(.unknown)
    let effect = configureEffectToTest(retryAttempt: 0, automaticRetry: automaticRetry, dueTo: error)
    
    effect.performTask { returnedEvents in
      let expectedError = PubNubError(.internalServiceError)
      let expectedRes = Presence.Event.heartbeatFailed(error: expectedError)
      XCTAssertTrue(returnedEvents.elementsEqual([expectedRes]))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 2 * delayRange.upperBound)
  }
  
  func test_DelayedHeartbeatEffectGiveUp() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    let automaticRetry = AutomaticRetry(retryLimit: 3, policy: .linear(delay: 2.0), excluded: [])
    let error = PubNubError(.unknown)
    let effect = configureEffectToTest(retryAttempt: 3, automaticRetry: automaticRetry, dueTo: error)
    
    mockResponse(GenericServicePayloadResponse(status: 200))
    
    effect.performTask { returnedEvents in
      let expectedRes = Presence.Event.heartbeatGiveUp(error: PubNubError(.unknown))
      XCTAssertTrue(returnedEvents.elementsEqual([expectedRes]))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 0.5)
  }
}

private extension DelayedHeartbeatEffectTests {
  func mockResponse(_ response: GenericServicePayloadResponse) {
    mockUrlSession.responseForDataTask = { task, _ in
      task.mockError = nil
      task.mockData = try? Constant.jsonEncoder.encode(response)
      task.mockResponse = HTTPURLResponse(statusCode: response.status)
      return task
    }
  }
  
  func configureEffectToTest(
    retryAttempt attempt: Int,
    automaticRetry: AutomaticRetry?,
    dueTo error: PubNubError
  ) -> any EffectHandler<Presence.Event> {
    factory.effect(
      for: .delayedHeartbeat(
        channels: ["channel-1", "channel-2"], groups: ["group-1", "group-2"],
        retryAttempt: attempt, error: error
      ),
      with: EventEngineDependencies(value: Presence.Dependencies(
        configuration: PubNubConfiguration(
          publishKey: "pubKey",
          subscribeKey: "subKey",
          userId: "userId",
          automaticRetry: automaticRetry
        ))
      )
    )
  }
}
