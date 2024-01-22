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

struct SubscribeInput: Equatable {
  private let channelEntries: [String: PubNubChannel]
  private let groupEntries: [String: PubNubChannel]
  
  init(channels: [PubNubChannel] = [], groups: [PubNubChannel] = []) {
    self.channelEntries = channels.reduce(into: [String: PubNubChannel]()) { r, channel in _ = r.insert(channel) }
    self.groupEntries = groups.reduce(into: [String: PubNubChannel]()) { r, channel in _ = r.insert(channel) }
  }
  
  private init(channels: [String: PubNubChannel], groups: [String: PubNubChannel]) {
    self.channelEntries = channels
    self.groupEntries = groups
  }
  
  var isEmpty: Bool {
    channelEntries.isEmpty && groupEntries.isEmpty
  }
  
  var channels: [PubNubChannel] {
    Array(channelEntries.values)
  }
  
  var groups: [PubNubChannel] {
    Array(groupEntries.values)
  }
  
  var subscribedChannelNames: [String] {
    channelEntries.map { $0.key }
  }
  
  var subscribedGroupNames: [String] {
    groupEntries.map { $0.key }
  }
  
  var allSubscribedChannelNames: [String] {
    channelEntries.reduce(into: [String]()) { result, entry in
      result.append(entry.value.id)
      if entry.value.isPresenceSubscribed {
        result.append(entry.value.presenceId)
      }
    }
  }
  
  var allSubscribedGroupNames: [String] {
    groupEntries.reduce(into: [String]()) { result, entry in
      result.append(entry.value.id)
      if entry.value.isPresenceSubscribed {
        result.append(entry.value.presenceId)
      }
    }
  }
  
  var presenceSubscribedChannelNames: [String] {
    channelEntries.compactMap {
      if $0.value.isPresenceSubscribed {
        return $0.value.id
      } else {
        return nil
      }
    }
  }
  
  var presenceSubscribedGroupNames: [String] {
    groupEntries.compactMap {
      if $0.value.isPresenceSubscribed {
        return $0.value.id
      } else {
        return nil
      }
    }
  }
  
  var totalSubscribedCount: Int {
    channelEntries.count + groupEntries.count
  }
    
  func adding(
    channels: [PubNubChannel],
    and groups: [PubNubChannel]
  ) -> (
    newInput: SubscribeInput,
    insertedChannels: [PubNubChannel],
    insertedGroups: [PubNubChannel]
  ) {
    var currentChannels = channelEntries
    var currentGroups = groupEntries
    
    let insertedChannels = channels.filter { currentChannels.insert($0) }
    let insertedGroups = groups.filter { currentGroups.insert($0) }
    
    return (
      newInput: SubscribeInput(channels: currentChannels, groups: currentGroups),
      insertedChannels: insertedChannels,
      insertedGroups: insertedGroups
    )
  }
  
  func removing(
    channels: [String],
    and groups: [String]
  ) -> (
    newInput: SubscribeInput,
    removedChannels: [PubNubChannel],
    removedGroups: [PubNubChannel]
  ) {
    var currentChannels = channelEntries
    var currentGroups = groupEntries
    
    let removedChannels = channels.compactMap {
      if $0.isPresenceChannelName {
        return currentChannels.unsubscribePresence($0.trimmingPresenceChannelSuffix)
      } else {
        return currentChannels.removeValue(forKey: $0)
      }
    }
    
    let removedGroups = groups.compactMap {
      if $0.isPresenceChannelName {
        return currentGroups.unsubscribePresence($0.trimmingPresenceChannelSuffix)
      } else {
        return currentGroups.removeValue(forKey: $0)
      }
    }
    
    return (
      newInput: SubscribeInput(channels: currentChannels, groups: currentGroups),
      removedChannels: removedChannels,
      removedGroups: removedGroups
    )
  }
  
  static func ==(lhs: SubscribeInput, rhs: SubscribeInput) -> Bool {
    let equalChannels = lhs.allSubscribedChannelNames.sorted(by: <) == rhs.allSubscribedChannelNames.sorted(by: <)
    let equalGroups = lhs.allSubscribedGroupNames.sorted(by: <) == rhs.allSubscribedGroupNames.sorted(by: <)
    
    return equalChannels && equalGroups
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
  
  func difference(_ dict: [Key:Value]) -> [Key: Value] {
    let entriesInSelfAndNotInDict = filter {
      dict[$0.0] != self[$0.0]
    }
    return entriesInSelfAndNotInDict.reduce([Key:Value]()) { (res, entry) -> [Key:Value] in
      var res = res
      res[entry.0] = entry.1
      return res
    }
  }
  
  func intersection(_ dict: [Key:Value]) -> [Key: Value] {
    let entriesInSelfAndInDict = filter {
      dict[$0.0] == self[$0.0]
    }
    return entriesInSelfAndInDict.reduce([Key:Value]()) { (res, entry) -> [Key:Value] in
      var res = res
      res[entry.0] = entry.1
      return res
    }
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
