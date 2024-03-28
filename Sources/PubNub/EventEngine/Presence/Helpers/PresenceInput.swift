//
//  PresenceInput.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
import Foundation

struct PresenceInput: Equatable {
  fileprivate let channelsSet: Set<String>
  fileprivate let groupsSet: Set<String>

  init(channels: [String] = [], groups: [String] = []) {
    channelsSet = Set(channels)
    groupsSet = Set(groups)
  }

  fileprivate init(channels: Set<String>, groups: Set<String>) {
    channelsSet = channels
    groupsSet = groups
  }

  var channels: [String] {
    channelsSet.map { $0 }
  }

  var groups: [String] {
    groupsSet.map { $0 }
  }

  var isEmpty: Bool {
    channelsSet.isEmpty && groupsSet.isEmpty
  }

  static func + (lhs: PresenceInput, rhs: PresenceInput) -> PresenceInput {
    PresenceInput(
      channels: lhs.channelsSet.union(rhs.channelsSet),
      groups: lhs.groupsSet.union(rhs.groupsSet)
    )
  }

  static func - (lhs: PresenceInput, rhs: PresenceInput) -> PresenceInput {
    PresenceInput(
      channels: lhs.channelsSet.subtracting(rhs.channelsSet),
      groups: lhs.groupsSet.subtracting(rhs.groupsSet)
    )
  }

  static func == (lhs: PresenceInput, rhs: PresenceInput) -> Bool {
    let equalChannels = lhs.channels.sorted(by: <) == rhs.channels.sorted(by: <)
    let equalGroups = lhs.groups.sorted(by: <) == rhs.groups.sorted(by: <)

    return equalChannels && equalGroups
  }
}
