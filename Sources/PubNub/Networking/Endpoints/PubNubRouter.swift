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
  case filter = "filter-expr"
  case disableUUIDs = "disable_uuids"
  case remove
  case add
  case type
  case start
  case end
  case channel
  case count
  case max
  case reverse
  case includeToken = "include_token"
  case includeMeta = "include_meta"
  case stringtoken
  case timetoken
  case channelsTimetoken
  case include
  case limit
}

struct PubNubRouter {
  let configuration: RouterConfiguration
  let endpoint: Endpoint
  let crypto: Crypto?

  public init(configuration: RouterConfiguration, endpoint: Endpoint, crypto: Crypto? = nil) {
    self.configuration = configuration
    self.endpoint = endpoint
    self.crypto = crypto
  }
}

extension PubNubRouter: Router {
  var method: HTTPMethod {
    switch endpoint {
    case .compressedPublish:
      return .post
    case .deleteMessageHistory:
      return .delete
    case .objectsUserCreate:
      return .post
    case .objectsUserUpdate:
      return .patch
    case .objectsUserDelete:
      return .delete
    case .objectsSpaceCreate:
      return .post
    case .objectsSpaceUpdate:
      return .patch
    case .objectsSpaceDelete:
      return .delete
    case .objectsUserMembershipsUpdate:
      return .patch
    case .objectsSpaceMembershipsUpdate:
      return .patch
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
      return append(message: parameters.message,
                    to: "/publish/\(publishKey)/\(subscribeKey)/0/\(parameters.channel.urlEncodeSlash)/0/")
    case let .fire(parameters):
      return append(message: parameters.message,
                    to: "/publish/\(publishKey)/\(subscribeKey)/0/\(parameters.channel.urlEncodeSlash)/0/")
    case let .compressedPublish(parameters):
      path = "/publish/\(publishKey)/\(subscribeKey)/0/\(parameters.channel.urlEncodeSlash)/0"
    case let .signal(message, channel):
      return append(message: message,
                    to: "/signal/\(publishKey)/\(subscribeKey)/0/\(channel.urlEncodeSlash)/0/")
    case let .subscribe(parameters):
      let channels = parameters.channels.commaOrCSVString.urlEncodeSlash
      path = "/v2/subscribe/\(subscribeKey)/\(channels)/0"
    case let .heartbeat(channels, _, _, _):
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels.csvString.urlEncodeSlash)/heartbeat"
    case let .leave(channels, _):
      let channels = channels.commaOrCSVString.urlEncodeSlash
      path = "/v2/presence/sub_key/\(subscribeKey)/channel/\(channels)/leave"
    case let .getPresenceState(uuid, channels, _):
      let channels = channels.commaOrCSVString.urlEncodeSlash
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels)/uuid/\(uuid.urlEncodeSlash)"
    case let .setPresenceState(channels, _, _):
      let channels = channels.commaOrCSVString.urlEncodeSlash
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels)/uuid/\(configuration.uuid.urlEncodeSlash)/data"
    case let .hereNow(channels, _, _, _):
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels.csvString.urlEncodeSlash)"
    case .hereNowGlobal:
      path = "/v2/presence/sub-key/\(subscribeKey)"
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
    case let .messageCounts(channels, _, _):
      path = "/v3/history/sub-key/\(subscribeKey)/message-counts/\(channels.csvString.urlEncodeSlash)"

    case .objectsUserFetch(let userID, _):
      path = "/v1/objects/\(subscribeKey)/users/\(userID)"
    case .objectsUserFetchAll:
      path = "/v1/objects/\(subscribeKey)/users"
    case .objectsUserCreate:
      path = "/v1/objects/\(subscribeKey)/users"
    case let .objectsUserUpdate(user, _):
      path = "/v1/objects/\(subscribeKey)/users/\(user.id)"
    case let .objectsUserDelete(userID, _):
      path = "/v1/objects/\(subscribeKey)/users/\(userID)"

    case .objectsSpaceFetch(let spaceID, _):
      path = "/v1/objects/\(subscribeKey)/spaces/\(spaceID)"
    case .objectsSpaceFetchAll:
      path = "/v1/objects/\(subscribeKey)/spaces"
    case .objectsSpaceCreate:
      path = "/v1/objects/\(subscribeKey)/spaces"
    case let .objectsSpaceUpdate(space, _):
      path = "/v1/objects/\(subscribeKey)/spaces/\(space.id)"
    case let .objectsSpaceDelete(spaceID, _):
      path = "/v1/objects/\(subscribeKey)/spaces/\(spaceID)"

    case let .objectsUserMemberships(parameters):
      path = "/v1/objects/demo/users/\(parameters.userID)/spaces"
    case let .objectsUserMembershipsUpdate(parameters):
      path = "/v1/objects/demo/users/\(parameters.userID)/spaces"
    case let .objectsSpaceMemberships(parameters):
      path = "/v1/objects/demo/spaces/\(parameters.spaceID)/users"
    case let .objectsSpaceMembershipsUpdate(parameters):
      path = "/v1/objects/demo/spaces/\(parameters.spaceID)/users"

    case .unknown:
      return .failure(PNError.unknown(endpoint.description, endpoint))
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
      query.appendIfPresent(key: .timetokenShort, value: parameters.timetoken?.description)
      query.appendIfNotEmpty(key: .channelGroup, value: parameters.groups)
      query.appendIfPresent(key: .regionShort, value: parameters.region?.description)
      query.appendIfPresent(key: .filter, value: parameters.filter)
      query.appendIfPresent(key: .heartbeat, value: parameters.heartbeat?.description)
      return parseState(query: &query, state: parameters.state)
    case let .heartbeat(parameters):
      query.appendIfNotEmpty(key: .channelGroup, value: parameters.groups)
      query.appendIfPresent(key: .heartbeat, value: parameters.presenceTimeout?.description)
      return parseState(query: &query, state: parameters.state)
    case let .leave(_, groups):
      query.appendIfNotEmpty(key: .channelGroup, value: groups)
    case let .getPresenceState(parameters):
      query.appendIfNotEmpty(key: .channelGroup, value: parameters.groups)
    case let .setPresenceState(parameters):
      if !parameters.state.isEmpty {
        return parseState(query: &query, state: parameters.state)
      } else {
        query.append(URLQueryItem(key: .state, value: "{}"))
      }
    case let .hereNow(_, groups, includeUUIDs, includeState):
      query.appendIfNotEmpty(key: .channelGroup, value: groups)
      query.append(URLQueryItem(key: .disableUUIDs, value: (!includeUUIDs).stringNumber))
      query.append(URLQueryItem(key: .state, value: includeState.stringNumber))
    case let .hereNowGlobal(includeUUIDs, includeState):
      query.append(URLQueryItem(key: .disableUUIDs, value: (!includeUUIDs).stringNumber))
      query.append(URLQueryItem(key: .state, value: includeState.stringNumber))
    case let .addChannelsForGroup(_, channels):
      query.append(URLQueryItem(key: .add, value: channels.csvString))
    case let .removeChannelsForGroup(_, channels):
      query.append(URLQueryItem(key: .remove, value: channels.csvString))
    case let .listPushChannels(_, pushType):
      query.append(URLQueryItem(key: .type, value: pushType.rawValue))
    case let .modifyPushChannels(_, pushType, addChannels, removeChannels):
      query.append(URLQueryItem(key: .type, value: pushType.rawValue))
      query.appendIfNotEmpty(key: .type, value: addChannels)
      query.appendIfNotEmpty(key: .type, value: removeChannels)
    case let .removeAllPushChannels(_, pushType):
      query.append(URLQueryItem(key: .type, value: pushType.rawValue))
    case let .fetchMessageHistory(_, max, start, end, includeMeta):
      // Deprecated: Remove `count` with v2 message history
      query.appendIfPresent(key: .count, value: max?.description)
      query.appendIfPresent(key: .stringtoken, value: false.description)
      query.appendIfPresent(key: .includeToken, value: true.description)
      query.appendIfPresent(key: .reverse, value: false.description)
      // End Deprecation Block

      query.appendIfPresent(key: .max, value: max?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .includeMeta, value: includeMeta.description)
    case let .deleteMessageHistory(_, startTimetoken, endTimetoken):
      query.appendIfPresent(key: .start, value: startTimetoken?.description)
      query.appendIfPresent(key: .end, value: endTimetoken?.description)
    case let .messageCounts(parameters):
      query.appendIfPresent(key: .timetoken, value: parameters.timetoken?.description)
      query.appendIfPresent(key: .channelsTimetoken,
                            value: parameters.channelsTimetoken?.map { $0.description }.csvString)

    case let .objectsUserFetch(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case let .objectsUserFetchAll(include, limit, start, end, count):
      query.appendIfPresent(key: .include, value: include?.rawValue)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .count, value: count?.description)
    case let .objectsUserCreate(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case let .objectsUserUpdate(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case let .objectsUserDelete(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)

    case let .objectsSpaceFetch(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case let .objectsSpaceFetchAll(include, limit, start, end, count):
      query.appendIfPresent(key: .include, value: include?.rawValue)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .count, value: count?.description)
    case let .objectsSpaceCreate(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case let .objectsSpaceUpdate(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case let .objectsSpaceDelete(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case let .objectsUserMemberships(parameters):
      query.appendIfPresent(key: .include, value: parameters.include?.map { $0.rawValue }.csvString)
      query.appendIfPresent(key: .limit, value: parameters.limit?.description)
      query.appendIfPresent(key: .start, value: parameters.start?.description)
      query.appendIfPresent(key: .end, value: parameters.end?.description)
      query.appendIfPresent(key: .count, value: parameters.count?.description)
    case let .objectsUserMembershipsUpdate(parameters):
      query.appendIfPresent(key: .include, value: parameters.include?.map { $0.rawValue }.csvString)
      query.appendIfPresent(key: .limit, value: parameters.limit?.description)
      query.appendIfPresent(key: .start, value: parameters.start?.description)
      query.appendIfPresent(key: .end, value: parameters.end?.description)
      query.appendIfPresent(key: .count, value: parameters.count?.description)
    case let .objectsSpaceMemberships(parameters):
      query.appendIfPresent(key: .include, value: parameters.include?.map { $0.rawValue }.csvString)
      query.appendIfPresent(key: .limit, value: parameters.limit?.description)
      query.appendIfPresent(key: .start, value: parameters.start?.description)
      query.appendIfPresent(key: .end, value: parameters.end?.description)
      query.appendIfPresent(key: .count, value: parameters.count?.description)
    case let .objectsSpaceMembershipsUpdate(parameters):
      query.appendIfPresent(key: .include, value: parameters.include?.map { $0.rawValue }.csvString)
      query.appendIfPresent(key: .limit, value: parameters.limit?.description)
      query.appendIfPresent(key: .start, value: parameters.start?.description)
      query.appendIfPresent(key: .end, value: parameters.end?.description)
      query.appendIfPresent(key: .count, value: parameters.count?.description)
    default:
      break
    }
    return .success(query)
  }

  var additionalHeaders: HTTPHeaders {
    return [:]
  }

  var body: Result<Data?, Error> {
    switch endpoint {
    case let .compressedPublish(parameters):
      if let crypto = configuration.cipherKey {
        return parameters.message.jsonStringifyResult.flatMap {
          crypto.encrypt(plaintext: $0).map { $0.jsonDescription.data(using: .utf8) }
        }.mapError { PNError.requestCreationFailure(.jsonDataCodingFailure(parameters.message, with: $0), endpoint) }
      }
      return parameters.message.jsonDataResult
        .map { .some($0) }
        .mapError { PNError.requestCreationFailure(.jsonDataCodingFailure(parameters.message, with: $0), endpoint) }
    case let .objectsUserCreate(user, _):
      return user.jsonDataResult
        .map { .some($0) }
        .mapError { PNError.requestCreationFailure(.jsonDataCodingFailure(user.codableValue, with: $0), endpoint) }
    case let .objectsUserUpdate(user, _):
      return user.jsonDataResult
        .map { .some($0) }
        .mapError { PNError.requestCreationFailure(.jsonDataCodingFailure(user.codableValue, with: $0), endpoint) }
    case let .objectsSpaceCreate(space, _):
      return space.jsonDataResult
        .map { .some($0) }
        .mapError { PNError.requestCreationFailure(.jsonDataCodingFailure(space.codableValue, with: $0), endpoint) }
    case let .objectsSpaceUpdate(space, _):
      return space.jsonDataResult
        .map { .some($0) }
        .mapError { PNError.requestCreationFailure(.jsonDataCodingFailure(space.codableValue, with: $0), endpoint) }
    case let .objectsUserMembershipsUpdate(parameters):
      let changeset = ObjectIdentifiableChangeset(add: parameters.add,
                                                  update: parameters.update,
                                                  remove: parameters.remove)
      return changeset.encodableJSONData
        .map { .some($0) }
        .mapError { PNError.requestCreationFailure(.jsonDataCodingFailure(AnyJSON(changeset), with: $0), endpoint) }
    case let .objectsSpaceMembershipsUpdate(parameters):
      let changeset = ObjectIdentifiableChangeset(add: parameters.add,
                                                  update: parameters.update,
                                                  remove: parameters.remove)
      return changeset.encodableJSONData
        .map { .some($0) }
        .mapError { PNError.requestCreationFailure(.jsonDataCodingFailure(AnyJSON(changeset), with: $0), endpoint) }
    default:
      return .success(nil)
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
    case .heartbeat:
      return .none
    case .leave:
      return .none
    case .objectsUserFetch, .objectsUserFetchAll, .objectsUserCreate, .objectsUserUpdate, .objectsUserDelete:
      return .version3
    case .objectsSpaceFetch, .objectsSpaceFetchAll, .objectsSpaceCreate, .objectsSpaceUpdate, .objectsSpaceDelete:
      return .version3
    case .objectsUserMemberships, .objectsUserMembershipsUpdate, .objectsSpaceMemberships,
         .objectsSpaceMembershipsUpdate:
      return .version3
    default:
      return .version2
    }
  }

  func decodeError(endpoint: Endpoint, request: URLRequest, response: HTTPURLResponse, for data: Data?) -> PNError? {
    switch endpoint {
    case .publish, .compressedPublish, .fire, .signal:
      return PublishResponseDecoder().decodeError(endpoint: endpoint, request: request, response: response, for: data)
    default:
      return AnyJSONResponseDecoder().decodeError(endpoint: endpoint, request: request, response: response, for: data)
    }
  }
}

extension PubNubRouter {
  func append(message: AnyJSON, to partialPath: String) -> Result<String, Error> {
    if let crypto = configuration.cipherKey {
      return message.jsonDataResult.flatMap { jsonData in
        crypto.encrypt(utf8Encoded: jsonData)
          .flatMap { .success("\(partialPath)\($0.base64EncodedString().urlEncodeSlash.jsonDescription)") }
      }.mapError { PNError.requestCreationFailure(.jsonStringCodingFailure(message, dueTo: $0), endpoint) }
    }
    return message.jsonStringifyResult
      .map { "\(partialPath)\($0.urlEncodeSlash)" }
      .mapError { PNError.requestCreationFailure(.jsonStringCodingFailure(message, dueTo: $0), endpoint) }
  }

  func parsePublish(
    query: inout [URLQueryItem],
    shouldStore: Bool?,
    ttl: Int?,
    meta: AnyJSON?
  ) -> Result<[URLQueryItem], Error> {
    query.appendIfPresent(key: .store, value: shouldStore?.stringNumber)
    query.appendIfPresent(key: .ttl, value: ttl?.description)

    if let meta = meta, !meta.isEmpty {
      do {
        try query.append(URLQueryItem(key: .meta, value: meta.jsonStringifyResult.get()))
        return .success(query)
      } catch {
        return .failure(PNError.requestCreationFailure(.jsonStringCodingFailure(meta, dueTo: error), endpoint))
      }
    }

    return .success(query)
  }

  func parseState<T>(query: inout [URLQueryItem], state: T?) -> Result<[URLQueryItem], Error> {
    if let state = state {
      let stateJson = AnyJSON(state)
      do {
        try query.append(URLQueryItem(key: .state, value: stateJson.jsonStringifyResult.get()))
        return .success(query)
      } catch {
        return .failure(PNError.requestCreationFailure(.jsonStringCodingFailure(stateJson, dueTo: error), endpoint))
      }
    }

    return .success(query)
  }
}

// swiftlint:disable:next file_length
// swiftlint:enable discouraged_optional_boolean
