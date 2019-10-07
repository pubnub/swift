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
// swiftlint:disable discouraged_optional_boolean discouraged_optional_collection file_length

import Foundation

public enum Endpoint {
  public enum RawValue: Int {
    case unknown
    case time
    case publish
    case compressedPublish
    case fire
    case signal
    case subscribe
    case heartbeat
    case leave
    case setPresenceState
    case getPresenceState
    case hereNow
    case hereNowGlobal
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
    case messageCounts

    case objectsUserFetchAll
    case objectsUserFetch
    case objectsUserCreate
    case objectsUserUpdate
    case objectsUserDelete
    case objectsUserMemberships
    case objectsUserMembershipsUpdate

    case objectsSpaceFetchAll
    case objectsSpaceFetch
    case objectsSpaceCreate
    case objectsSpaceUpdate
    case objectsSpaceDelete
    case objectsSpaceMemberships
    case objectsSpaceMembershipsUpdate
  }

  public enum PushType: String, Codable {
    case apns
    case gcm
    case mpns
  }

  public enum IncludeField: String, Codable {
    case custom
    case user
    case customUser = "user.custom"
    case space
    case customSpace = "space.custom"
  }

  // Time Endpoint
  case time

  // Publish Endpoint
  case publish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
  case compressedPublish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
  case fire(message: AnyJSON, channel: String, meta: AnyJSON?)
  case signal(message: AnyJSON, channel: String)

  // Subscribe Endpoint
  case subscribe(
    channels: [String], groups: [String], timetoken: Timetoken?,
    region: String?, state: ChannelPresenceState?, heartbeat: Int?, filter: String?
  )

  // History
  case fetchMessageHistory(channels: [String], max: Int?, start: Timetoken?, end: Timetoken?, includeMeta: Bool)
  case deleteMessageHistory(channel: String, start: Timetoken?, end: Timetoken?)

  // Message Counts
  case messageCounts(channels: [String], timetoken: Timetoken?, channelsTimetoken: [Timetoken]?)

  // Presence Endpoints
  case hereNow(channels: [String], groups: [String], includeUUIDs: Bool, includeState: Bool)
  case hereNowGlobal(includeUUIDs: Bool, includeState: Bool)
  case whereNow(uuid: String)
  case heartbeat(channels: [String], groups: [String], state: [String: Codable]?, presenceTimeout: Int?)
  case leave(channels: [String], groups: [String])
  case getPresenceState(uuid: String, channels: [String], groups: [String])
  case setPresenceState(channels: [String], groups: [String], state: [String: Codable])

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

  // User Objects
  case objectsUserFetchAll(include: IncludeField?, limit: Int?, start: String?, end: String?, count: Bool?)
  case objectsUserFetch(userID: String, include: IncludeField?)
  case objectsUserCreate(user: PubNubUser, include: IncludeField?)
  case objectsUserUpdate(user: PubNubUser, include: IncludeField?)
  case objectsUserDelete(userID: String, include: IncludeField?)
  case objectsUserMemberships(
    userID: String,
    include: [IncludeField]?,
    limit: Int?, start: String?, end: String?, count: Bool?
  )
  case objectsUserMembershipsUpdate(
    userID: String,
    add: [ObjectIdentifiable], update: [ObjectIdentifiable], remove: [ObjectIdentifiable],
    include: [IncludeField]?,
    limit: Int?, start: String?, end: String?, count: Bool?
  )

  // Space Objects
  case objectsSpaceFetchAll(include: IncludeField?, limit: Int?, start: String?, end: String?, count: Bool?)
  case objectsSpaceFetch(spaceID: String, include: IncludeField?)
  case objectsSpaceCreate(space: PubNubSpace, include: IncludeField?)
  case objectsSpaceUpdate(space: PubNubSpace, include: IncludeField?)
  case objectsSpaceDelete(spaceID: String, include: IncludeField?)
  case objectsSpaceMemberships(
    spaceID: String,
    include: [IncludeField]?,
    limit: Int?, start: String?, end: String?, count: Bool?
  )
  case objectsSpaceMembershipsUpdate(
    spaceID: String,
    add: [ObjectIdentifiable], update: [ObjectIdentifiable], remove: [ObjectIdentifiable],
    include: [IncludeField]?,
    limit: Int?, start: String?, end: String?, count: Bool?
  )

  case unknown

  public var rawValue: RawValue {
    switch self {
    case .time:
      return .time
    case .publish:
      return .publish
    case .compressedPublish:
      return .compressedPublish
    case .fire:
      return .fire
    case .signal:
      return .signal
    case .subscribe:
      return .subscribe
    case .heartbeat:
      return .heartbeat
    case .leave:
      return .leave
    case .getPresenceState:
      return .getPresenceState
    case .setPresenceState:
      return .setPresenceState
    case .hereNow:
      return .hereNow
    case .hereNowGlobal:
      return .hereNowGlobal
    case .whereNow:
      return .whereNow
    case .messageCounts:
      return .messageCounts
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
    case .objectsUserFetch:
      return .objectsUserFetch
    case .objectsUserFetchAll:
      return .objectsUserFetchAll
    case .objectsUserCreate:
      return .objectsUserCreate
    case .objectsUserUpdate:
      return .objectsUserUpdate
    case .objectsUserDelete:
      return .objectsUserDelete
    case .objectsSpaceFetch:
      return .objectsSpaceFetch
    case .objectsSpaceFetchAll:
      return .objectsSpaceFetchAll
    case .objectsSpaceCreate:
      return .objectsSpaceCreate
    case .objectsSpaceUpdate:
      return .objectsSpaceUpdate
    case .objectsSpaceDelete:
      return .objectsSpaceDelete
    case .objectsUserMemberships:
      return .objectsUserMemberships
    case .objectsUserMembershipsUpdate:
      return .objectsUserMembershipsUpdate
    case .objectsSpaceMemberships:
      return .objectsSpaceMemberships
    case .objectsSpaceMembershipsUpdate:
      return .objectsSpaceMembershipsUpdate

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
    case let .signal(message, channel):
      return isEndpointInvalid(message.isEmpty, channel.isEmpty)
    case let .subscribe(parameters):
      return isEndpointInvalid(parameters.channels.isEmpty && parameters.groups.isEmpty)
    case let .fetchMessageHistory(channels, max, _, _, _):
      return isEndpointInvalid(channels.isEmpty, max ?? 1 < 1)
    case let .deleteMessageHistory(channel, _, _):
      return isEndpointInvalid(channel.isEmpty)
    case let .hereNow(channels, groups, _, _):
      return isEndpointInvalid(channels.isEmpty && groups.isEmpty)
    case .hereNowGlobal:
      return nil
    case let .whereNow(uuid):
      return isEndpointInvalid(uuid.isEmpty)
    case let .messageCounts(channels, timetoken, timetokens):
      return isEndpointInvalid(!validMessageCount(channels: channels,
                                                  timetokens: timetokens,
                                                  timetoken: timetoken))
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
    case let .heartbeat(channels, _, _, presenceTimeout):
      return isEndpointInvalid(channels.isEmpty, presenceTimeout ?? 0 < 0)
    case let .leave(channels, groups):
      return isEndpointInvalid(channels.isEmpty && groups.isEmpty)
    case let .getPresenceState(parameters):
      return isEndpointInvalid(parameters.uuid.isEmpty, parameters.channels.isEmpty && parameters.groups.isEmpty)
    case .setPresenceState(let channels, _, _):
      return isEndpointInvalid(channels.isEmpty)
    case .objectsUserFetch(let userID, _):
      return isEndpointInvalid(userID.isEmpty)
    case .objectsUserFetchAll:
      return nil
    case let .objectsUserCreate(user, _):
      return isEndpointInvalid(!user.isValid)
    case let .objectsUserUpdate(user, _):
      return isEndpointInvalid(!user.isValid)
    case let .objectsUserDelete(userID, _):
      return isEndpointInvalid(userID.isEmpty)

    case .objectsSpaceFetch(let spaceID, _):
      return isEndpointInvalid(spaceID.isEmpty)
    case .objectsSpaceFetchAll:
      return nil
    case let .objectsSpaceCreate(space, _):
      return isEndpointInvalid(!space.isValid)
    case let .objectsSpaceUpdate(space, _):
      return isEndpointInvalid(!space.isValid)
    case let .objectsSpaceDelete(spaceID, _):
      return isEndpointInvalid(spaceID.isEmpty)
    case let .objectsUserMemberships(parameters):
      return isEndpointInvalid(parameters.userID.isEmpty)
    case let .objectsUserMembershipsUpdate(parameters):
      return isEndpointInvalid(parameters.userID.isEmpty,
                               !parameters.add.allSatisfy { $0.isValid },
                               !parameters.update.allSatisfy { $0.isValid },
                               !parameters.remove.allSatisfy { $0.isValid })
    case let .objectsSpaceMemberships(parameters):
      return isEndpointInvalid(parameters.spaceID.isEmpty)
    case let .objectsSpaceMembershipsUpdate(parameters):
      return isEndpointInvalid(parameters.spaceID.isEmpty,
                               !parameters.add.allSatisfy { $0.isValid },
                               !parameters.update.allSatisfy { $0.isValid },
                               !parameters.remove.allSatisfy { $0.isValid })
    }
  }

  func validMessageCount(channels: [String], timetokens: [Timetoken]?, timetoken: Timetoken?) -> Bool {
    guard !channels.isEmpty else {
      return false
    }

    switch (timetokens, timetoken) {
    case let (.some(tokens), _):
      // Ensure that each value of the timetokens is greater than zero
      return tokens.count == channels.count && tokens.allSatisfy { $0 > 0 }
    case let (.none, .some(token)):
      return token > 0
    case (.none, .none):
      return false
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
    case channelGroup = "Channel Group"
    case history = "History"
    case objects = "Objects"
    case presence = "Presence"
    case publish = "Publish"
    case push = "Push"
    case subscribe = "Subscribe"
    case time = "Time"
    case unknown = "Unknown"
  }

  public var operationCategory: OperationType {
    switch rawValue {
    case .time:
      return .time
    case .publish, .compressedPublish, .fire, .signal:
      return .publish
    case .subscribe:
      return .subscribe
    case .hereNow, .hereNowGlobal, .whereNow, .heartbeat, .leave, .setPresenceState, .getPresenceState:
      return .presence
    case .channelGroups, .deleteGroup, .channelsForGroup, .addChannelsForGroup, .removeChannelsForGroup:
      return .channelGroup
    case .listPushChannels, .modifyPushChannels, .removeAllPushChannels:
      return .push
    case .fetchMessageHistory, .fetchMessageHistoryV2, .deleteMessageHistory, .messageCounts:
      return .history
    case .objectsUserFetchAll, .objectsUserFetch, .objectsUserCreate, .objectsUserUpdate, .objectsUserDelete:
      return .objects
    case .objectsSpaceFetchAll, .objectsSpaceFetch, .objectsSpaceCreate, .objectsSpaceUpdate, .objectsSpaceDelete:
      return .objects
    case .objectsUserMemberships, .objectsUserMembershipsUpdate, .objectsSpaceMemberships,
         .objectsSpaceMembershipsUpdate:
      return .objects
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
    case .signal:
      return "Signal"
    case .subscribe:
      return "Subscribe"
    case .heartbeat:
      return "Heartbeat"
    case .leave:
      return "Leave"
    case .setPresenceState:
      return "Set Presence State"
    case .getPresenceState:
      return "Get Presence State"
    case .hereNow:
      return "Here Now"
    case .hereNowGlobal:
      return "Global Here Now"
    case .whereNow:
      return "Where Now"
    case .messageCounts:
      return "Message Counts"
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
    case .objectsUserFetch:
      return "Fetch User Object"
    case .objectsUserFetchAll:
      return "Fetch All User Objects"
    case .objectsUserCreate:
      return "Create User Object"
    case .objectsUserUpdate:
      return "Update User Object"
    case .objectsUserDelete:
      return "Delete User Object"
    case .objectsUserMemberships:
      return "Fetch User's Memberships"
    case .objectsUserMembershipsUpdate:
      return "Update User's Memberships"

    case .objectsSpaceFetch:
      return "Fetch Space Object"
    case .objectsSpaceFetchAll:
      return "Fetch All Space Objects"
    case .objectsSpaceCreate:
      return "Create Space Object"
    case .objectsSpaceUpdate:
      return "Update Space Object"
    case .objectsSpaceDelete:
      return "Delete Space Object"
    case .objectsSpaceMemberships:
      return "Fetch Space's Memberships"
    case .objectsSpaceMembershipsUpdate:
      return "Update Space's Memberships"

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

extension Endpoint {
  public var associatedValue: [String: Any?] {
    switch self {
    case .time:
      return [:]
    case let .publish(message, channel, shouldStore, ttl, meta):
      return ["message": message, "channel": channel, "shouldStore": shouldStore, "ttl": ttl, "meta": meta]
    case let .compressedPublish(message, channel, shouldStore, ttl, meta):
      return ["message": message, "channel": channel, "shouldStore": shouldStore, "ttl": ttl, "meta": meta]
    case let .fire(message, channel, meta):
      return ["message": message, "channel": channel, "meta": meta]
    case let .signal(message, channel):
      return ["message": message, "channel": channel]
    case let .subscribe(channels, groups, timetoken, region, state, heartbeat, filter):
      return ["channels": channels,
              "groups": groups,
              "timetoken": timetoken,
              "region": region,
              "state": state,
              "heartbeat": heartbeat,
              "filter": filter]
    case let .fetchMessageHistory(channels, max, start, end, includeMeta):
      return ["channels": channels, "max": max, "start": start, "end": end, "includeMeta": includeMeta]
    case let .deleteMessageHistory(channel, start, end):
      return ["channel": channel, "start": start, "end": end]
    case let .messageCounts(channels, timetoken, channelsTimetoken):
      return ["channels": channels, "timetoken": timetoken, "channelsTimetoken": channelsTimetoken]
    case let .hereNow(channels, groups, includeUUIDs, includeState):
      return ["channels": channels, "groups": groups, "includeUUIDs": includeUUIDs, "includeState": includeState]
    case let .hereNowGlobal(includeUUIDs, includeState):
      return ["includeUUIDs": includeUUIDs, "includeState": includeState]
    case let .whereNow(uuid):
      return ["uuid": uuid]
    case let .heartbeat(channels, groups, state, presenceTimeout):
      return ["channels": channels, "groups": groups, "state": state, "presenceTimeout": presenceTimeout]
    case let .leave(channels, groups):
      return ["channels": channels, "groups": groups]
    case let .getPresenceState(uuid, channels, groups):
      return ["uuid": uuid, "channels": channels, "groups": groups]
    case let .setPresenceState(channels, groups, state):
      return ["channels": channels, "groups": groups, "state": state]
    case let .channelsForGroup(group):
      return ["group": group]
    case let .addChannelsForGroup(group, channels):
      return ["group": group, "channels": channels]
    case let .removeChannelsForGroup(group, channels):
      return ["group": group, "channels": channels]
    case .channelGroups:
      return [:]
    case let .deleteGroup(group):
      return ["group": group]
    case let .listPushChannels(pushToken, pushType):
      return ["pushToken": pushToken, "pushType": pushType]
    case let .modifyPushChannels(pushToken, pushType, addChannels, removeChannels):
      return ["pushToken": pushToken,
              "pushType": pushType,
              "addChannels": addChannels,
              "removeChannels": removeChannels]
    case let .removeAllPushChannels(pushToken, pushType):
      return ["pushToken": pushToken, "pushType": pushType]

    case let .objectsUserFetchAll(include, limit, start, end, count):
      return ["include": include, "limit": limit, "start": start, "end": end, "count": count]
    case let .objectsUserFetch(userID, include):
      return ["userID": userID, "include": include]
    case let .objectsUserCreate(user, include):
      return ["user": user, "include": include]
    case let .objectsUserUpdate(user, include):
      return ["user": user, "include": include]
    case let .objectsUserDelete(userID, include):
      return ["userID": userID, "include": include]

    case let .objectsSpaceFetchAll(include, limit, start, end, count):
      return ["include": include, "limit": limit, "start": start, "end": end, "count": count]
    case let .objectsSpaceFetch(spaceID, include):
      return ["spaceID": spaceID, "include": include]
    case let .objectsSpaceCreate(space, include):
      return ["space": space, "include": include]
    case let .objectsSpaceUpdate(space, include):
      return ["space": space, "include": include]
    case let .objectsSpaceDelete(spaceID, include):
      return ["spaceID": spaceID, "include": include]

    case let .objectsUserMemberships(parameters):
      return ["userID": parameters.userID,
              "include": parameters.include,
              "limit": parameters.limit, "start": parameters.start, "end": parameters.end, "count": parameters.count]
    case let .objectsUserMembershipsUpdate(parameters):
      return ["userID": parameters.userID,
              "add": parameters.add, "update": parameters.update, "remove": parameters.remove,
              "include": parameters.include,
              "limit": parameters.limit, "start": parameters.start, "end": parameters.end, "count": parameters.count]
    case let .objectsSpaceMemberships(parameters):
      return ["spaceID": parameters.spaceID,
              "include": parameters.include,
              "limit": parameters.limit, "start": parameters.start, "end": parameters.end, "count": parameters.count]
    case let .objectsSpaceMembershipsUpdate(parameters):
      return ["spaceID": parameters.spaceID,
              "add": parameters.add, "update": parameters.update, "remove": parameters.remove,
              "include": parameters.include,
              "limit": parameters.limit, "start": parameters.start, "end": parameters.end, "count": parameters.count]

    case .unknown:
      return [:]
    }
  }
}

// swiftlint:enable discouraged_optional_boolean discouraged_optional_collection file_length
