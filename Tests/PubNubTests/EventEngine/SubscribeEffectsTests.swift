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
  
  private lazy var factory = SubscribeEffectFactory(
    configuration: PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      automaticRetry: AutomaticRetry(
        retryLimit: 3,
        policy: AutomaticRetry.ReconnectionPolicy.immediately
      )
    ),
    session: httpSession
  )
  
  override func setUp() {
    delegate = HTTPSessionDelegate()
    mockUrlSession = MockURLSession(delegate: delegate)
    httpSession = HTTPSession(session: mockUrlSession, delegate: delegate, sessionQueue: .main)
    super.setUp()
  }
  
  override func tearDown() {
    mockUrlSession = nil
    delegate = nil
    httpSession = nil
    super.tearDown()
  }
  
  func test_HandshakingEffectWithSuccessResponse() {
    let effect = factory.effect(
      for: .handshakeRequest(channels: ["test-channel"], groups: [])
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(subscribeResponse: SubscribeResponse(
        cursor: SubscribeCursor(timetoken: 12345, region: 1),
        messages: []
      ))
    }, verifyResults: { results in
      if case let .handshakeSucceess(cursor) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(cursor == SubscribeCursor(timetoken: 12345, region: 1))
      } else {
        XCTFail("Unexpected condition")
      }
    })
  }
  
  func test_HandshakingEffectWithFailedResponse() {
    let effect = factory.effect(
      for: .handshakeRequest(channels: ["test-channel"], groups: [])
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(
        errorIfAny: URLError(.cannotFindHost),
        httpResponse: HTTPURLResponse(statusCode: 404)!
      )
    }, verifyResults: { results in
      if case let .handshakeFailure(error) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(error.underlying == PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost)))
      } else {
        XCTFail("Unexpected condition")
      }
    })
  }
  
  func test_ReceivingEffectWithSuccessResponse() {
    let effect = factory.effect(
      for: .receiveMessages(
        channels: ["test-channel"],
        groups: [],
        cursor: SubscribeCursor(timetoken: 111, region: 1)
      )
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(subscribeResponse: SubscribeResponse(
        cursor: SubscribeCursor(timetoken: 12345, region: 1),
        messages: [firstMessage, secondMessage]
      ))
    }, verifyResults: { results in
      if case let .receiveSuccess(cursor, messages) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(cursor == SubscribeCursor(timetoken: 12345, region: 1))
        XCTAssertTrue(messages == [firstMessage, secondMessage])
      } else {
        XCTFail("Unexpected condition")
      }
    })
  }
  
  func test_ReceivingEffectWithFailedResponse() {
    let effect = factory.effect(
      for: .receiveMessages(
        channels: ["test-channel"],
        groups: [],
        cursor: SubscribeCursor(timetoken: 111, region: 1)
      )
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(
        errorIfAny: URLError(.cannotFindHost),
        httpResponse: HTTPURLResponse(statusCode: 404)!
      )
    }, verifyResults: { results in
      if case let .receiveFailure(error) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(error.underlying == PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost)))
      } else {
        XCTFail("Unexpected condition")
      }
    })
  }
  
  func test_HandshakeReconnectingSuccess() {
    let error = SubscribeError(
      underlying: PubNubError(.badServerResponse, underlying: URLError(.badServerResponse))
    )
    let effect = factory.effect(
      for: .handshakeReconnect(
        channels: ["test-channel"],
        groups: [],
        currentAttempt: 1,
        reason: error
      )
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(subscribeResponse: SubscribeResponse(
        cursor: SubscribeCursor(timetoken: 12345, region: 1),
        messages: []
      ))
    }, verifyResults: { results in
      if case let .handshakeReconnectSuccess(cursor) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(cursor == SubscribeCursor(timetoken: 12345, region: 1))
      } else {
        XCTFail("Unexpected condition")
      }
    })
  }
  
  func test_HandshakeReconnectingFailed() {
    let error = SubscribeError(
      underlying: PubNubError(.badServerResponse, underlying: URLError(.badServerResponse))
    )
    let effect = factory.effect(
      for: .handshakeReconnect(
        channels: ["test-channel"],
        groups: [],
        currentAttempt: 1,
        reason: error
      )
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(
        errorIfAny: URLError(.cannotFindHost),
        httpResponse: HTTPURLResponse(statusCode: 404)!
      )
    }, verifyResults: { results in
      if case let .handshakeReconnectFailure(error) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(error.underlying == PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost)))
      } else {
        XCTFail("Unexpected condition")
      }
    })
  }
  
  func test_HandshakeReconnectGiveUp() {
    let error = SubscribeError(
      underlying: PubNubError(.badServerResponse, underlying: URLError(.badServerResponse))
    )
    let effect = factory.effect(
      for: .handshakeReconnect(
        channels: ["test-channel"],
        groups: [],
        currentAttempt: 2,
        reason: error
      )
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(
        errorIfAny: URLError(.cannotFindHost),
        httpResponse: HTTPURLResponse(statusCode: 404)!
      )
    }, verifyResults: { results in
      if case let .handshakeReconnectGiveUp(error) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(error.underlying == PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost)))
      } else {
        XCTFail("Unexpected condition")
      }
    })
  }
  
  func test_ReceiveReconnectingSuccess() {
    let error = SubscribeError(
      underlying: PubNubError(.badServerResponse, underlying: URLError(.badServerResponse))
    )
    let effect = factory.effect(
      for: .receiveReconnect(
        channels: ["test-channel"],
        group: [],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        currentAttempt: 1,
        reason: error
      )
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(subscribeResponse: SubscribeResponse(
        cursor: SubscribeCursor(timetoken: 12345, region: 1),
        messages: [firstMessage, secondMessage]
      ))
    }, verifyResults: { results in
      if case let .receiveReconnectSuccess(cursor, messages) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(cursor == SubscribeCursor(timetoken: 12345, region: 1))
        XCTAssertTrue(messages == [firstMessage, secondMessage])
      } else {
        XCTFail("Unexpected condition")
      }
    })
  }
  
  func test_ReceiveReconnectingFailure() {
    let error = SubscribeError(
      underlying: PubNubError(.badServerResponse, underlying: URLError(.badServerResponse))
    )
    let effect = factory.effect(
      for: .receiveReconnect(
        channels: ["test-channel"],
        group: [],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        currentAttempt: 1,
        reason: error
      )
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(
        errorIfAny: URLError(.cannotFindHost),
        httpResponse: HTTPURLResponse(statusCode: 404)!
      )
    }, verifyResults: { results in
      if case let .receiveReconnectFailure(error) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(error.underlying == PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost)))
      } else {
        XCTFail("Unexpected condition")
      }
    })
  }
  
  func test_ReceiveReconnectGiveUp() {
    let error = SubscribeError(
      underlying: PubNubError(.badServerResponse, underlying: URLError(.badServerResponse))
    )
    let effect = factory.effect(
      for: .receiveReconnect(
        channels: ["test-channel"],
        group: [],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        currentAttempt: 2,
        reason: error
      )
    )
    testEffect(effect: effect, mockResponse: {
      mockResponse(
        errorIfAny: URLError(.cannotFindHost),
        httpResponse: HTTPURLResponse(statusCode: 404)!
      )
    }, verifyResults: { results in
      if case let .receiveReconnectGiveUp(error) = results[0] {
        XCTAssertTrue(results.count == 1)
        XCTAssertTrue(error.underlying == PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost)))
      } else {
        XCTFail("Unexpected condition")
      }
    })
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
  
  func testEffect(
    effect: some EffectHandler<Subscribe.Event>,
    mockResponse: () -> Void,
    verifyResults: @escaping ([Subscribe.Event]) -> Void
  ) {
    mockResponse()
    
    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    
    effect.performTask(completionBlock: { events in
      verifyResults(events)
      expectation.fulfill()
    })
    
    wait(for: [expectation], timeout: 0.5)
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
