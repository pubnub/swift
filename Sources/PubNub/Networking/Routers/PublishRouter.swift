//
//  PublishRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Router

struct PublishRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case publish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
    case compressedPublish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
    case fire(message: AnyJSON, channel: String, meta: AnyJSON?)
    case signal(message: AnyJSON, channel: String)
    case file(message: FilePublishPayload, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)

    var description: String {
      switch self {
      case .publish:
        return "Publish"
      case .compressedPublish:
        return "Compressed Publish"
      case .fire:
        return "Fire"
      case .signal:
        return "Signal"
      case .file:
        return "Publish a File Message"
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
    return .publish
  }

  var category: String {
    return endpoint.description
  }

  var path: Result<String, Error> {
    switch endpoint {
    case let .publish(message, channel, _, _, _):
      return append(message: message,
                    to: "/publish/\(publishKey)/\(subscribeKey)/0/\(channel.urlEncodeSlash)/0/")
    case let .fire(message, channel, _):
      return append(message: message,
                    to: "/publish/\(publishKey)/\(subscribeKey)/0/\(channel.urlEncodeSlash)/0/")
    case let .compressedPublish(_, channel, _, _, _):
      return .success("/publish/\(publishKey)/\(subscribeKey)/0/\(channel.urlEncodeSlash)/0")
    case let .signal(message, channel):
      return append(message: message,
                    to: "/signal/\(publishKey)/\(subscribeKey)/0/\(channel.urlEncodeSlash)/0/")
    case let .file(message, _, _, _):
      return append(message: message,
                    to: "/v1/files/publish-file/\(publishKey)/\(subscribeKey)/0/\(message.channel.urlEncodeSlash)/0/")
    }
  }

  func append(message: JSONCodable, to partialPath: String) -> Result<String, Error> {
    if let cryptoModule = configuration.cryptoModule {
      return message.jsonDataResult.flatMap { jsonData in
        cryptoModule.encrypt(data: jsonData).mapError { $0 as Error }
          .flatMap { .success("\(partialPath)\($0.base64EncodedString().urlEncodeSlash.jsonDescription)") }
      }
    }
    return message.jsonStringifyResult.map { "\(partialPath)\($0.urlEncodeSlash)" }
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .publish(_, _, shouldStore, ttl, meta):
      return parsePublish(query: &query, store: shouldStore, ttl: ttl, meta: meta)
    case let .compressedPublish(_, _, shouldStore, ttl, meta):
      return parsePublish(query: &query, store: shouldStore, ttl: ttl, meta: meta)
    case let .fire(_, _, meta):
      return parsePublish(query: &query, store: false, ttl: 0, meta: meta)
    case .signal:
      break
    case let .file(_, shouldStore, ttl, meta):
      return parsePublish(query: &query, store: shouldStore, ttl: ttl, meta: meta)
    }

    return .success(query)
  }

  func parsePublish(query: inout [URLQueryItem], store: Bool?, ttl: Int?, meta: AnyJSON?) -> QueryResult {
    query.appendIfPresent(key: .store, value: store?.stringNumber)
    query.appendIfPresent(key: .ttl, value: ttl?.description)

    if let meta = meta, !meta.isEmpty {
      return meta.jsonStringifyResult.map { json -> [URLQueryItem] in
        query.append(URLQueryItem(key: .meta, value: json))
        return query
      }
    }
    return .success(query)
  }

  var method: HTTPMethod {
    switch endpoint {
    case .compressedPublish:
      return .post
    default:
      return .get
    }
  }

  var body: Result<Data?, Error> {
    switch endpoint {
    case let .compressedPublish(message, _, _, _, _):
      if let cryptoModule = configuration.cryptoModule {
        return message.jsonStringifyResult.flatMap {
          cryptoModule.encrypt(string: $0)
            .map { $0.jsonDescription.data(using: .utf8) }
            .mapError { $0 as Error }
        }
      }
      return message.jsonDataResult.map { .some($0) }
    default:
      return .success(nil)
    }
  }

  func decodeError(request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError? {
    return PublishResponseDecoder().decodeError(router: self, request: request, response: response, for: data)
  }

  // Validated
  var keysRequired: PNKeyRequirement {
    return .publishAndSubscribe
  }

  var validationErrorDetail: String? {
    switch endpoint {
    case let .publish(message, channel, _, _, _):
      return isInvalidForReason(
        (message.isEmpty, ErrorDescription.emptyMessagePayload),
        (channel.isEmpty, ErrorDescription.emptyChannelString)
      )
    case let .compressedPublish(message, channel, _, _, _):
      return isInvalidForReason(
        (message.isEmpty, ErrorDescription.emptyMessagePayload),
        (channel.isEmpty, ErrorDescription.emptyChannelString)
      )
    case let .fire(message, channel, _):
      return isInvalidForReason(
        (message.isEmpty, ErrorDescription.emptyMessagePayload),
        (channel.isEmpty, ErrorDescription.emptyChannelString)
      )
    case let .signal(message, channel):
      return isInvalidForReason(
        (message.isEmpty, ErrorDescription.emptyMessagePayload),
        (channel.isEmpty, ErrorDescription.emptyChannelString)
      )
    case let .file(message, _, _, _):
      return message.validationErrorDetail
    }
  }
}

// MARK: - Response Decoder

struct PublishResponseDecoder: ResponseDecoder {
  typealias Payload = PublishResponsePayload

  func decodeError(router: HTTPRouter, request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError? {
    do {
      let decodedPayload = try Constant.jsonDecoder.decode(PublishResponsePayload.self, from: data)
      let reason = EndpointResponseMessage(rawValue: decodedPayload.message).pubnubReason
      if reason == .unknown {
        return PubNubError(reason: reason, router: router, request: request, response: response,
                           additional: [ErrorDetail(message: decodedPayload.message,
                                                    location: "unknown",
                                                    locationType: "unknown")])
      }

      return PubNubError(reason: reason, router: router, request: request, response: response, additional: [])
    } catch {
      if let defaultError = decodeDefaultError(router: router, request: request, response: response, for: data) {
        return defaultError
      }
    }

    return nil
  }
}

// MARK: - Response Body

struct PublishResponsePayload: Codable, Hashable {
  let error: Int
  let message: String
  let timetoken: Timetoken

  public init(error: Int = 1, message: String = "Sent", timetoken: Timetoken) {
    self.error = error
    self.message = message
    self.timetoken = timetoken
  }

  init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()

    var optionalError: Int?
    var optionalMessage: String?
    var optionalToken: Timetoken?

    while !container.isAtEnd {
      switch container.currentIndex {
      case 0:
        optionalError = try container.decode(Int.self)
      case 1:
        optionalMessage = try container.decode(String.self)
      case 2:
        let value = try container.decode(String.self)
        optionalToken = Timetoken(value) ?? 0
      default:
        break
      }
    }

    guard let error = optionalError, let message = optionalMessage, let timetoken = optionalToken else {
      throw DecodingError
        .valueNotFound(PublishResponsePayload.self,
                       .init(codingPath: [],
                             debugDescription: PubNubError.Reason.malformedResponseBody.description))
    }

    self.error = error
    self.message = message
    self.timetoken = timetoken
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()

    try container.encode(error)
    try container.encode(message)
    try container.encode(timetoken.description)
  }
}
