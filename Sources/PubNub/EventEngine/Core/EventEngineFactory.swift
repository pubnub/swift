//
//  EventEngineFactory.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

typealias SubscribeEngine = EventEngine<(any SubscribeState), Subscribe.Event, Subscribe.Invocation, Subscribe.Dependencies>
typealias PresenceEngine = EventEngine<(any PresenceState), Presence.Event, Presence.Invocation, Presence.Dependencies>

typealias SubscribeTransitions = TransitionProtocol<(any SubscribeState), Subscribe.Event, Subscribe.Invocation>
typealias PresenceTransitions = TransitionProtocol<(any PresenceState), Presence.Event, Presence.Invocation>
typealias SubscribeDispatcher = Dispatcher<Subscribe.Invocation, Subscribe.Event, Subscribe.Dependencies>
typealias PresenceDispatcher = Dispatcher<Presence.Invocation, Presence.Event, Presence.Dependencies>

class EventEngineFactory {
  func subscribeEngine(
    with configuration: PubNubConfiguration,
    dispatcher: some SubscribeDispatcher,
    transition: some SubscribeTransitions
  ) -> SubscribeEngine {
    EventEngine(
      state: Subscribe.UnsubscribedState(),
      transition: transition,
      dispatcher: dispatcher,
      dependencies: EventEngineDependencies(value: Subscribe.Dependencies(configuration: configuration))
    )
  }
  
  func presenceEngine(
    with configuration: PubNubConfiguration,
    dispatcher: some PresenceDispatcher,
    transition: some PresenceTransitions
  ) -> PresenceEngine {
    EventEngine(
      state: Presence.HeartbeatInactive(),
      transition: transition,
      dispatcher: dispatcher,
      dependencies: EventEngineDependencies(value: Presence.Dependencies(configuration: configuration))
    )
  }
}
