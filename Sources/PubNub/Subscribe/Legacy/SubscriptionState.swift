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
