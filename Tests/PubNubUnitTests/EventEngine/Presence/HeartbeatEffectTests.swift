//
//  HeartbeatEffectTests.swift
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

class HeartbeatEffectTests: XCTestCase {
  private let config = PubNubConfiguration(
    publishKey: "pubKey",
    subscribeKey: "subKey",
    userId: "userId",
    heartbeatInterval: 30
  )

  func test_HeartbeatEffect_WithSuccessResponse_ReturnsHeartbeatSuccessEvent() throws {
    let factory = try makeFactory(mockingResponse: GenericServicePayloadResponse(status: 200))

    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let effect = factory.effect(
      for: .heartbeat(channels: ["channel-1", "channel-2"], groups: ["group-1", "group-2"]),
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
    )
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.elementsEqual([.heartbeatSuccess]))
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 0.5)
  }

  func test_HeartbeatEffect_WithFailedResponse_ReturnsHeartbeatFailedEvent() throws {
    let factory = try makeFactory(mockingResponse: GenericServicePayloadResponse(status: 500))

    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let effect = factory.effect(
      for: .heartbeat(channels: ["channel-1", "channel-2"], groups: ["group-1", "group-2"]),
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
    )
    effect.performTask { returnedEvents in
      let expectedError = PubNubError(.internalServiceError)
      let expectedEvent = Presence.Event.heartbeatFailed(error: expectedError)
      XCTAssertTrue(returnedEvents.elementsEqual([expectedEvent]))
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 0.5)
  }
}

private extension HeartbeatEffectTests {
  func makeFactory(mockingResponse response: GenericServicePayloadResponse) throws -> PresenceEffectFactory {
    let mockData = try XCTUnwrap(Constant.jsonEncoder.encode(response))
    let delegate = HTTPSessionDelegate()
    let mockUrlSession = MockURLSession(delegate: delegate)

    mockUrlSession.responseForDataTask = { task, _ in
      task.mockError = nil
      task.mockData = mockData
      task.mockResponse = HTTPURLResponse(statusCode: response.status)
      return task
    }

    let httpSession = HTTPSession(
      session: mockUrlSession,
      delegate: delegate,
      logger: PubNubLogger.defaultLogger(),
      sessionQueue: .main
    )

    return PresenceEffectFactory(
      session: httpSession,
      presenceStateContainer: .shared
    )
  }
}
