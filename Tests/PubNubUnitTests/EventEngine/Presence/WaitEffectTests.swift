//
//  WaitEffectTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest

@testable import PubNubSDK

class WaitEffectTests: XCTestCase {
  func test_WaitEffect_WithHeartbeatInterval_CompletesAfterInterval() {
    let factory = makeFactory()

    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let heartbeatInterval = 2
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: UInt(heartbeatInterval)
    )

    let effect = factory.effect(
      for: .wait,
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
    )
    let startDate = Date()

    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.elementsEqual([.timesUp]))
      let elapsed = Date().timeIntervalSince(startDate)
      XCTAssertEqual(elapsed, Double(heartbeatInterval), accuracy: 0.5)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2.5)
  }

  func test_WaitEffect_WhenCancelled_DoesNotComplete() {
    let factory = makeFactory()

    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true
    expectation.isInverted = true

    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: UInt(2)
    )
    let effect = factory.effect(
      for: .wait,
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
    )
    effect.performTask { _ in
      expectation.fulfill()
    }
    effect.cancelTask()

    wait(for: [expectation], timeout: 0.5)
  }

  func test_WaitEffect_WithZeroHeartbeatInterval_CompletesImmediatelyWithNoEvents() {
    let factory = makeFactory()

    let expectation = XCTestExpectation()
    expectation.expectationDescription = "Effect Completion Expectation"
    expectation.assertForOverFulfill = true

    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: UInt(0)
    )
    let effect = factory.effect(
      for: .wait,
      with: EventEngineDependencies(value: Presence.Dependencies(configuration: config))
    )
    effect.performTask { returnedEvents in
      XCTAssertTrue(returnedEvents.isEmpty)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 0.5)
  }
}

private extension WaitEffectTests {
  func makeFactory() -> PresenceEffectFactory {
    let delegate = HTTPSessionDelegate()
    let mockUrlSession = MockURLSession(delegate: delegate)

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
