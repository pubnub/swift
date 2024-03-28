//
//  Presence.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - PresenceState

protocol PresenceState: Equatable {
  var input: PresenceInput { get }
}

extension PresenceState {
  var channels: [String] {
    input.channels
  }

  var groups: [String] {
    input.groups
  }
}

//
// A namespace for Events, concrete State types and Invocations used in Presence EE
//
enum Presence {}

// MARK: - Presence States

extension Presence {
  struct Heartbeating: PresenceState {
    let input: PresenceInput
  }

  struct HeartbeatCooldown: PresenceState {
    let input: PresenceInput
  }

  struct HeartbeatReconnecting: PresenceState {
    let input: PresenceInput
    let retryAttempt: Int
    let error: PubNubError
  }

  struct HeartbeatFailed: PresenceState {
    let input: PresenceInput
    let error: PubNubError
  }

  struct HeartbeatStopped: PresenceState {
    let input: PresenceInput
  }

  struct HeartbeatInactive: PresenceState {
    let input: PresenceInput = .init()
  }
}

// MARK: - Presence Events

extension Presence {
  enum Event {
    case joined(channels: [String], groups: [String])
    case left(channels: [String], groups: [String])
    case leftAll
    case reconnect
    case disconnect
    case timesUp
    case heartbeatSuccess
    case heartbeatFailed(error: PubNubError)
    case heartbeatGiveUp(error: PubNubError)
  }
}

extension Presence {
  struct Dependencies {
    let configuration: PubNubConfiguration
  }
}

// MARK: - Presence Effect Invocations

extension Presence {
  enum Invocation: AnyEffectInvocation {
    case heartbeat(channels: [String], groups: [String])
    case leave(channels: [String], groups: [String])
    case delayedHeartbeat(channels: [String], groups: [String], retryAttempt: Int, error: PubNubError)
    case wait

    // swiftlint:disable:next nesting
    enum Cancellable: AnyCancellableInvocation {
      case wait
      case delayedHeartbeat

      var id: String {
        switch self {
        case .wait:
          return "Presence.ScheduleNextHeartbeat"
        case .delayedHeartbeat:
          return "Presence.HeartbeatReconnect"
        }
      }
    }

    var id: String {
      switch self {
      case .heartbeat:
        return "Presence.Heartbeat"
      case .wait:
        return Cancellable.wait.id
      case .delayedHeartbeat:
        return Cancellable.delayedHeartbeat.id
      case .leave:
        return "Presence.Leave"
      }
    }
  }
}
