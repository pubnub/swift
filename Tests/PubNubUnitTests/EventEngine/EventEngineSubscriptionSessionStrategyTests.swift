//
//  EventEngineSubscriptionSessionStrategyTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest

@testable import PubNubSDK

class EventEngineSubscriptionSessionStrategyTests: XCTestCase {
  func test_SettingAuthTokenPropagatesConfigToEngineDependencies() {
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      authToken: "initial-token"
    )

    let subscribeEngine = SubscribeEngine(
      state: Subscribe.UnsubscribedState(),
      transition: SubscribeTransition(),
      dispatcher: EffectDispatcher(factory: NoOpSubscribeEffectFactory(), logger: PubNubLogger.defaultLogger()),
      dependencies: EventEngineDependencies(value: Subscribe.Dependencies(configuration: config)),
      logger: PubNubLogger.defaultLogger()
    )
    let presenceEngine = PresenceEngine(
      state: Presence.HeartbeatInactive(),
      transition: PresenceTransition(configuration: config),
      dispatcher: EffectDispatcher(factory: NoOpPresenceEffectFactory(), logger: PubNubLogger.defaultLogger()),
      dependencies: EventEngineDependencies(value: Presence.Dependencies(configuration: config)),
      logger: PubNubLogger.defaultLogger()
    )

    let strategy = EventEngineSubscriptionSessionStrategy(
      configuration: config,
      subscribeEngine: subscribeEngine,
      presenceEngine: presenceEngine,
      presenceStateContainer: .init()
    )

    // Verify initial state
    XCTAssertEqual(
      strategy.subscribeEngine.dependencies.value.configuration.authToken,
      "initial-token"
    )

    // Simulate what PubNub.set(token:) does
    strategy.configuration.authToken = "refreshed-token"

    XCTAssertEqual(
      strategy.subscribeEngine.dependencies.value.configuration.authToken,
      "refreshed-token"
    )
    XCTAssertEqual(
      strategy.presenceEngine.dependencies.value.configuration.authToken,
      "refreshed-token"
    )
  }
}

extension EventEngineSubscriptionSessionStrategyTests {
  func test_Reconnect_FromHeartbeatCooldown_SendsImmediateHeartbeat() {
    let config = PubNubConfiguration(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId", heartbeatInterval: 30)
    let presenceFactory = RecordingPresenceEffectFactory()

    let subscribeEngine = SubscribeEngine(
      state: Subscribe.UnsubscribedState(),
      transition: SubscribeTransition(),
      dispatcher: EffectDispatcher(factory: NoOpSubscribeEffectFactory(), logger: PubNubLogger.defaultLogger()),
      dependencies: EventEngineDependencies(value: Subscribe.Dependencies(configuration: config)),
      logger: PubNubLogger.defaultLogger()
    )
    let presenceEngine = PresenceEngine(
      state: Presence.HeartbeatCooldown(input: PresenceInput(channels: ["c1"], groups: ["g1"])),
      transition: PresenceTransition(configuration: config),
      dispatcher: EffectDispatcher(factory: presenceFactory, logger: PubNubLogger.defaultLogger()),
      dependencies: EventEngineDependencies(value: Presence.Dependencies(configuration: config)),
      logger: PubNubLogger.defaultLogger()
    )
    let strategy = EventEngineSubscriptionSessionStrategy(
      configuration: config,
      subscribeEngine: subscribeEngine,
      presenceEngine: presenceEngine,
      presenceStateContainer: .init()
    )

    strategy.reconnect(at: nil)

    XCTAssertTrue(presenceEngine.state is Presence.Heartbeating)
    XCTAssertEqual(presenceFactory.heartbeatCount, 1)
  }
}

// MARK: - No-op effect factories (prevent any network activity)

private struct NoOpSubscribeEffectFactory: EffectHandlerFactory {
  func effect(
    for invocation: Subscribe.Invocation,
    with dependencies: EventEngineDependencies<Subscribe.Dependencies>
  ) -> any EffectHandler<Subscribe.Event> {
    NoOpEffectHandler()
  }
}

private struct NoOpPresenceEffectFactory: EffectHandlerFactory {
  func effect(
    for invocation: Presence.Invocation,
    with dependencies: EventEngineDependencies<Presence.Dependencies>
  ) -> any EffectHandler<Presence.Event> {
    NoOpEffectHandler()
  }
}

private class RecordingPresenceEffectFactory: EffectHandlerFactory {
  private(set) var heartbeatCount = 0

  func effect(
    for invocation: Presence.Invocation,
    with dependencies: EventEngineDependencies<Presence.Dependencies>
  ) -> any EffectHandler<Presence.Event> {
    if case .heartbeat = invocation {
      heartbeatCount += 1
    }
    return NoOpEffectHandler()
  }
}

private struct NoOpEffectHandler<Event>: EffectHandler {
  func performTask(completionBlock: @escaping ([Event]) -> Void) {
    completionBlock([])
  }
}
