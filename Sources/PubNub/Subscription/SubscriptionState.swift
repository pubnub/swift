//
//  SubscriptionState.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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

public extension Dictionary where Key == String, Value == PubNubChannel {
  /// Inserts the provided channel if that channel doesn't already exist
  mutating func insert(_ channel: Value) -> Bool {
    if let match = self[channel.id], match == channel {
      return false
    }

    self[channel.id] = channel
    return true
  }

  /// Updates the subscribedPresence state on the channel matching the provided name
  mutating func unsubscribePresence(_ id: String) -> Value? {
    if var match = self[id], match.isPresenceSubscribed {
      match.isPresenceSubscribed = false
      self[match.id] = match
      return match
    }
    return nil
  }
}
