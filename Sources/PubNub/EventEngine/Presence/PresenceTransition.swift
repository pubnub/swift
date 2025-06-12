//
//  PresenceTransition.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class PresenceTransition: TransitionProtocol {
  typealias State = (any PresenceState)
  typealias Event = Presence.Event
  typealias Invocation = Presence.Invocation

  private let configuration: PubNubConfiguration

  init(configuration: PubNubConfiguration) {
    self.configuration = configuration
  }

  func canTransition(from state: State, dueTo event: Event) -> Bool {
    switch event {
    case .joined:
      return true
    case .left:
      return true
    case .heartbeatSuccess:
      return state is Presence.Heartbeating
    case .heartbeatFailed:
      return state is Presence.Heartbeating
    case .timesUp:
      return state is Presence.HeartbeatCooldown
    case .leftAll:
      return true
    case .disconnect:
      return !(state is Presence.HeartbeatInactive)
    case .reconnect:
      return state is Presence.HeartbeatStopped || state is Presence.HeartbeatFailed
    }
  }

  private func onEntry(to state: State) -> [EffectInvocation<Invocation>] {
    switch state {
    case is Presence.Heartbeating:
      return [.regular(.heartbeat(
        channels: state.channels,
        groups: state.input.groups
      ))]
    case is Presence.HeartbeatCooldown:
      return [.managed(.wait)]
    default:
      return []
    }
  }

  private func onExit(from state: State) -> [EffectInvocation<Invocation>] {
    switch state {
    case is Presence.HeartbeatCooldown:
      return [.cancel(.wait)]
    default:
      return []
    }
  }

  func transition(from state: State, event: Event) -> TransitionResult<State, Invocation> {
    var results: TransitionResult<State, Invocation>

    switch event {
    case let .joined(channels, groups):
      results = heartbeatingTransition(from: state, joining: (channels: channels, groups: groups))
    case let .left(channels, groups):
      results = heartbeatingTransition(from: state, leaving: (channels: channels, groups: groups))
    case .heartbeatSuccess:
      results = heartbeatSuccessTransition(from: state)
    case let .heartbeatFailed(error):
      results = heartbeatFailedTransition(from: state, dueTo: error)
    case .timesUp:
      results = heartbeatingTransition(from: state)
    case .leftAll:
      results = heartbeatInactiveTransition(from: state)
    case .reconnect:
      results = heartbeatingTransition(from: state)
    case .disconnect:
      results = heartbeatStoppedTransition(from: state)
    }

    return TransitionResult(
      state: results.state,
      invocations: onExit(from: state) + results.invocations + onEntry(to: results.state)
    )
  }
}

fileprivate extension PresenceTransition {
  func heartbeatingTransition(
    from state: State,
    joining: (channels: [String], groups: [String])
  ) -> TransitionResult<State, Invocation> {
    let newInput = state.input + PresenceInput(
      channels: joining.channels,
      groups: joining.groups
    )
    if state is Presence.HeartbeatStopped {
      return TransitionResult(state: Presence.HeartbeatStopped(input: newInput))
    } else {
      return TransitionResult(state: Presence.Heartbeating(input: newInput))
    }
  }
}

fileprivate extension PresenceTransition {
  func heartbeatingTransition(
    from state: State,
    leaving: (channels: [String], groups: [String])
  ) -> TransitionResult<State, Invocation> {
    let newInput = state.input - PresenceInput(
      channels: leaving.channels,
      groups: leaving.groups
    )
    let invocations = configuration.supressLeaveEvents ? [] : [
      EffectInvocation.regular(Presence.Invocation.leave(
        channels: leaving.channels,
        groups: leaving.groups
      ))
    ]

    if state is Presence.HeartbeatStopped {
      return TransitionResult(
        state: Presence.HeartbeatStopped(input: newInput),
        invocations: invocations
      )
    } else {
      return TransitionResult(
        state: newInput.isEmpty ? Presence.HeartbeatInactive() : Presence.Heartbeating(input: newInput),
        invocations: invocations
      )
    }
  }
}

fileprivate extension PresenceTransition {
  func heartbeatSuccessTransition(from state: State) -> TransitionResult<State, Invocation> {
    if configuration.heartbeatInterval > 0 {
      return TransitionResult(state: Presence.HeartbeatCooldown(input: state.input))
    } else {
      return TransitionResult(state: Presence.HeartbeatInactive())
    }
  }
}

fileprivate extension PresenceTransition {
  func heartbeatFailedTransition(
    from state: State,
    dueTo error: PubNubError
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Presence.HeartbeatFailed(
        input: state.input,
        error: error
      )
    )
  }
}

fileprivate extension PresenceTransition {
  func heartbeatingTransition(from state: State) -> TransitionResult<State, Invocation> {
    return TransitionResult(state: Presence.Heartbeating(input: state.input))
  }
}

fileprivate extension PresenceTransition {
  func heartbeatStoppedTransition(from state: State) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Presence.HeartbeatStopped(input: state.input),
      invocations: [.regular(.leave(channels: state.input.channels, groups: state.input.groups))]
    )
  }
}

fileprivate extension PresenceTransition {
  func heartbeatInactiveTransition(from state: State) -> TransitionResult<State, Invocation> {
    let leaveInvocation = EffectInvocation.regular(Presence.Invocation.leave(
      channels: state.input.channels,
      groups: state.input.groups
    ))
    return TransitionResult(
      state: Presence.HeartbeatInactive(),
      invocations: configuration.supressLeaveEvents ? []: [leaveInvocation]
    )
  }
}
