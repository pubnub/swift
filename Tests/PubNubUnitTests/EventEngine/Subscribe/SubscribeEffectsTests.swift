//
//  SubscribeEffectTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest

@testable import PubNubSDK

class SubscribeEffectsTests: XCTestCase {
  private let config = PubNubConfiguration(
    publishKey: "pubKey",
    subscribeKey: "subKey",
    userId: "userId",
    automaticRetry: AutomaticRetry(retryLimit: 3, policy: .linear(delay: 2.0))
  )
}

// MARK: - HandshakingEffect

extension SubscribeEffectsTests {
  func test_HandshakeEffect_WithSuccessResponse_ReturnsHandshakeSuccessEvent() throws {
    let factory = try makeFactory(
      mockingResponse: SubscribeResponse(
        cursor: SubscribeCursor(timetoken: 12345, region: 1),
        messages: []
      )
    )

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

  func test_HandshakeEffect_WithFailedResponse_ReturnsHandshakeFailureEvent() throws {
    let factory = try makeFactory(
      error: URLError(.cannotFindHost),
      statusCode: 404
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
  func test_ReceiveEffect_WithSuccessResponse_ReturnsMessagesAndCursor() throws {
    let factory = try makeFactory(
      mockingResponse: SubscribeResponse(
        cursor: SubscribeCursor(timetoken: 12345, region: 1),
        messages: [firstMessage, secondMessage]
      )
    )

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

  func test_ReceiveEffect_WithFailedResponse_ReturnsReceiveFailureEvent() throws {
    let factory = try makeFactory(
      error: URLError(.cannotFindHost),
      statusCode: 404
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

private extension SubscribeEffectsTests {
  func makeFactory(
    mockingResponse response: SubscribeResponse? = nil,
    error: Error? = nil,
    statusCode: Int = 200
  ) throws -> SubscribeEffectFactory {
    let delegate = HTTPSessionDelegate()
    let mockUrlSession = MockURLSession(delegate: delegate)
    let httpResponse = try XCTUnwrap(HTTPURLResponse(statusCode: statusCode))
    let mockData = try XCTUnwrap(Constant.jsonEncoder.encode(response))

    mockUrlSession.responseForDataTask = { task, _ in
      task.mockError = error
      task.mockData = mockData
      task.mockResponse = httpResponse

      return task
    }

    let httpSession = HTTPSession(
      session: mockUrlSession, delegate: delegate,
      logger: PubNubLogger.defaultLogger(), sessionQueue: .main
    )

    return SubscribeEffectFactory(
      session: httpSession,
      presenceStateContainer: .init()
    )
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
