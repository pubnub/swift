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

  let configuration: RouterConfiguration
  let endpoint: Endpoint
}

extension PubNubRouter: Router {
  var method: HTTPMethod {
    switch endpoint {
    case .time:
      return .get
    case .publish:
      return .get
    case .compressedPublish:
      return .post
    case .fire:
      return .get
    case .subscribe:
      return .get
    }
  }

  func path() throws -> String {
    let publishKey = configuration.publishKey ?? ""
    let subscribeKey = configuration.subscribeKey ?? ""

    // General Note: Only URL Encode slashes `/` for the channel(s) in the path.
    // Everything else will be encoded by the URL object
    switch endpoint {
    case .time:
      return "/time/0"
    case let .publish(parameters):
      return try parsePublishPath(publishKey: publishKey,
                                  subscribeKey: subscribeKey,
                                  channel: parameters.channel,
                                  message: parameters.message)
    case let .compressedPublish(parameters):
      return "/publish/\(publishKey)/\(subscribeKey)/0/\(urlEncodeSlash(path: parameters.channel))/0"
    case let .fire(parameters):
      return try parsePublishPath(publishKey: publishKey,
                                  subscribeKey: subscribeKey,
                                  channel: parameters.channel,
                                  message: parameters.message)
    case let .subscribe(parameters):
      return "/v2/subscribe/\(subscribeKey)/\(urlEncodeSlash(path: parameters.channels.csvString))/0"
    }
  }

  func queryItems() throws -> [URLQueryItem] {
    var query = defaultQueryItems
    switch endpoint {
    case .time:
      break
    case let .publish(_, channel, shouldStore, ttl, meta):
      try query.append(contentsOf: parsePublishQuery(channel: channel,
                                                     shouldStore: shouldStore,
                                                     ttl: ttl,
                                                     meta: meta))
    case let .compressedPublish(_, channel, shouldStore, ttl, meta):
      try query.append(contentsOf: parsePublishQuery(channel: channel,
                                                     shouldStore: shouldStore,
                                                     ttl: ttl,
                                                     meta: meta))
    case let .fire(_, channel, meta):
      try query.append(contentsOf: parsePublishQuery(channel: channel,
                                                     shouldStore: false,
                                                     ttl: 0,
                                                     meta: meta))
      query.append(contentsOf: [
        URLQueryItem(name: noRepKey, value: "true"),
        URLQueryItem(name: storedKey, value: "0")
      ])
    case let .subscribe(parameters):
      query.append(URLQueryItem(name: timetokenKey, value: parameters.timetoken?.description ?? "0"))
      if !parameters.groups.isEmpty {
        query.append(URLQueryItem(name: channelGroupsKey, value: parameters.groups.csvString))
      }
      if let region = parameters.region {
        query.append(URLQueryItem(name: regionKey, value: region.description))
      }
    }
    return query
  }

  var additionalHeaders: HTTPHeaders {
    return [:]
  }

  var body: AnyJSON? {
    switch endpoint {
    case .time:
      return nil
    case .publish:
      return nil
    case let .compressedPublish(parameters):
      return parameters.message
    case let .fire(parameters):
      return parameters.message
    case .subscribe:
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
    case .subscribe:
      return .subscribe
    }
  }

  var pamVersion: PAMVersionRequirement {
    switch endpoint {
    case .time:
      return .none
    case .publish, .compressedPublish:
      return .version2
    case .fire:
      return .version2
    case .subscribe:
      return .version2
    }
  }
}

extension PubNubRouter {
  func parsePublishPath(publishKey: String, subscribeKey: String, channel: String, message: AnyJSON) throws -> String {
    do {
      return try "/publish/\(publishKey)/\(subscribeKey)/0/\(urlEncodeSlash(path: channel))/0/\(urlEncodeSlash(path: message.jsonString()))"
    } catch {
      let reason = PNError.RequestCreationFailureReason.jsonStringCodingFailure(message, dueTo: error)
      throw PNError.requestCreationFailure(reason)
    }
  }

  func parsePublishQuery(
    channel _: String,
    shouldStore: Bool?,
    ttl: Int?,
    meta: AnyJSON?
  ) throws -> [URLQueryItem] {
    var query = [URLQueryItem]()

    if let shouldStore = shouldStore {
      query.append(URLQueryItem(name: storedKey, value: shouldStore.stringNumber))
    }
    if let ttl = ttl {
      query.append(URLQueryItem(name: ttlKey, value: ttl.description))
    }
    if let meta = meta, !meta.isEmpty {
      do {
        try query.append(URLQueryItem(name: metaKey,
                                      value: meta.jsonString()))
      } catch {
        let reason = PNError
          .RequestCreationFailureReason
          .jsonStringCodingFailure(meta, dueTo: error)
        throw PNError.requestCreationFailure(reason)
      }
    }
    return query
  }
}

// swiftlint:enable discouraged_optional_boolean
