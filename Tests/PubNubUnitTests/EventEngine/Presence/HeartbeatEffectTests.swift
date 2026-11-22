//
//  HeartbeatEffectTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

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

  func test_CancelTask_WithPendingHeartbeat_CancelsRequest() {
    let request = MockHeartbeatRequest(configuration: config)
    let effect = HeartbeatEffect(request: request)

    effect.performTask { _ in }
    effect.cancelTask()

    XCTAssertEqual(request.cancelCount, 1)
    withExtendedLifetime(effect) {}
  }

  func test_HeartbeatSuccess_AfterCancellation_EmitsNoEvents() throws {
    let request = MockHeartbeatRequest(configuration: config)
    let effect = HeartbeatEffect(request: request)

    var events: [Presence.Event] = []
    effect.performTask { events.append(contentsOf: $0) }
    let completion = try XCTUnwrap(request.completion)
    effect.cancelTask()

    completion(.success(()))

    XCTAssertTrue(events.isEmpty)
    withExtendedLifetime(effect) {}
  }

  func test_HeartbeatFailure_AfterCancellation_EmitsNoEvents() throws {
    let request = MockHeartbeatRequest(configuration: config)
    let effect = HeartbeatEffect(request: request)

    var events: [Presence.Event] = []
    effect.performTask { events.append(contentsOf: $0) }
    let completion = try XCTUnwrap(request.completion)
    effect.cancelTask()

    completion(.failure(PubNubError(.unknown)))

    XCTAssertTrue(events.isEmpty)
    withExtendedLifetime(effect) {}
  }
}

private extension HeartbeatEffectTests {
  func makeFactory(mockingResponse response: GenericServicePayloadResponse) throws -> PresenceEffectFactory {
    let mockData = try XCTUnwrap(Constant.jsonEncoder.encode(response))
    let mockResponse = try XCTUnwrap(HTTPURLResponse(statusCode: response.status))
    let delegate = HTTPSessionDelegate()
    let mockUrlSession = MockURLSession(delegate: delegate)

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

private class MockHeartbeatRequest: PresenceHeartbeatRequest {
  var cancelCount = 0
  var completion: ((Result<Void, PubNubError>) -> Void)?

  init(configuration: PubNubConfiguration) {
    let delegate = HTTPSessionDelegate()
    let session = HTTPSession(
      session: MockURLSession(delegate: delegate),
      delegate: delegate,
      logger: PubNubLogger.defaultLogger(),
      sessionQueue: .main
    )
    super.init(
      channels: [],
      groups: [],
      channelStates: [:],
      configuration: configuration,
      session: session,
      sessionResponseQueue: .main
    )
  }

  override func execute(completionBlock: @escaping (Result<Void, PubNubError>) -> Void) {
    completion = completionBlock
  }

  override func cancel() {
    cancelCount += 1
  }
}
