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
  //  case whereNow                             = "WhereNow"
  //  case hereNowGlobal                        = "HereNowGlobal"
  //  case hereNowForChannel                    = "HereNowForChannel"
  //  case hereNowForChannelGroup               = "HereNowForChannelGroup"
  //  case heartbeat                            = "Heartbeat"
  //  case setState                             = "SetState"
  //  case getState                             = "GetState"
  //  case stateForChannel                      = "StateForChannel"
  //  case stateForChannelGroup                 = "StateForChannelGroup"
  //  case unsubscribe                          = "Unsubscribe"
  // Channel Groups
  //  case addChannelsToGroup                   = "AddChannelsToGroup"
  //  case removeChannelsFromGroup              = "RemoveChannelsFromGroup"
  //  case channelGroups                        = "ChannelGroups"
  //  case removeGroup                          = "RemoveGroup"
  //  case channelsForGroup                     = "ChannelsForGroup"
  // Push Notifications
  //  case pushNotificationEnabledChannels      = "PushNotificationEnabledChannels"
  //  case addPushNotificationsOnChannels       = "AddPushNotificationsOnChannels"
  //  case removePushNotificationsFromChannels  = "RemovePushNotificationsFromChannels"
  //  case removeAllPushNotifications           = "RemoveAllPushNotifications"
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
    }
  }
}

// swiftlint:enable discouraged_optional_boolean
