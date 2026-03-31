//
//  SubscribeEffectTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest

@testable import PubNubSDK

class SubscribeEffectsTests: XCTestCase {
  private var mockUrlSession: MockURLSession!
  private var httpSession: HTTPSession!
  private var delegate: HTTPSessionDelegate!
  private var factory: SubscribeEffectFactory!
  
  private let config = PubNubConfiguration(
    publishKey: "pubKey",
    subscribeKey: "subKey",
    userId: "userId",
    automaticRetry: AutomaticRetry(retryLimit: 3, policy: .linear(delay: 2.0))
  )
  
  private func configWithLinearPolicy(_ delay: Double = 2.0) -> PubNubConfiguration {
    PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      automaticRetry: AutomaticRetry(retryLimit: 3, policy: .linear(delay: delay), excluded: [])
    )
  }
  
  override func setUp() {
    delegate = HTTPSessionDelegate()
    mockUrlSession = MockURLSession(delegate: delegate)
    httpSession = HTTPSession(session: mockUrlSession, delegate: delegate, logger: PubNubLogger.defaultLogger(), sessionQueue: .main)
    factory = SubscribeEffectFactory(session: httpSession, presenceStateContainer: .shared)
    super.setUp()
  }
  
  override func tearDown() {
    delegate = nil
    mockUrlSession = nil
    httpSession = nil
    factory = nil
    super.tearDown()
  }
}

// MARK: - HandshakingEffect

extension SubscribeEffectsTests {
  func test_HandshakingEffectWithSuccessResponse() {
    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: []
    ))
    
    let expectation = XCTestExpectation(description: "Effect Completion")
    expectation.expectedFulfillmentCount = 1
    expectation.assertForOverFulfill = true
    
    let testedInvocation: Subscribe.Invocation = .handshakeRequest(
      channels: ["channel1", "channel1-pnpres", "channel2"],
      groups: ["g1", "g2", "g2-pnpres"]
    )
    let effect = factory.effect(
      for: testedInvocation,
      with: EventEngineDependencies(value: Subscribe.Dependencies(configuration: config))
    )
    let expectedOutput: Subscribe.Event = .handshakeSuccess(
      cursor: SubscribeCursor(timetoken: 12345, region: 1)
    )
    
    effect.performTask {
      XCTAssertEqual([expectedOutput], $0)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }
  
  func test_HandshakingEffectWithFailedResponse() {
    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    
    let expectation = XCTestExpectation(description: "Effect Completion")
    expectation.expectedFulfillmentCount = 1
    expectation.assertForOverFulfill = true

    let testedInvocation: Subscribe.Invocation = .handshakeRequest(
      channels: ["channel1", "channel1-pnpres", "channel2"],
      groups: ["g1", "g2", "g2-pnpres"]
    )
    let expectedOutput: Subscribe.Event = .handshakeFailure(
      error: PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost))
    )
    let effect = factory.effect(
      for: testedInvocation,
      with: EventEngineDependencies(value: Subscribe.Dependencies(configuration: config))
    )
    
    effect.performTask {
      XCTAssertEqual([expectedOutput], $0)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: ReceivingEffect

extension SubscribeEffectsTests {
  func test_ReceivingEffectWithSuccessResponse() {
    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: [firstMessage, secondMessage]
    ))
    
    let expectation = XCTestExpectation(description: "Effect Completion")
    expectation.expectedFulfillmentCount = 1
    expectation.assertForOverFulfill = true
    
    let testedInvocation: Subscribe.Invocation = .receiveMessages(
      channels: ["channel1", "channel1-pnpres", "channel2"],
      groups: ["g1", "g2", "g2-pnpres"],
      cursor: SubscribeCursor(timetoken: 111, region: 1)
    )
    let expectedOutput: Subscribe.Event = .receiveSuccess(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: [firstMessage, secondMessage]
    )
    let effect = factory.effect(
      for: testedInvocation,
      with: EventEngineDependencies(value: Subscribe.Dependencies(configuration: config))
    )
    
    effect.performTask {
      XCTAssertEqual([expectedOutput], $0)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }
  
  func test_ReceivingEffectWithFailedResponse() {
    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    
    let expectation = XCTestExpectation(description: "Effect Completion")
    expectation.expectedFulfillmentCount = 1
    expectation.assertForOverFulfill = true
    
    let testedInvocation: Subscribe.Invocation = .receiveMessages(
      channels: ["channel1", "channel1-pnpres", "channel2"],
      groups: ["g1", "g2", "g2-pnpres"],
      cursor: SubscribeCursor(timetoken: 111, region: 1)
    )
    let expectedOutput: Subscribe.Event = .receiveFailure(
      error: PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost))
    )
    let effect = factory.effect(
      for: testedInvocation,
      with: EventEngineDependencies(value: Subscribe.Dependencies(configuration: config))
    )
    
    effect.performTask {
      XCTAssertEqual([expectedOutput], $0)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Helpers

private extension SubscribeEffectsTests {
  func mockResponse(
    subscribeResponse: SubscribeResponse? = nil,
    errorIfAny: Error? = nil,
    httpResponse: HTTPURLResponse = HTTPURLResponse(statusCode: 200)!
  ) {
    mockUrlSession.responseForDataTask = { task, _ in
      task.mockError = errorIfAny
      task.mockData = try? Constant.jsonEncoder.encode(subscribeResponse)
      task.mockResponse = httpResponse
      return task
    }
  }
}

private let firstMessage = SubscribeMessagePayload(
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
  meta: nil,
  error: nil
)

private let secondMessage = SubscribeMessagePayload(
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
  meta: nil,
  error: nil
)
