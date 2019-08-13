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
    case unknown
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
    case listPushChannels
    case modifyPushChannels
    case removeAllPushChannels
    case fetchMessageHistoryV2
    case fetchMessageHistory
    case deleteMessageHistory
  }

  public enum PushType: String, Codable {
    case apns
    case gcm
    case mpns
  }

  // Time Endpoint
  case time

  // Publish Endpoint
  case publish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
  case compressedPublish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
  case fire(message: AnyJSON, channel: String, meta: AnyJSON?)

  // Subscribe Endpoint
  case subscribe(channels: [String], groups: [String], timetoken: Int, region: Int?, state: AnyJSON?)

  // History
  case fetchMessageHistory(channels: [String], max: Int?, start: Timetoken?, end: Timetoken?, includeMeta: Bool)
  case deleteMessageHistory(channel: String, start: Timetoken?, end: Timetoken?)

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
  case listPushChannels(pushToken: Data, pushType: PushType)
  case modifyPushChannels(pushToken: Data, pushType: PushType, addChannels: [String], removeChannels: [String])
  case removeAllPushChannels(pushToken: Data, pushType: PushType)

  case unknown

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
    case .listPushChannels:
      return .listPushChannels
    case .modifyPushChannels:
      return .modifyPushChannels
    case .removeAllPushChannels:
      return .removeAllPushChannels
    case let .fetchMessageHistory(parameters):
      // Deprecated: Remove v2 message history path when single group support added to v3
      if parameters.channels.count == 1 {
        return .fetchMessageHistoryV2
      }
      return .fetchMessageHistory
    case .deleteMessageHistory:
      return .deleteMessageHistory
    case .unknown:
      return .unknown
    }
  }
}

extension Endpoint: Validated {
  public var validationError: Error? {
    switch self {
    case .time:
      return nil
    case let .publish(message, channel, _, _, _):
      return isEndpointInvalid(message.isEmpty, channel.isEmpty)
    case let .compressedPublish(message, channel, _, _, _):
      return isEndpointInvalid(message.isEmpty, channel.isEmpty)
    case let .fire(message, channel, _):
      return isEndpointInvalid(message.isEmpty, channel.isEmpty)
    case let .subscribe(channels, _, timetoken, _, _):
      return isEndpointInvalid(channels.isEmpty, timetoken < 0)
    case let .fetchMessageHistory(channels, max, _, _, _):
      return isEndpointInvalid(channels.isEmpty, max ?? 1 < 1)
    case let .deleteMessageHistory(channel, _, _):
      return isEndpointInvalid(channel.isEmpty)
    case let .hereNow(channels, _, _, _):
      return isEndpointInvalid(channels.isEmpty)
    case let .whereNow(uuid):
      return isEndpointInvalid(uuid.isEmpty)
    case let .channelsForGroup(group):
      return isEndpointInvalid(group.isEmpty)
    case let .addChannelsForGroup(group, channels):
      return isEndpointInvalid(group.isEmpty, channels.isEmpty)
    case let .removeChannelsForGroup(group, channels):
      return isEndpointInvalid(group.isEmpty, channels.isEmpty)
    case .channelGroups:
      return nil
    case let .deleteGroup(group):
      return isEndpointInvalid(group.isEmpty)
    case .listPushChannels(let pushToken, _):
      return isEndpointInvalid(pushToken.isEmpty)
    case let .modifyPushChannels(pushToken, _, addChannels, removeChannels):
      return isEndpointInvalid(pushToken.isEmpty, addChannels.isEmpty && removeChannels.isEmpty)
    case .removeAllPushChannels(let pushToken, _):
      return isEndpointInvalid(pushToken.isEmpty)
    case .unknown:
      return PNError.invalidEndpointType(self)
    }
  }

  func isEndpointInvalid(_ values: Bool...) -> PNError? {
    for invalidValue in values where invalidValue {
      return PNError.missingRequiredParameter(self)
    }
    return nil
  }
}

extension Endpoint {
  public enum OperationType: String {
    case publish = "Publish"
    case subscribe = "Subscribe"
    case history = "History"
    case presence = "Presence"
    case channelGroup = "ChannelGroup"
    case push = "Push"
    case time = "Time"
    case unknown = "Unknown"
  }

  public var operationCategory: OperationType {
    switch rawValue {
    case .time:
      return .time
    case .publish, .compressedPublish, .fire:
      return .publish
    case .subscribe:
      return .subscribe
    case .hereNow, .whereNow, .heartbeat, .leave, .setPresenceState, .getPresenceState:
      return .presence
    case .channelGroups, .deleteGroup, .channelsForGroup, .addChannelsForGroup, .removeChannelsForGroup:
      return .channelGroup
    case .listPushChannels, .modifyPushChannels, .removeAllPushChannels:
      return .push
    case .fetchMessageHistory, .fetchMessageHistoryV2, .deleteMessageHistory:
      return .history
    case .unknown:
      return .unknown
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
    case .channelGroups:
      return "Group List"
    case .deleteGroup:
      return "Group Delete"
    case .channelsForGroup:
      return "Group Channels List"
    case .addChannelsForGroup:
      return "Group Channels Add"
    case .removeChannelsForGroup:
      return "Group Channels Remove"
    case .listPushChannels:
      return "List Push Channels"
    case .modifyPushChannels:
      return "Modify Push Channels"
    case .removeAllPushChannels:
      return "Remove All Push Channels"
    case .fetchMessageHistory:
      return "Fetch Message History"
    case .deleteMessageHistory:
      return "Delete Message History"
    case .unknown:
      return "Unknown"
    }
  }
}

extension Endpoint: Equatable {
  public static func == (lhs: Endpoint, rhs: Endpoint) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}

// swiftlint:enable discouraged_optional_boolean
