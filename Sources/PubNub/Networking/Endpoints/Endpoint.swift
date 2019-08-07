//
//  Endpoint.swift
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
// swiftlint:disable discouraged_optional_boolean

import Foundation

public enum Endpoint {
  public enum RawValue: Int {
    case time
    case publish
    case compressedPublish
    case fire
    case subscribe
    case heartbeat
    case leave
    case setPresenceState
    case getPresenceState
    case hereNow
    case whereNow
    case channelsForGroup
    case addChannelsForGroup
    case removeChannelsForGroup
    case channelGroups
    case deleteGroup
  }

  // Time Endpoint
  case time
  // Publish Endpoint
  case publish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
  case compressedPublish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
  case fire(message: AnyJSON, channel: String, meta: AnyJSON?)
  // Subscribe Endpoint
  case subscribe(channels: [String], groups: [String], timetoken: Int?, region: Int?, state: AnyJSON?)
  // History
  //  case history                              = "History"
  //  case historyForChannels                   = "HistoryForChannels"
  //  case deleteMessage                        = "DeleteMessage"
  // Presence Endpoints
  case hereNow(channels: [String], groups: [String], includeUUIDs: Bool, includeState: Bool)
  case whereNow(uuid: String)
  //  case heartbeat                            = "Heartbeat"
  //  case setState                             = "SetState"
  //  case getState                             = "GetState"
  //  case stateForChannel                      = "StateForChannel"
  //  case stateForChannelGroup                 = "StateForChannelGroup"
  //  case unsubscribe                          = "Unsubscribe"
  // Channel Groups
  case channelsForGroup(group: String)
  case addChannelsForGroup(group: String, channels: [String])
  case removeChannelsForGroup(group: String, channels: [String])
  case channelGroups
  case deleteGroup(group: String)
  // Push Notifications
  //  case pushNotificationEnabledChannels      = "PushNotificationEnabledChannels"
  //  case addPushNotificationsOnChannels       = "AddPushNotificationsOnChannels"
  //  case removePushNotificationsFromChannels  = "RemovePushNotificationsFromChannels"
  //  case removeAllPushNotifications           = "RemoveAllPushNotifications"

  var rawValue: RawValue {
    switch self {
    case .time:
      return .time
    case .publish:
      return .publish
    case .compressedPublish:
      return .compressedPublish
    case .fire:
      return .fire
    case .subscribe:
      return .subscribe
    case .hereNow:
      return .hereNow
    case .whereNow:
      return .whereNow
    case .channelsForGroup:
      return .channelsForGroup
    case .addChannelsForGroup:
      return .addChannelsForGroup
    case .removeChannelsForGroup:
      return .removeChannelsForGroup
    case .channelGroups:
      return .channelGroups
    case .deleteGroup:
      return .deleteGroup
    }
  }
}

extension Endpoint: CustomStringConvertible {
  public var description: String {
    switch self {
    case .time:
      return "Time"
    case .publish, .compressedPublish:
      return "Publish"
    case .fire:
      return "Fire"
    case .subscribe:
      return "Subscribe"
    case .hereNow:
      return "Here Now"
    case .whereNow:
      return "Where Now"
    case .channelsForGroup:
      return "List of Channels for Group"
    case .addChannelsForGroup:
      return "Add Channels to Group"
    case .removeChannelsForGroup:
      return "Remove Channels from Group"
    case .channelGroups:
      return "List of Channel Groups"
    case .deleteGroup:
      return "Delete Channel Group"
    }
  }
}

extension Endpoint: Equatable {
  public static func == (lhs: Endpoint, rhs: Endpoint) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}

// swiftlint:enable discouraged_optional_boolean
