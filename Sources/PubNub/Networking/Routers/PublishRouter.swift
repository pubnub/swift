//
//  PublishRouter.swift
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

struct PublishRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case publish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
    case compressedPublish(message: AnyJSON, channel: String, shouldStore: Bool?, ttl: Int?, meta: AnyJSON?)
    case fire(message: AnyJSON, channel: String, meta: AnyJSON?)
    case signal(message: AnyJSON, channel: String)

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
    case let .publish(parameters):
      return append(message: parameters.message,
                    to: "/publish/\(publishKey)/\(subscribeKey)/0/\(parameters.channel.urlEncodeSlash)/0/")
    case let .fire(parameters):
      return append(message: parameters.message,
                    to: "/publish/\(publishKey)/\(subscribeKey)/0/\(parameters.channel.urlEncodeSlash)/0/")
    case let .compressedPublish(parameters):
      return .success("/publish/\(publishKey)/\(subscribeKey)/0/\(parameters.channel.urlEncodeSlash)/0")
    case let .signal(message, channel):
      return append(message: message,
                    to: "/signal/\(publishKey)/\(subscribeKey)/0/\(channel.urlEncodeSlash)/0/")
    }
  }

  func append(message: AnyJSON, to partialPath: String) -> Result<String, Error> {
    if let crypto = configuration.cipherKey {
      return message.jsonDataResult.flatMap { jsonData in
        crypto.encrypt(utf8Encoded: jsonData)
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
    case let .compressedPublish(parameters):
      if let crypto = configuration.cipherKey {
        return parameters.message.jsonStringifyResult.flatMap {
          crypto.encrypt(plaintext: $0).map { $0.jsonDescription.data(using: .utf8) }
        }
      }
      return parameters.message.jsonDataResult.map { .some($0) }
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
    }
  }
}

// MARK: - Response Decoder

struct PublishResponseDecoder: ResponseDecoder {
  func decode(response: EndpointResponse<Data>) -> Result<EndpointResponse<PublishResponsePayload>, Error> {
    do {
      // Publish Response pattern:  [Int, String, String]
      let decodedPayload = try Constant.jsonDecoder.decode(AnyJSON.self, from: response.payload).arrayOptional

      guard let timeString = decodedPayload?.last as? String, let timetoken = Timetoken(timeString) else {
        return .failure(PubNubError(.malformedResponseBody, response: response))
      }

      let decodedResponse = EndpointResponse<PublishResponsePayload>(
        router: response.router,
        request: response.request,
        response: response.response,
        data: response.data,
        payload: PublishResponsePayload(timetoken: timetoken)
      )

      return .success(decodedResponse)
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }

  func decodeError(router: HTTPRouter, request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError? {
    // Publish Response pattern:  [Int, String, String]
    let decodedPayload = try? Constant.jsonDecoder.decode(AnyJSON.self, from: data).arrayOptional

    if let errorFlag = decodedPayload?.first as? Int, errorFlag == 0 {
      if let message = decodedPayload?[1] as? String,
        let reason = EndpointResponseMessage(rawValue: message).pubnubReason {
        return PubNubError(reason: reason, router: router, request: request, response: response)
      }
      return PubNubError(reason: .unknown, router: router, request: request, response: response)
    }

    // Check if we were provided a default error from the server
    if let defaultError = decodeDefaultError(router: router, request: request, response: response, for: data) {
      return defaultError
    }

    return nil
  }
}

// MARK: - Response Body

public struct PublishResponsePayload: Codable, Hashable {
  public let timetoken: Timetoken
}

public struct ErrorResponse: Codable, Hashable {
  public let message: String?
  public let error: Bool
  public let service: String?
  public let status: Int
}
