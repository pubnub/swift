//
//  ChannelGroups.swift
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

// MARK: - Router Helpers

enum QueryKey: String {
  case meta
  case store
  case ttl
  case norep
  case channelGroup = "channel-group"
  case timetokenShort = "tt"
  case regionShort = "tr"
  case state
  case heartbeat
  case filterExpr = "filter-expr"
  case disableUUIDs = "disable_uuids"
  case remove
  case add
  case type
  case start
  case end
  case channel
  case count
  case max
  case includeMeta = "include_meta"
  case timetoken
  case channelsTimetoken
  case include
  case limit
  case topic
  case environment
  case filter
  case sort
  case descending = "desc"
}

/// The PubNub Key requirement for a given Endpoint
public enum PNKeyRequirement: String {
  /// No key is required
  case none = "None"
  /// Only a publish key is required
  case publish = "Publish"
  /// Only a subscribe key is required
  case subscribe = "Subscribe"
  /// Both a subscribe and publish key are required
  case publishAndSubscribe = "Publish & Subscribe"
}

/// The PubNub PAM version for a given Endpoint
public enum PAMVersionRequirement {
  /// No PAM is needed for this endpoint
  case none
  /// A key from a version 2 PAM grant is required
  case version2
  /// A key from a version 3 PAM grant is required
  case version3
}
