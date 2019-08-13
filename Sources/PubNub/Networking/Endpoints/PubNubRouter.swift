//
//  PubNubRouter.swift
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

struct PubNubRouter {
  // URL Param Keys
  private let metaKey = "meta"
  private let storedKey = "store"
  private let ttlKey = "ttl"
  private let noRepKey = "norep"
  private let channelGroupsKey = "channel-group"
  private let timetokenKey = "tt"
  private let regionKey = "tr"
  private let stateKey = "state"
  private let heartbeatKey = "heartbeat"
  private let filterKey = "filter-expr"
  private let disableUUIDsKey = "disable_uuids"
  private let removeGroupKey = "remove"
  private let addGroupKey = "add"
  private let typeKey = "type"
  private let startKey = "start"
  private let endKey = "end"
  private let channelKey = "channel"
  private let countKey = "count"
  private let maxKey = "max"
  private let reverseKey = "reverse"
  private let includeTokenKey = "include_token"
  private let includeMetaKey = "include_meta"
  private let stringtokenKey = "stringtoken"

  let configuration: RouterConfiguration
  let endpoint: Endpoint
}

extension PubNubRouter: Router {
  var method: HTTPMethod {
    switch endpoint {
    case .compressedPublish:
      return .post
    case .deleteMessageHistory:
      return .delete
    default:
      return .get
    }
  }

  var path: Result<String, Error> {
    let publishKey = configuration.publishKey?.urlEncodeSlash ?? ""
    let subscribeKey = configuration.subscribeKey?.urlEncodeSlash ?? ""

    // Note: URL Encode slashes `/` for inputs in path as they will be skipped
    // by the URL Loader inside Foundation
    let path: String
    switch endpoint {
    case .time:
      path = "/time/0"
    case let .publish(parameters):
      return parsePublishPath(publishKey: publishKey,
                              subscribeKey: subscribeKey,
                              channel: parameters.channel,
                              message: parameters.message)
    case let .fire(parameters):
      return parsePublishPath(publishKey: publishKey,
                              subscribeKey: subscribeKey,
                              channel: parameters.channel,
                              message: parameters.message)
    case let .compressedPublish(parameters):
      path = "/publish/\(publishKey)/\(subscribeKey)/0/\(parameters.channel.urlEncodeSlash)/0"
    case let .subscribe(parameters):
      path = "/v2/subscribe/\(subscribeKey)/\(parameters.channels.csvString.urlEncodeSlash)/0"
    case let .hereNow(channels, _, _, _):
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels.csvString.urlEncodeSlash)"
    case let .whereNow(uuid):
      path = "/v2/presence/sub-key/\(subscribeKey)/uuid/\(uuid.urlEncodeSlash)"
    case let .channelsForGroup(group):
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group/\(group.urlEncodeSlash)"
    case let .addChannelsForGroup(group, _):
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group/\(group.urlEncodeSlash)"
    case let .removeChannelsForGroup(group, _):
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group/\(group.urlEncodeSlash)"
    case .channelGroups:
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group"
    case let .deleteGroup(group):
      path = "/v1/channel-registration/sub-key/\(subscribeKey)/channel-group/\(group.urlEncodeSlash)/remove"
    case .listPushChannels(let token, _):
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(token.hexEncodedString)"
    case .modifyPushChannels(let token, _, _, _):
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(token.hexEncodedString)"
    case .removeAllPushChannels(let token, _):
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(token.hexEncodedString)/remove"
    case let .fetchMessageHistory(parameters):
      // Deprecated: Remove v2 message history path when single group support added to v3
      if parameters.channels.count == 1, let channel = parameters.channels.first {
        path = "/v2/history/sub-key/\(subscribeKey)/channel/\(channel.urlEncodeSlash)"
      } else {
        path = "/v3/history/sub-key/\(subscribeKey)/channel/\(parameters.channels.csvString.urlEncodeSlash)"
      }
    case .deleteMessageHistory(let channel, _, _):
      path = "/v3/history/sub-key/\(subscribeKey)/channel/\(channel.urlEncodeSlash)"
    case .unknown:
      return .failure(PNError.unknown(message: endpoint.description, endpoint))
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = [URLQueryItem]()
    switch endpoint {
    case let .publish(_, _, shouldStore, ttl, meta):
      return parsePublish(query: &query, shouldStore: shouldStore, ttl: ttl, meta: meta)
    case let .compressedPublish(_, _, shouldStore, ttl, meta):
      return parsePublish(query: &query, shouldStore: shouldStore, ttl: ttl, meta: meta)
    case let .fire(_, _, meta):
      return parsePublish(query: &query, shouldStore: false, ttl: 0, meta: meta)
    case let .subscribe(parameters):
      query.append(URLQueryItem(name: timetokenKey, value: parameters.timetoken.description))
      query.appendIfNotEmpty(name: channelGroupsKey, value: parameters.groups)
      query.appendIfPresent(name: regionKey, value: parameters.region?.description)
    case let .hereNow(_, groups, includeUUIDs, includeState):
      query.appendIfNotEmpty(name: channelGroupsKey, value: groups)
      query.append(URLQueryItem(name: disableUUIDsKey, value: (!includeUUIDs).stringNumber))
      query.append(URLQueryItem(name: stateKey, value: includeState.stringNumber))
    case let .addChannelsForGroup(_, channels):
      query.append(URLQueryItem(name: addGroupKey, value: channels.csvString))
    case let .removeChannelsForGroup(_, channels):
      query.append(URLQueryItem(name: removeGroupKey, value: channels.csvString))
    case let .listPushChannels(_, pushType):
      query.append(URLQueryItem(name: typeKey, value: pushType.rawValue))
    case let .modifyPushChannels(_, pushType, addChannels, removeChannels):
      query.append(URLQueryItem(name: typeKey, value: pushType.rawValue))
      query.appendIfNotEmpty(name: typeKey, value: addChannels)
      query.appendIfNotEmpty(name: typeKey, value: removeChannels)
    case let .removeAllPushChannels(_, pushType):
      query.append(URLQueryItem(name: typeKey, value: pushType.rawValue))
    case let .fetchMessageHistory(_, max, start, end, includeMeta):
      // Deprecated: Remove `countKey` with v2 message history
      query.appendIfPresent(name: countKey, value: max?.description)
      query.appendIfPresent(name: stringtokenKey, value: false.description)
      query.appendIfPresent(name: includeTokenKey, value: true.description)
      query.appendIfPresent(name: reverseKey, value: false.description)
      // End Deprecation Block

      query.appendIfPresent(name: maxKey, value: max?.description)
      query.appendIfPresent(name: startKey, value: start?.description)
      query.appendIfPresent(name: endKey, value: end?.description)
      query.appendIfPresent(name: includeMetaKey, value: includeMeta.description)
    case let .deleteMessageHistory(_, startTimetoken, endTimetoken):
      query.appendIfPresent(name: startKey, value: startTimetoken?.description)
      query.appendIfPresent(name: endKey, value: endTimetoken?.description)
    default:
      break
    }
    return .success(query)
  }

  var additionalHeaders: HTTPHeaders {
    return [:]
  }

  var body: AnyJSON? {
    switch endpoint {
    case let .compressedPublish(parameters):
      return parameters.message
    default:
      return nil
    }
  }

  var keysRequired: PNKeyRequirement {
    switch endpoint {
    case .time:
      return .none
    case .publish, .compressedPublish:
      return .publishAndSubscribe
    case .fire:
      return .publishAndSubscribe
    default:
      return .subscribe
    }
  }

  var pamVersion: PAMVersionRequirement {
    switch endpoint {
    case .time:
      return .none
    case .hereNow:
      return .none
    case .whereNow:
      return .none
    case .channelsForGroup:
      return .none
    case .channelGroups:
      return .none
    case .listPushChannels:
      return .none
    case .removeAllPushChannels:
      return .none
    default:
      return .version2
    }
  }

  func decodeError(endpoint: Endpoint, request: URLRequest, response: HTTPURLResponse, for data: Data?) -> PNError? {
    switch endpoint {
    case .publish, .compressedPublish, .fire:
      return PublishResponseDecoder().decodeError(endpoint: endpoint, request: request, response: response, for: data)
    default:
      return AnyJSONResponseDecoder().decodeError(endpoint: endpoint, request: request, response: response, for: data)
    }
  }
}

extension PubNubRouter {
  func parsePublishPath(
    publishKey: String,
    subscribeKey: String,
    channel: String,
    message: AnyJSON
  ) -> Result<String, Error> {
    return message.jsonStringifyResult.map {
      "/publish/\(publishKey)/\(subscribeKey)/0/\(channel.urlEncodeSlash)/0/\($0.urlEncodeSlash)"
    }.mapError {
      PNError.requestCreationFailure(.jsonStringCodingFailure(message, dueTo: $0), endpoint)
    }
  }

  func parsePublish(
    query: inout [URLQueryItem],
    shouldStore: Bool?,
    ttl: Int?,
    meta: AnyJSON?
  ) -> Result<[URLQueryItem], Error> {
    query.appendIfPresent(name: storedKey, value: shouldStore?.stringNumber)
    query.appendIfPresent(name: ttlKey, value: ttl?.description)

    if let meta = meta, !meta.isEmpty {
      do {
        try query.append(URLQueryItem(name: metaKey, value: meta.jsonStringifyResult.get()))
        return .success(query)
      } catch {
        return .failure(PNError.requestCreationFailure(.jsonStringCodingFailure(meta, dueTo: error), endpoint))
      }
    }

    return .success(query)
  }
}

// swiftlint:enable discouraged_optional_boolean
