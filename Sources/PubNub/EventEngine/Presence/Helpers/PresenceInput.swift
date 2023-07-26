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
  
  var channels: [String] {
    channelsSet.allObjects.sorted(by: <)
  }
  
  var groups: [String] {
    groupsSet.allObjects.sorted(by: <)
  }
  
  var isEmpty: Bool {
    channelsSet.isEmpty && groupsSet.isEmpty
  }
  
  init(channels: [String] = [], groups: [String] = []) {
    channelsSet = Set(channels)
    groupsSet = Set(groups)
  }
  
  fileprivate init(channels: Set<String>, groups: Set<String>) {
    channelsSet = channels
    groupsSet = groups
  }
  
  static func +(lhs: PresenceInput, rhs: PresenceInput) -> PresenceInput {
    var uniqueChannels = lhs.channelsSet
    var uniqueGroups = lhs.groupsSet
    
    rhs.channelsSet.forEach { uniqueChannels.insert($0) }
    rhs.groupsSet.forEach { uniqueGroups.insert($0) }
    
    return PresenceInput(channels: uniqueChannels, groups: uniqueGroups)
  }
  
  static func -(lhs: PresenceInput, rhs: PresenceInput) -> PresenceInput {
    var uniqueChannels = lhs.channelsSet
    var uniqueGroups = lhs.groupsSet
    
    rhs.channelsSet.forEach { uniqueChannels.remove($0) }
    rhs.groupsSet.forEach { uniqueGroups.remove($0) }
    
    return PresenceInput(channels: uniqueChannels, groups: uniqueGroups)
  }
  
  static func ==(lhs: PresenceInput, rhs: PresenceInput) -> Bool {
    lhs.channels == rhs.channels && lhs.groups == rhs.groups
  }
}
