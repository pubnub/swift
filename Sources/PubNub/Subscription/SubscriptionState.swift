//
//  SubscriptionState.swift
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

public struct SubscriptionState {
  public var connectionState: ConnectionStatus = .disconnected
  public var channels: [String: PubNubChannel] = [:]
  public var groups: [String: PubNubChannel] = [:]

  public var subscribedChannels: [String] {
    return channels.map { $0.key }
  }

  public var subscribedGroups: [String] {
    return groups.map { $0.key }
  }

  var allSubscribedChannels: [String] {
    var subscribed = [String]()

    channels.forEach { _, channel in
      subscribed.append(channel.id)
      if channel.isPresenceSubscribed {
        subscribed.append(channel.presenceId)
      }
    }

    return subscribed
  }

  var allSubscribedGroups: [String] {
    var subscribed = [String]()

    groups.forEach { _, group in
      subscribed.append(group.id)
      if group.isPresenceSubscribed {
        subscribed.append(group.presenceId)
      }
    }

    return subscribed
  }

  public var totalSubscribedCount: Int {
    return channels.count + groups.count
  }

  public var subscribedState: [String: [String: JSONCodable]] {
    var state = [String: [String: JSONCodable]]()

    channels.forEach { _, channel in
      if let channelState = channel.state {
        state[channel.id] = channelState
      }
    }

    groups.forEach { _, group in
      if let channelState = group.state {
        state[group.id] = channelState
      }
    }

    return state
  }

  public mutating func findAndUpdate(_ id: String, state: [String: JSONCodable]) {
    if var channelMatch = channels[id] {
      channelMatch.state = state
      channels[channelMatch.id] = channelMatch
    } else if var groupMatch = groups[id] {
      groupMatch.state = state
      groups[groupMatch.id] = groupMatch
    } else {
      PubNub.log.debug("Attempted to updated state of an unsubscribed channel/group \(id)")
    }
  }
}

// MARK: - Dependent Models

public struct PubNubChannel {
  public let id: String
  public let presenceId: String
  public var state: [String: JSONCodable]?

  public var isPresenceSubscribed: Bool

  public init(id: String, state: [String: JSONCodable]? = nil, withPresence: Bool = false) {
    self.id = id
    presenceId = id.presenceChannelName
    self.state = state
    isPresenceSubscribed = withPresence
  }
}

extension PubNubChannel: Codable {
  enum CodingKeys: String, CodingKey {
    case id
    case presenceId
    case state
    case isPresenceSubscribed
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(String.self, forKey: .id)
    presenceId = try container.decode(String.self, forKey: .presenceId)
    state = try container.decodeIfPresent([String: AnyJSON].self, forKey: .state)
    isPresenceSubscribed = try container.decode(Bool.self, forKey: .isPresenceSubscribed)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encode(presenceId, forKey: .presenceId)
    try container.encode(state?.mapValues { $0.codableValue }, forKey: .state)
    try container.encode(isPresenceSubscribed, forKey: .isPresenceSubscribed)
  }
}

extension PubNubChannel: Hashable {
  public static func == (lhs: PubNubChannel, rhs: PubNubChannel) -> Bool {
    return lhs.id == rhs.id &&
      lhs.presenceId == rhs.presenceId &&
      lhs.state?.mapValues { $0.codableValue } == rhs.state?.mapValues { $0.codableValue } &&
      lhs.isPresenceSubscribed == rhs.isPresenceSubscribed
  }

  public func hash(into hasher: inout Hasher) {
    id.hash(into: &hasher)
    presenceId.hash(into: &hasher)
    state?.mapValues { $0.codableValue }.hash(into: &hasher)
    isPresenceSubscribed.hash(into: &hasher)
  }
}

extension Dictionary where Key == String, Value == PubNubChannel {
  public mutating func insert(_ channel: Value) -> Bool {
    if let match = self[channel.id], match == channel {
      return false
    }

    self[channel.id] = channel
    return true
  }

  public mutating func unsubscribePresence(_ id: String) -> Value? {
    if var match = self[id], match.isPresenceSubscribed {
      match.isPresenceSubscribed = false
      self[match.id] = match
      return match
    }
    return nil
  }
}
