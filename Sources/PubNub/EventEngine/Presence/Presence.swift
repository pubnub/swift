//
//  Presence.swift
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
    let currentAttempt: Int
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
    let input: PresenceInput = PresenceInput()
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
  struct EngineInput {
    let configuration: SubscriptionConfiguration
  }
}

// MARK: - Presence Effect Invocations

extension Presence {
  enum Invocation: AnyEffectInvocation {
    case heartbeat(channels: [String], groups: [String])
    case leave(channels: [String], groups: [String])
    case delayedHeartbeat(channels: [String], groups: [String], currentAttempt: Int, error: PubNubError)
    case wait
        
    enum Cancellable: AnyCancellableInvocation {
      case scheduleNextHeartbeat
      case delayedHeartbeat
      
      var id: String {
        switch self {
        case .scheduleNextHeartbeat:
          return "Presence.ScheduleNextHeartbeat"
        case .delayedHeartbeat:
          return "Presence.HeartbeatReconnect"
        }
      }
    }
    
    var id: String {
      switch self {
      case .heartbeat(_,_):
        return "Presence.Heartbeat"
      case .wait:
        return Cancellable.scheduleNextHeartbeat.id
      case .delayedHeartbeat:
        return Cancellable.delayedHeartbeat.id
      case .leave(_,_):
        return "Presence.Leave"
      }
    }
  }
}
