//
//  PresenceInput.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
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
  
  static func +(lhs: PresenceInput, rhs: PresenceInput) -> PresenceInput {
    PresenceInput(
      channels: lhs.channelsSet.union(rhs.channelsSet),
      groups: lhs.groupsSet.union(rhs.groupsSet)
    )
  }
  
  static func -(lhs: PresenceInput, rhs: PresenceInput) -> PresenceInput {
    PresenceInput(
      channels: lhs.channelsSet.subtracting(rhs.channelsSet),
      groups: lhs.groupsSet.subtracting(rhs.groupsSet)
    )
  }
  
  static func ==(lhs: PresenceInput, rhs: PresenceInput) -> Bool {
    let equalChannels = lhs.channels.sorted(by: <) == rhs.channels.sorted(by: <)
    let equalGroups = lhs.groups.sorted(by: <) == rhs.groups.sorted(by: <)
    
    return equalChannels && equalGroups
  }
}
