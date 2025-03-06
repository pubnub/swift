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

protocol PresenceState: Equatable, CustomStringConvertible {
  var input: PresenceInput { get }
}

extension PresenceState {
  var channels: [String] {
    input.channels
  }

  var groups: [String] {
    input.groups
  }

  var description: String {
    String.formattedDescription(self, arguments: [("input", input)])
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
}

extension Presence {
  struct HeartbeatCooldown: PresenceState {
    let input: PresenceInput
  }
}

extension Presence {
  struct HeartbeatFailed: PresenceState {
    let input: PresenceInput
    let error: PubNubError
  }
}

extension Presence.HeartbeatFailed {
  var description: String {
    String.formattedDescription(self, arguments: [("input", input), ("error", error.reason)])
  }
}

extension Presence {
  struct HeartbeatStopped: PresenceState {
    let input: PresenceInput
  }
}

extension Presence {
  struct HeartbeatInactive: PresenceState {
    let input: PresenceInput = .init()
  }
}

extension Presence.HeartbeatInactive {
  var description: String {
    String.formattedDescription(self)
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
  }
}

extension Presence {
  struct Dependencies {
    let configuration: PubNubConfiguration
  }
}

// MARK: - Presence Effect Invocations

extension Presence {
  enum Invocation: AnyEffectInvocation, CustomStringConvertible {
    case heartbeat(channels: [String], groups: [String])
    case leave(channels: [String], groups: [String])
    case wait

    // swiftlint:disable:next nesting
    enum Cancellable: AnyCancellableInvocation, CustomStringConvertible {
      case wait

      var id: String {
        switch self {
        case .wait:
          return "Presence.ScheduleNextHeartbeat"
        }
      }
      var description: String {
        switch self {
        case .wait:
          return "Presence.Invocation.Cancellable.Wait"
        }
      }
    }

    var id: String {
      switch self {
      case .heartbeat:
        return "Presence.Heartbeat"
      case .wait:
        return Cancellable.wait.id
      case .leave:
        return "Presence.Leave"
      }
    }

    var description: String {
      switch self {
      case let .heartbeat(channels, groups):
        return String.formattedDescription(
          "Presence.Invocation.Heartbeat",
          arguments: [("channels", channels), ("groups", groups)]
        )
      case let .leave(channels, groups):
        return String.formattedDescription(
          "Presence.Invocation.Leave",
          arguments: [("channels", channels), ("groups", groups)]
        )
      case .wait:
        return "Presence.Invocation.Wait"
      }
    }
  }
}
