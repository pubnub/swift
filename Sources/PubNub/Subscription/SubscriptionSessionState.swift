//
//  SubscriptionSessionState.swift
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

struct SubscriptionSessionState {
  var state: ConnectionStatus = .initialized

  var channels: Set<String> = []
  var channelGroups: Set<String> = []

  var nonPresenceChannels: Set<String> {
    return channels.filter { !$0.isPresenceChannelName }
  }

  var nonPresenceChannelGroups: Set<String> {
    return channelGroups.filter { !$0.isPresenceChannelName }
  }

  var totalChannelCount: Int {
    return channels.count + channelGroups.count
  }

  mutating func remove(channels: [String]) -> [String] {
    return self.channels.remove(contentsOf: channels)
  }

  mutating func removeAllChannels() -> [String] {
    return channels.remove(contentsOf: channels)
  }

  mutating func remove(channelGroups: [String]) -> [String] {
    return self.channelGroups.remove(contentsOf: channelGroups)
  }

  mutating func removeAllChannelGroups() -> [String] {
    return channelGroups.remove(contentsOf: channelGroups)
  }

  // Nil values will be ignored and empty values will become nil after the next subscription loop/setState call
  private(set) var presenceState: ChannelPresenceState = [:]

  mutating func cleanPresenceState(removeNil _: Bool = true, removeEmpty: Bool = true) {
    presenceState = presenceState.filter { channelState in
      if removeEmpty, channelState.value.isEmpty {
        return false
      }
      return true
    }
  }

  mutating func mergePresenceState(
    _ other: ChannelPresenceState,
    removingEmpty: Bool = true,
    addingChannels: Bool = false
  ) {
    // Clean List before processing
    cleanPresenceState()

    // Get all the empty values and remove them from the existing state list
    other.forEach { channelState in
      if removingEmpty, channelState.value.isEmpty {
        // Remove empty lists from our cached list
        presenceState.removeValue(forKey: channelState.key)
      } else if addingChannels, presenceState[channelState.key] == nil {
        // Only update channels that we're actively subscribed to
        presenceState.updateValue(channelState.value, forKey: channelState.key)
      } else if presenceState[channelState.key] != nil {
        // Update any tracked values
        presenceState.updateValue(channelState.value, forKey: channelState.key)
      }
    }
  }
}
