//
//  ChannelGroupsRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Router

struct ChannelGroupsRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case channelsForGroup(group: String)
    case addChannelsToGroup(group: String, channels: [String])
    case removeChannelsForGroup(group: String, channels: [String])
    case channelGroups
    case deleteGroup(group: String)

    var description: String {
      switch self {
      case .channelsForGroup:
        return "Group Channels List"
      case .addChannelsToGroup:
        return "Group Channels Add"
      case .removeChannelsForGroup:
        return "Group Channels Remove"
      case .channelGroups:
        return "Group List"
      case .deleteGroup:
        return "Group Delete"
      }
    }
  }

  // Init
  init(_ endpoint: Endpoint, configuration: RouterConfiguration) {
    self.endpoint = endpoint
    self.configuration = configuration
  }

  var endpoint: Endpoint
  var configuration: RouterConfiguration

  // Protocol Properties
  var service: PubNubService {
    return .channelGroup
  }

  var category: String {
    return endpoint.description
  }

  var path: Result<String, Error> {
    let path: String

    switch endpoint {
    case let .channelsForGroup(group):
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group/\(group.urlEncodeSlash)"
    case let .addChannelsToGroup(group, _):
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group/\(group.urlEncodeSlash)"
    case let .removeChannelsForGroup(group, _):
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group/\(group.urlEncodeSlash)"
    case .channelGroups:
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group"
    case let .deleteGroup(group):
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group/\(group.urlEncodeSlash)/remove"
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .addChannelsToGroup(_, channels):
      query.append(URLQueryItem(key: .add, value: channels.csvString))
    case let .removeChannelsForGroup(_, channels):
      query.append(URLQueryItem(key: .remove, value: channels.csvString))
    default:
      break
    }

    return .success(query)
  }

  var pamVersion: PAMVersionRequirement {
    switch endpoint {
    case .channelGroups:
      return .none
    default:
      return .version2
    }
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .channelsForGroup(group):
      return isInvalidForReason((group.isEmpty,
                                 ErrorDescription.emptyGroupString))
    case let .addChannelsToGroup(group, channels):
      return isInvalidForReason(
        (group.isEmpty, ErrorDescription.emptyGroupString),
        (channels.isEmpty, ErrorDescription.emptyChannelArray)
      )
    case let .removeChannelsForGroup(group, channels):
      return isInvalidForReason(
        (group.isEmpty, ErrorDescription.emptyGroupString),
        (channels.isEmpty, ErrorDescription.emptyChannelArray)
      )
    case .channelGroups:
      return nil
    case let .deleteGroup(group):
      return isInvalidForReason((group.isEmpty, ErrorDescription.emptyGroupString))
    }
  }
}

// MARK: - Response Decoder

struct ChannelGroupResponseDecoder<PayloadType>: ResponseDecoder where PayloadType: Codable {
  typealias Payload = PayloadType
}

// MARK: - Response Body

struct AnyChannelGroupResponsePayload<Payload>: Codable where Payload: Codable {
  let status: Int
  let service: String
  let error: Bool
  let payload: Payload
}

// List Groups, Channels
typealias ChannelListPayloadResponse = AnyChannelGroupResponsePayload<ChannelListPayload>

struct ChannelListPayload: Codable {
  let group: String
  let channels: [String]
}

typealias GroupListPayloadResponse = AnyChannelGroupResponsePayload<GroupListPayload>

struct GroupListPayload: Codable {
  let namespace: String?
  let groups: [String]
}
