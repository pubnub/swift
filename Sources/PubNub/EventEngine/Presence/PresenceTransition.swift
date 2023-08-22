//
//  PresenceTransition.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

class PresenceTransition: TransitionProtocol {
  typealias State = (any PresenceState)
  typealias Event = Presence.Event
  typealias Invocation = Presence.Invocation
  
  func canTransition(from state: State, dueTo event: Event) -> Bool {
    switch event {
    case .joined(_,_):
      return true
    case .left(_,_):
      return !(state is Presence.HeartbeatInactive)
    case .heartbeatSuccess:
      return state is Presence.Heartbeating
    case .heartbeatFailed(_):
      return state is Presence.Heartbeating || state is Presence.HeartbeatReconnecting
    case .heartbeatGiveUp(_):
      return state is Presence.HeartbeatReconnecting
    case .timesUp:
      return state is Presence.HeartbeatCooldown
    case .leftAll:
      return !(state is Presence.HeartbeatInactive)
    case .disconnect:
      return true
    case .reconnect:
      return state is Presence.HeartbeatStopped || state is Presence.HeartbeatFailed
    }
  }
  
  private func onEntry(to state: State) -> [EffectInvocation<Invocation>] {
    switch state {
    case is Presence.Heartbeating:
      return [.regular(.heartbeat(channels: state.channels, groups: state.input.groups))]
    case is Presence.HeartbeatCooldown:
      return [.managed(.wait)]
    case let state as Presence.HeartbeatReconnecting:
      return [.managed(.delayedHeartbeat(channels: state.channels, groups: state.groups, retryAttempt: state.retryAttempt, error: state.error))]
    default:
      return []
    }
  }
  
  private func onExit(from state: State) -> [EffectInvocation<Invocation>] {
    switch state {
    case is Presence.HeartbeatCooldown:
      return [.cancel(.scheduleNextHeartbeat)]
    case is Presence.HeartbeatReconnecting:
      return [.cancel(.delayedHeartbeat)]
    default:
      return []
    }
  }
  
  func transition(from state: State, event: Event) -> TransitionResult<State, Invocation> {
    var results: TransitionResult<State, Invocation>
    
    switch event {
    case .joined(let channels, let groups):
      results = heartbeatingTransition(from: state, joined: channels, and: groups)
    case .left(let channels, let groups):
      results = heartbeatingTransition(from: state, left: channels, and: groups)
    case .heartbeatSuccess:
      results = heartbeatSuccessTransition(from: state)
    case .heartbeatFailed(let error):
      results = heartbeatReconnectingTransition(from: state, dueTo: error)
    case .heartbeatGiveUp(let error):
      results = heartbeatReconnectingGiveUpTransition(from: state, dueTo: error)
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
    joined channels: [String],
    and groups: [String]
  ) -> TransitionResult<State, Invocation> {
    let newInput = state.input + PresenceInput(
      channels: channels,
      groups: groups
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
    left channels: [String],
    and groups: [String]
  ) -> TransitionResult<State, Invocation> {
    let newInput = state.input - PresenceInput(
      channels: channels,
      groups: groups
    )
    if state is Presence.HeartbeatStopped {
      return TransitionResult(
        state: Presence.HeartbeatStopped(input: newInput),
        invocations: []
      )
    } else if newInput.isEmpty {
      return TransitionResult(
        state: Presence.HeartbeatInactive(),
        invocations: [.regular(.leave(channels: channels, groups: groups))]
      )
    } else {
      return TransitionResult(
        state: Presence.Heartbeating(input: newInput),
        invocations: [.regular(.leave(channels: channels, groups: groups))]
      )
    }
  }
}

fileprivate extension PresenceTransition {
  func heartbeatSuccessTransition(from state: State) -> TransitionResult<State, Invocation> {
    return TransitionResult(state: Presence.HeartbeatCooldown(input: state.input))
  }
}

fileprivate extension PresenceTransition {
  func heartbeatReconnectingTransition(
    from state: State,
    dueTo error: PubNubError
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Presence.HeartbeatReconnecting(
        input: state.input,
        retryAttempt: ((state as? Presence.HeartbeatReconnecting)?.retryAttempt ?? -1) + 1,
        error: error
      )
    )
  }
}

fileprivate extension PresenceTransition {
  func heartbeatReconnectingGiveUpTransition(
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
    return TransitionResult(
      state: Presence.HeartbeatInactive(),
      invocations: [.regular(.leave(channels: state.input.channels, groups: state.input.groups))]
    )
  }
}
