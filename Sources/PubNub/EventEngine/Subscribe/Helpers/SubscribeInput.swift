//
//  SubscribeInput.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A container for the current subscribed channels and channel groups
struct SubscribeInput: Equatable {
  private let subscribedChannels: Set<String>
  private let subscribedChannelGroups: Set<String>

  /// Result of comparing two SubscribeInput instances
  struct Difference {
    /// Items that were added (present in new but not in old)
    let addedChannels: Set<String>
    /// Channels that were removed (present in old but not in new)
    let removedChannels: Set<String>
    /// Channel groups that were added (present in new but not in old)
    let addedChannelGroups: Set<String>
    /// Channel groups that were removed (present in old but not in new)
    let removedChannelGroups: Set<String>
  }

  init(channels: Set<String> = [], channelGroups: Set<String> = []) {
    self.subscribedChannels = channels
    self.subscribedChannelGroups = channelGroups
  }

  init(channels: [String] = [], channelGroups: [String] = []) {
    self.subscribedChannels = Set(channels)
    self.subscribedChannelGroups = Set(channelGroups)
  }

  /// Whether the subscribe input is empty
  ///
  /// This is true if there are no subscribed channels or channel groups
  var isEmpty: Bool {
    subscribedChannels.isEmpty && subscribedChannelGroups.isEmpty
  }

  /// Names of all subscribed channels
  ///
  /// This list includes both regular and presence channel names
  var allSubscribedChannelNames: [String] {
    subscribedChannels.allObjects
  }

  /// Names of all subscribed main channels
  ///
  /// This list does not include presence channel names
  var mainChannelNames: [String] {
    subscribedChannels.filter { !$0.isPresenceChannelName }
  }

  /// Names of all subscribed main channel groups
  ///
  /// This list does not include presence channel group names
  var mainChannelGroupNames: [String] {
    subscribedChannelGroups.filter { !$0.isPresenceChannelName }
  }

  /// Names of all subscribed channel groups
  ///
  /// This list includes both regular and presence channel group names
  var allSubscribedChannelGroupNames: [String] {
    subscribedChannelGroups.allObjects
  }

  /// Total number of subscribed channels and channel groups
  var totalSubscribedCount: Int {
    subscribedChannels.count + subscribedChannelGroups.count
  }

  /// Adds the given channels and channel groups and returns a new input without modifying the current one
  func adding(channels: Set<String>, and channelGroups: Set<String>) -> SubscribeInput {
    SubscribeInput(
      channels: channels.union(subscribedChannels),
      channelGroups: channelGroups.union(subscribedChannelGroups)
    )
  }

  /// Removes the given channels and channel groups and returns a new input without modifying the current one
  func removing(channels: Set<String>, and channelGroups: Set<String>) -> SubscribeInput {
    SubscribeInput(
      channels: subscribedChannels.subtracting(channels),
      channelGroups: subscribedChannelGroups.subtracting(channelGroups)
    )
  }

  /// Compares this input with another and returns the differences
  func difference(from other: SubscribeInput) -> Difference {
    let addedChannels = subscribedChannels.subtracting(other.subscribedChannels)
    let removedChannels = other.subscribedChannels.subtracting(subscribedChannels)

    let addedGroups = subscribedChannelGroups.subtracting(other.subscribedChannelGroups)
    let removedGroups = other.subscribedChannelGroups.subtracting(subscribedChannelGroups)

    return Difference(
      addedChannels: addedChannels,
      removedChannels: removedChannels,
      addedChannelGroups: addedGroups,
      removedChannelGroups: removedGroups
    )
  }

  static func == (lhs: SubscribeInput, rhs: SubscribeInput) -> Bool {
    lhs.subscribedChannels == rhs.subscribedChannels && lhs.subscribedChannelGroups == rhs.subscribedChannelGroups
  }
}

extension SubscribeInput: CustomStringConvertible {
  var description: String {
    String.formattedDescription(
      self,
      arguments: [
        ("channels", allSubscribedChannelNames),
        ("groups", allSubscribedChannelGroupNames)
      ]
    )
  }
}
