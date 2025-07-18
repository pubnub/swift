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
  public let isPresenceSubscribed: Bool

  init(id: String, withPresence: Bool = false) {
    self.id = id
    presenceId = id.presenceChannelName
    isPresenceSubscribed = withPresence
  }

  init(channel: String) {
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

extension Array where Element == PubNubChannel {
  /// Returns consolidated channels that merge duplicate channels with their presence counterparts
  ///
  /// This method groups PubNubChannel instances by their main channel ID, detecting duplicates
  /// representing the same logical channel with different presence settings and merging them
  /// into single consolidated instances.
  func consolidated() -> [PubNubChannel] {
    let consolidatedMap = self.reduce(into: [String: Bool]()) { result, channel in
      /// Check if we've already processed this channel ID and if any previous instance had presence enabled
      result[channel.id] = (result[channel.id] ?? false) || channel.isPresenceSubscribed
    }
    return consolidatedMap.map { channelId, hasPresence in
      PubNubChannel(id: channelId, withPresence: hasPresence)
    }.sorted { $0.id < $1.id }
  }
}

extension Dictionary where Key == String, Value == PubNubChannel {
  // Inserts and returns the provided channel if that channel doesn't already exist
  mutating func insert(_ channel: Value) -> Bool {
    if let match = self[channel.id], match == channel {
      return false
    }
    self[channel.id] = channel
    return true
  }

  // Updates current Dictionary with the new channel value unsubscribed from Presence.
  // Returns the updated value if the corresponding entry matching the passed `id:` was found, otherwise `nil`
  @discardableResult mutating func unsubscribePresence(_ id: String) -> Value? {
    if let match = self[id], match.isPresenceSubscribed {
      let updatedChannel = PubNubChannel(id: match.id, withPresence: false)
      self[match.id] = updatedChannel
      return updatedChannel
    }
    return nil
  }
}
