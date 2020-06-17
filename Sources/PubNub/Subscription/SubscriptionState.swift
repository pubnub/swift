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

/// State of a PubNub subscription lifecycle
public struct SubscriptionState {
  /// Connection status
  public var connectionState: ConnectionStatus = .disconnected
  /// Dictionary that maps channel name to the Channel object
  public var channels: [String: PubNubChannel] = [:]
  /// Dictionary that maps group name to the group Channel object
  public var groups: [String: PubNubChannel] = [:]
  /// List of actively subscribed channels
  public var subscribedChannels: [String] {
    return channels.map { $0.key }
  }

  /// List of actively subscribed groups
  public var subscribedGroups: [String] {
    return groups.map { $0.key }
  }

  /// Names of all subscribed channels
  ///
  /// This list includes both regular and presence channel names
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

  /// Names of all subscribed groups
  ///
  /// This list includes both regular and presence groups names
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

  /// Combined value of all subscribed channels and groups
  public var totalSubscribedCount: Int {
    return channels.count + groups.count
  }
}

// MARK: - Dependent Models

/// A PubNub channel or channel group
public struct PubNubChannel: Hashable {
  /// The channel name as a String
  public let id: String
  /// The presence channel name
  public let presenceId: String
  /// If the channel is currently subscribed with presence
  public var isPresenceSubscribed: Bool

  public init(id: String, withPresence: Bool = false) {
    self.id = id
    presenceId = id.presenceChannelName
    isPresenceSubscribed = withPresence
  }

  /// Detects if the string is a Presence channel name and sets the appropriate values
  public init(channel: String) {
    if channel.isPresenceChannelName {
      id = channel.trimmingPresenceChannelSuffix
      presenceId = channel
      isPresenceSubscribed = true
    } else {
      id = channel
      presenceId = channel.presenceChannelName
      isPresenceSubscribed = false
    }
  }
}

extension PubNubChannel: Codable {
  enum CodingKeys: String, CodingKey {
    case id
    case presenceId
    case isPresenceSubscribed
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(String.self, forKey: .id)
    presenceId = try container.decode(String.self, forKey: .presenceId)
    isPresenceSubscribed = try container.decode(Bool.self, forKey: .isPresenceSubscribed)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encode(presenceId, forKey: .presenceId)
    try container.encode(isPresenceSubscribed, forKey: .isPresenceSubscribed)
  }
}

extension Dictionary where Key == String, Value == PubNubChannel {
  /// Inserts the provided channel if that channel doesn't already exist
  public mutating func insert(_ channel: Value) -> Bool {
    if let match = self[channel.id], match == channel {
      return false
    }

    self[channel.id] = channel
    return true
  }

  /// Updates the subscribedPresence state on the channel matching the provided name
  public mutating func unsubscribePresence(_ id: String) -> Value? {
    if var match = self[id], match.isPresenceSubscribed {
      match.isPresenceSubscribed = false
      self[match.id] = match
      return match
    }
    return nil
  }
}
