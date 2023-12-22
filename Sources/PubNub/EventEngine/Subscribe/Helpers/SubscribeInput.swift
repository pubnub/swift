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
  private let channels: [String: PubNubChannel]
  private let groups: [String: PubNubChannel]
  
  init(channels: [PubNubChannel] = [], groups: [PubNubChannel] = []) {
    self.channels = channels.reduce(into: [String: PubNubChannel]()) { r, channel in _ = r.insert(channel) }
    self.groups = groups.reduce(into: [String: PubNubChannel]()) { r, channel in _ = r.insert(channel) }
  }
  
  private init(channels: [String: PubNubChannel], groups: [String: PubNubChannel]) {
    self.channels = channels
    self.groups = groups
  }
  
  var isEmpty: Bool {
    channels.isEmpty && groups.isEmpty
  }
  
  var subscribedChannels: [String] {
    channels.map { $0.key }
  }
  
  var subscribedGroups: [String] {
    groups.map { $0.key }
  }
  
  var allSubscribedChannels: [String] {
    channels.reduce(into: [String]()) { result, entry in
      result.append(entry.value.id)
      if entry.value.isPresenceSubscribed {
        result.append(entry.value.presenceId)
      }
    }
  }
  
  var allSubscribedGroups: [String] {
    groups.reduce(into: [String]()) { result, entry in
      result.append(entry.value.id)
      if entry.value.isPresenceSubscribed {
        result.append(entry.value.presenceId)
      }
    }
  }
  
  var presenceSubscribedChannels: [String] {
    channels.compactMap {
      if $0.value.isPresenceSubscribed {
        return $0.value.id
      } else {
        return nil
      }
    }
  }
  
  var presenceSubscribedGroups: [String] {
    groups.compactMap {
      if $0.value.isPresenceSubscribed {
        return $0.value.id
      } else {
        return nil
      }
    }
  }
  
  var totalSubscribedCount: Int {
    channels.count + groups.count
  }
  
  static func +(lhs: SubscribeInput, rhs: SubscribeInput) -> SubscribeInput {
    var currentChannels = lhs.channels
    var currentGroups = rhs.groups
    
    rhs.channels.values.forEach { _ = currentChannels.insert($0) }
    lhs.groups.values.forEach { _ = currentGroups.insert($0) }
    
    return SubscribeInput(
      channels: currentChannels,
      groups: currentGroups
    )
  }
  
  static func -(lhs: SubscribeInput, rhs: (channels: [String], groups: [String])) -> SubscribeInput {
    var currentChannels = lhs.channels
    var currentGroups = lhs.groups
    
    rhs.channels.forEach {
      if $0.isPresenceChannelName {
        currentChannels.unsubscribePresence($0.trimmingPresenceChannelSuffix)
      } else {
        currentChannels.removeValue(forKey: $0)
      }
    }
    rhs.groups.forEach {
      if $0.isPresenceChannelName {
        currentGroups.unsubscribePresence($0.trimmingPresenceChannelSuffix)
      } else {
        currentGroups.removeValue(forKey: $0)
      }
    }
    return SubscribeInput(
      channels: currentChannels,
      groups: currentGroups
    )
  }
  
  static func ==(lhs: SubscribeInput, rhs: SubscribeInput) -> Bool {
    let equalChannels = lhs.allSubscribedChannels.sorted(by: <) == rhs.allSubscribedChannels.sorted(by: <)
    let equalGroups = lhs.allSubscribedGroups.sorted(by: <) == rhs.allSubscribedGroups.sorted(by: <)
    
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
