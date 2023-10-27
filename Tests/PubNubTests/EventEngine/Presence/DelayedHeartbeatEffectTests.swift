//
//  DelayedHeartbeatEffectTests.swift
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

class DelayedHeartbeatEffectTests: XCTestCase {
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
  
  func test_DelayedHeartbeatEffectFiresImmediatelyForFirstAttempt() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    mockResponse(GenericServicePayloadResponse(status: 200))
    
    let timeout: UInt = 4
    let effect = configureEffect(attempt: 0, durationUntilTimeout: timeout, error: PubNubError(.unknown))
    let startDate = Date()
    
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.elementsEqual([.heartbeatSuccess]))
      XCTAssertEqual(Int(Date().timeIntervalSince(startDate)), 0)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_DelayedHeartbeatEffectIsShiftedForSecondAttempt() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    mockResponse(GenericServicePayloadResponse(status: 200))
    
    let timeout: UInt = 4
    let effect = configureEffect(attempt: 1, durationUntilTimeout: timeout, error: PubNubError(.unknown))
    let startDate = Date()
    
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.elementsEqual([.heartbeatSuccess]))
      XCTAssertEqual(Int(Date().timeIntervalSince(startDate)), Int(timeout) / 2)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2.5)
  }
  
  func test_DelayedHeartbeatEffectIsShiftedForThirdAttempt() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    mockResponse(GenericServicePayloadResponse(status: 200))
    
    let timeout: UInt = 4
    let effect = configureEffect(attempt: 2, durationUntilTimeout: timeout, error: PubNubError(.unknown))
    let startDate = Date()
    
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.elementsEqual([.heartbeatSuccess]))
      XCTAssertEqual(Int(Date().timeIntervalSince(startDate)), Int(0.5 * Double(timeout)) - 1)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 3.5)
  }
  
  func test_DelayedHeartbeatEffectFailure() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    mockResponse(GenericServicePayloadResponse(status: 500))
    
    let timeout: UInt = 4
    let error = PubNubError(.unknown)
    let effect = configureEffect(attempt: 0, durationUntilTimeout: timeout, error: error)
    
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.elementsEqual([.heartbeatFailed(error: PubNubError(.internalServiceError))]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_DelayedHeartbeatEffectGiveUp() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
        
    let timeout: UInt = 4
    let error = PubNubError(.unknown)
    let effect = configureEffect(attempt: 3, durationUntilTimeout: timeout, error: error)
    
    mockResponse(GenericServicePayloadResponse(status: 200))
    
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.elementsEqual([.heartbeatGiveUp(error: PubNubError(.unknown))]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 3.5)
  }
}

fileprivate extension DelayedHeartbeatEffectTests {
  func mockResponse(_ response: GenericServicePayloadResponse) {
    mockUrlSession.responseForDataTask = { task, id in
      task.mockError = nil
      task.mockData = try? Constant.jsonEncoder.encode(response)
      task.mockResponse = HTTPURLResponse(statusCode: response.status)
      return task
    }
  }
  
  func configureEffect(attempt: Int, durationUntilTimeout: UInt, error: PubNubError) -> any EffectHandler<Presence.Event> {
    factory.effect(
      for: .delayedHeartbeat(
        channels: ["channel-1", "channel-2"], groups: ["group-1", "group-2"],
        retryAttempt: attempt, error: PubNubError(.unknown)
      ),
      with: EventEngineCustomInput(value: Presence.EngineInput(
        configuration: PubNubConfiguration(
          publishKey: "pubKey",
          subscribeKey: "subKey",
          userId: "userId",
          durationUntilTimeout: durationUntilTimeout
        ))
      )
    )
  }
}
