//
//  PresenceEvent.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

public enum PresenceStateEvent: String, Codable, Hashable {
  case join
  case leave
  case timeout
  case stateChange = "state-change"
  case interval
}

public protocol PresenceEvent {
  // Common for all subscription responses
  /// The channel for which the message belongs
  var channel: String { get }
  /// The channel group or wildcard subscription match (if exists).
  var subscriptionMatch: String? { get }
  /// Timetoken for the message
  var senderTimetoken: Timetoken { get }
  /// Timetoken for the presence event
  var presenceTimetoken: Timetoken { get }
  /// User metadata
  var metadata: AnyJSON? { get }

  // Specific for presence responses
  /// The type of event
  var event: PresenceStateEvent { get }
  /// Current occupancy.
  var occupancy: Int { get }
  /// List of UUIDs that joined the channel
  var join: [String] { get }
  /// List of UUIDs that left the channel
  var leave: [String] { get }
  /// List of UUIDs that timed out of the channel
  var timeout: [String] { get }
  /// User UUIDs and their new Presence States
  var stateChange: [String: [String: Codable]] { get }
}

extension MessageResponse: PresenceEvent where Payload == PresenceResponse {
  public var senderTimetoken: Timetoken {
    return originTimetoken?.timetoken ?? payload.timetoken
  }

  public var presenceTimetoken: Timetoken {
    return publishTimetoken.timetoken
  }

  public var event: PresenceStateEvent {
    return payload.action
  }

  public var occupancy: Int {
    return payload.occupancy
  }

  public var join: [String] {
    return payload.join
  }

  public var leave: [String] {
    return payload.leave
  }

  public var timeout: [String] {
    return payload.timeout
  }

  public var stateChange: [String: [String: Codable]] {
    return payload.channelState
  }
}
