//
//  File.swift
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

class SubscribeEffectsTests: XCTestCase {
  private var mockUrlSession: MockURLSession!
  private var httpSession: HTTPSession!
  private var delegate: HTTPSessionDelegate!
  private var factory: SubscribeEffectFactory!
  
  private let config = PubNubConfiguration(
    publishKey: "pubKey",
    subscribeKey: "subKey",
    userId: "userId",
    automaticRetry: AutomaticRetry(
      retryLimit: 3,
      policy: .immediately
    )
  )
  
  private func configWithLinearPolicy(_ delay: Double = 1.0) -> PubNubConfiguration {
    PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      automaticRetry: AutomaticRetry(retryLimit: 3, policy: .linear(delay: delay))
    )
  }
  
  override func setUp() {
    delegate = HTTPSessionDelegate()
    mockUrlSession = MockURLSession(delegate: delegate)
    httpSession = HTTPSession(session: mockUrlSession, delegate: delegate, sessionQueue: .main)
    factory = SubscribeEffectFactory(session: httpSession)
    
    super.setUp()
  }
  
  override func tearDown() {
    mockUrlSession = nil
    delegate = nil
    httpSession = nil
    super.tearDown()
  }
  
  func test_HandshakingEffectWithSuccessResponse() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: []
    ))
    
    let effect = factory.effect(
      for: .handshakeRequest(channels: ["test-channel"], groups: []),
      with: EventEngineCustomInput(value: Subscribe.EngineInput(configuration: config))
    )
    effect.performTask { returnedEvents in
      let expectedCursor = SubscribeCursor(timetoken: 12345, region: 1)
      let expectedEvent = Subscribe.Event.handshakeSuccess(cursor: expectedCursor)
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_HandshakingEffectWithFailedResponse() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    
    let effect = factory.effect(
      for: .handshakeRequest(channels: ["test-channel"], groups: []),
      with: EventEngineCustomInput(
        value: Subscribe.EngineInput(configuration: config)
      )
    )
    effect.performTask { returnedEvents in
      let expectedUnderlyingErr = PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost))
      let expectedEvent = Subscribe.Event.handshakeFailure(error: SubscribeError(underlying: expectedUnderlyingErr))
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_ReceivingEffectWithSuccessResponse() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: [firstMessage, secondMessage]
    ))
    
    let effect = factory.effect(
      for: .receiveMessages(
        channels: ["test-channel"],
        groups: [],
        cursor: SubscribeCursor(timetoken: 111, region: 1)
      ), with: EventEngineCustomInput(
        value: Subscribe.EngineInput(configuration: config)
      )
    )
    effect.performTask { returnedEvents in
      let expectedCursor = SubscribeCursor(timetoken: 12345, region: 1)
      let expectedEvent = Subscribe.Event.receiveSuccess(cursor: expectedCursor, messages: [firstMessage, secondMessage])
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_ReceivingEffectWithFailedResponse() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    
    let effect = factory.effect(
      for: .receiveMessages(
        channels: ["test-channel"],
        groups: [],
        cursor: SubscribeCursor(timetoken: 111, region: 1)
      ), with: EventEngineCustomInput(
        value: Subscribe.EngineInput(configuration: config)
      )
    )
    effect.performTask { returnedEvents in
      let expectedUnderlyingErr = PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost))
      let expectedEvent = Subscribe.Event.receiveFailure(error: SubscribeError(underlying: expectedUnderlyingErr))
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_HandshakeReconnectingSuccess() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let urlError = URLError(.badServerResponse)
    
    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: []
    ))
    
    let effect = factory.effect(
      for: .handshakeReconnect(
        channels: ["test-channel"],
        groups: [],
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: EventEngineCustomInput(value: Subscribe.EngineInput(configuration: config))
    )
    effect.performTask { returnedEvents in
      let expectedCursor = SubscribeCursor(timetoken: 12345, region: 1)
      let expectedEvent = Subscribe.Event.handshakeReconnectSuccess(cursor: expectedCursor)
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_HandshakeReconnectingFailed() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    let customInput = EventEngineCustomInput(value: Subscribe.EngineInput(configuration: config))
    let urlError = URLError(.badServerResponse)

    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    let effect = factory.effect(
      for: .handshakeReconnect(
        channels: ["test-channel"],
        groups: [],
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: customInput
    )
    effect.performTask { returnedEvents in
      let expectedUnderlyingErr = PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost))
      let expectedEvent = Subscribe.Event.handshakeReconnectFailure(error: SubscribeError(underlying: expectedUnderlyingErr))
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_HandshakeReconnectGiveUp() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let customInput = EventEngineCustomInput(value: Subscribe.EngineInput(configuration: config))
    let urlError = URLError(.badServerResponse)
        
    let effect = factory.effect(
      for: .handshakeReconnect(
        channels: ["test-channel"],
        groups: [],
        retryAttempt: 3,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: customInput
    )
    effect.performTask { returnedEvents in
      let expectedUnderlyingErr = PubNubError(.badServerResponse)
      let expectedEvent = Subscribe.Event.handshakeReconnectGiveUp(error: SubscribeError(underlying: expectedUnderlyingErr))
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_HandshakeReconnectIsDelayed() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let delay = 1.0
    let customInput = EventEngineCustomInput(value: Subscribe.EngineInput(configuration: configWithLinearPolicy(delay)))
    let urlError = URLError(.badServerResponse)
    
    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: []
    ))
    
    let startDate = Date()
    let effect = factory.effect(
      for: .handshakeReconnect(
        channels: ["test-channel"],
        groups: [],
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: customInput
    )
    effect.performTask { _ in
      XCTAssertTrue(Int(Date().timeIntervalSince(startDate)) == Int(delay))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.5)
  }
  
  func test_ReceiveReconnectingSuccess() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let customInput = EventEngineCustomInput(value: Subscribe.EngineInput(configuration: config))
    let urlError = URLError(.badServerResponse)

    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: [firstMessage, secondMessage]
    ))
    
    let effect = factory.effect(
      for: .receiveReconnect(
        channels: ["test-channel"],
        groups: [],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: customInput
    )
    effect.performTask { returnedEvents in
      let expectedCursor = SubscribeCursor(timetoken: 12345, region: 1)
      let expectedEvent = Subscribe.Event.receiveReconnectSuccess(cursor: expectedCursor, messages: [firstMessage, secondMessage])
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_ReceiveReconnectingFailure() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let customInput = EventEngineCustomInput(value: Subscribe.EngineInput(configuration: config))
    let urlError = URLError(.badServerResponse)
    
    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )

    let effect = factory.effect(
      for: .receiveReconnect(
        channels: ["test-channel"],
        groups: [],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: customInput
    )
    effect.performTask { returnedEvents in
      let expectedUnderlyingErr = PubNubError(.nameResolutionFailure)
      let expectedEvent = Subscribe.Event.receiveReconnectFailure(error: SubscribeError(underlying: expectedUnderlyingErr))
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_ReceiveReconnectGiveUp() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let customInput = EventEngineCustomInput(value: Subscribe.EngineInput(configuration: config))
    let urlError = URLError(.badServerResponse)
    
    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )

    let effect = factory.effect(
      for: .receiveReconnect(
        channels: ["test-channel"],
        groups: [],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        retryAttempt: 3,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: customInput
    )
    effect.performTask { returnedEvents in
      let expectedUnderlyingErr = PubNubError(.badServerResponse)
      let expectedEvent = Subscribe.Event.receiveReconnectGiveUp(error: SubscribeError(underlying: expectedUnderlyingErr))
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.5)
  }
  
  func test_ReceiveReconnectingIsDelayed() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let delay = 1.0
    let customInput = EventEngineCustomInput(value: Subscribe.EngineInput(configuration: configWithLinearPolicy(delay)))
    let urlError = URLError(.badServerResponse)
    
    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: [firstMessage, secondMessage]
    ))
    
    let startDate = Date()
    let effect = factory.effect(
      for: .receiveReconnect(
        channels: ["test-channel"],
        groups: [],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: customInput
    )
    effect.performTask { _ in
      XCTAssertTrue(Int(Date().timeIntervalSince(startDate)) == Int(delay))
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.5)
  }
  
  func test_CancelledHandshakeReconnect() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    expectation.isInverted = true
    
    let customInput = EventEngineCustomInput(value: Subscribe.EngineInput(configuration: configWithLinearPolicy(1.0)))
    let urlError = URLError(.badServerResponse)

    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: []
    ))
    
    let effect = factory.effect(
      for: .handshakeReconnect(
        channels: ["test-channel"],
        groups: [],
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: customInput
    )
    effect.performTask { returnedEvents in
      expectation.fulfill()
    }
    effect.cancelTask()
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func test_CancelledReceiveReconnect() {
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    expectation.isInverted = true
    
    let customInput = EventEngineCustomInput(value: Subscribe.EngineInput(configuration: configWithLinearPolicy(1.0)))
    let urlError = URLError(.badServerResponse)

    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: [firstMessage, secondMessage]
    ))
    
    let effect = factory.effect(
      for: .receiveReconnect(
        channels: ["test-channel"],
        groups: [],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
      ), with: customInput
    )
    effect.performTask { returnedEvents in
      expectation.fulfill()
    }
    effect.cancelTask()
    
    wait(for: [expectation], timeout: 1.0)
  }
}

fileprivate extension SubscribeEffectsTests {
  func mockResponse(
    subscribeResponse: SubscribeResponse? = nil,
    errorIfAny: Error? = nil,
    httpResponse: HTTPURLResponse = HTTPURLResponse(statusCode: 200)!
  ) {
    mockUrlSession.responseForDataTask = { task, id in
      task.mockError = errorIfAny
      task.mockData = try? Constant.jsonEncoder.encode(subscribeResponse)
      task.mockResponse = httpResponse
      return task
    }
  }
}

fileprivate let firstMessage = SubscribeMessagePayload(
  shard: "",
  subscription: nil,
  channel: "test-channel",
  messageType: .message,
  payload: ["message": "hello!"],
  flags: 123,
  publisher: "publisher",
  subscribeKey: "FakeKey",
  originTimetoken: nil,
  publishTimetoken: SubscribeCursor(timetoken: 12312412412, region: 12),
  meta: nil
)

fileprivate let secondMessage = SubscribeMessagePayload(
  shard: "",
  subscription: nil,
  channel: "test-channel",
  messageType: .messageAction,
  payload: ["reaction": "👍"],
  flags: 456,
  publisher: "second-publisher",
  subscribeKey: "FakeKey",
  originTimetoken: nil,
  publishTimetoken: SubscribeCursor(timetoken: 12312412555, region: 12),
  meta: nil
)
