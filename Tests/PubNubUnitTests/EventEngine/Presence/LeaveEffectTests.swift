//
//  LeaveEffectTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest

@testable import PubNubSDK

class LeaveEffectTests: XCTestCase {
  func test_LeaveEffect_WithSuccessResponse_ReturnsNoEvents() throws {
    let factory = try makeFactory(mockingResponse: GenericServicePayloadResponse(status: 200))

    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

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

  func test_LeaveEffect_WithFailedResponse_ReturnsNoEvents() throws {
    let factory = try makeFactory(mockingResponse: GenericServicePayloadResponse(status: 500))

    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

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

private extension LeaveEffectTests {
  func makeFactory(mockingResponse response: GenericServicePayloadResponse) throws -> PresenceEffectFactory {
    let delegate = HTTPSessionDelegate()
    let mockUrlSession = MockURLSession(delegate: delegate)
    let mockData = try XCTUnwrap(Constant.jsonEncoder.encode(response))
    let mockResponse = try XCTUnwrap(HTTPURLResponse(statusCode: response.status))

    mockUrlSession.responseForDataTask = { task, _ in
      task.mockError = nil
      task.mockData = mockData
      task.mockResponse = mockResponse

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
      presenceStateContainer: .init()
    )
  }
}
