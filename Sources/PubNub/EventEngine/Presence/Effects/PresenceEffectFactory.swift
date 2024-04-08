//
//  PresenceEffectFactory.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class PresenceEffectFactory: EffectHandlerFactory {
  private let session: SessionReplaceable
  private let sessionResponseQueue: DispatchQueue
  private let presenceStateContainer: PubNubPresenceStateContainer

  init(
    session: SessionReplaceable,
    sessionResponseQueue: DispatchQueue = .main,
    presenceStateContainer: PubNubPresenceStateContainer
  ) {
    self.session = session
    self.sessionResponseQueue = sessionResponseQueue
    self.presenceStateContainer = presenceStateContainer
  }

  func effect(
    for invocation: Presence.Invocation,
    with dependencies: EventEngineDependencies<Presence.Dependencies>
  ) -> any EffectHandler<Presence.Event> {
    switch invocation {
    case let .heartbeat(channels, groups):
      return HeartbeatEffect(
        request: PresenceHeartbeatRequest(
          channels: channels,
          groups: groups,
          channelStates: presenceStateContainer.getStates(forChannels: channels),
          configuration: dependencies.value.configuration,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        )
      )
    case let .delayedHeartbeat(channels, groups, retryAttempt, reason):
      return DelayedHeartbeatEffect(
        request: PresenceHeartbeatRequest(
          channels: channels,
          groups: groups,
          channelStates: presenceStateContainer.getStates(forChannels: channels),
          configuration: dependencies.value.configuration,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        ),
        retryAttempt: retryAttempt,
        reason: reason
      )
    case let .leave(channels, groups):
      return LeaveEffect(
        request: PresenceLeaveRequest(
          channels: channels,
          groups: groups,
          configuration: dependencies.value.configuration,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        )
      )
    case .wait:
      return WaitEffect(configuration: dependencies.value.configuration)
    }
  }

  deinit {
    session.invalidateAndCancel()
  }
}
