//
//  Router.swift
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

/// Base configuration for PubNub Endpoints
public protocol RouterConfiguration {
  /// Specifies the PubNub Publish Key to be used when publishing messages to a channel
  var publishKey: String? { get }
  /// Specifies the PubNub Subscribe Key to be used when subscribing to a channel
  var subscribeKey: String { get }
  // UUID to be used as a device identifier
  var uuid: String { get }
  /// for further details.
  var useSecureConnections: Bool { get }
  /// Domain name used for requests
  var origin: String { get }
  /// If Access Manager (PAM) is enabled, client will use `authKey` on all requests
  var authKey: String? { get }
  /// If set, all communication will be encrypted with this key
  var cipherKey: Crypto? { get }
  /// Whether a request identifier should be included on outgoing requests
  var useRequestId: Bool { get }
}

extension RouterConfiguration {
  /// The scheme used when creating the URL for the request
  public var urlScheme: String {
    return useSecureConnections ? "https" : "http"
  }

  /// True if the subscribeKey exists and is not an empty `String`
  public var subscribeKeyExists: Bool {
    return !subscribeKey.isEmpty
  }

  /// True if the publishKey exists and is not an empty `String`
  public var publishKeyExists: Bool {
    guard let publishKey = publishKey, !publishKey.isEmpty else {
      return false
    }
    return true
  }
}

extension PubNubConfiguration: RouterConfiguration {}

/// HTTP method definitions.
///
/// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum HTTPMethod: String {
  case connect = "CONNECT"
  case delete = "DELETE"
  case get = "GET"
  case head = "HEAD"
  case options = "OPTIONS"
  case patch = "PATCH"
  case post = "POST"
  case put = "PUT"
  case trace = "TRACE"
}

public enum PubNubService: String {
  case channelGroup = "Channel Group"
  case history = "History"
  case messageActions = "Message Actions"
  case objects = "Objects"
  case presence = "Presence"
  case publish = "Publish"
  case push = "Push"
  case subscribe = "Subscribe"
  case time = "Time"
  case unknown = "Unknown"
}

// MARK: - Router

/// Collects together and assembles the separate pieces used to create an URLRequest
public protocol HTTPRouter: URLRequestConvertible, Validated, CustomStringConvertible {
//  /// The target of the `URLRequest`
//  var endpoint: Endpoint { get }
  var service: PubNubService { get }
  var category: String { get }
  /// Configuration used during the URLRequest generation
  var configuration: RouterConfiguration { get }
  /// The HTTP method used on the URL
  var method: HTTPMethod { get }
  /// The path for the `URL` or the `Error` during its creation
  var path: Result<String, Error> { get }
  /// The collection of `URLQueryItem` or the `Error` during its creation
  var queryItems: Result<[URLQueryItem], Error> { get }
  /// Additional requred headers
  var additionalHeaders: [String: String] { get }
  /// The `Data` that will be put inside the request or the `Error` generate during its creation
  var body: Result<Data?, Error> { get }

  var keysRequired: PNKeyRequirement { get }

  var pamVersion: PAMVersionRequirement { get }

  /// The method called when attempting to decode the response error data for a given Endpoint
  ///
  /// Currently being used during `Request` validation
  ///
  /// - Parameters:
  ///   - endpoint: The endpoint that was requested
  ///   - request: The `URLRequest` that failed
  ///   - response: The `HTTPURLResponse` that was returned
  ///   - for: The `ResponseDecoder` used to decode the raw response data
  /// - Returns: The `PubNubError` that represents the response error
  func decodeError(request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError?
}

// Default Protocol Values
extension HTTPRouter {
  public var method: HTTPMethod { return .get }
  public var additionalHeaders: [String: String] { return [:] }
  public var body: Result<Data?, Error> { return .success(nil) }
  public var keysRequired: PNKeyRequirement { return .subscribe }
  public var pamVersion: PAMVersionRequirement { return .version2 }

  public func decodeError(request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError? {
    return AnyJSONResponseDecoder().decodeError(router: self, request: request, response: response, for: data)
  }

  var defaultQueryItems: [URLQueryItem] {
    var queryItems = [
      Constant.pnSDKURLQueryItem,
      URLQueryItem(name: "uuid", value: configuration.uuid)
    ]
    // Add PAM key if needed
    if pamVersion != .none, let authKey = configuration.authKey {
      queryItems.append(URLQueryItem(name: "auth", value: authKey))
    }

    return queryItems
  }

  public var validationError: Error? {
    if let reason = keyValidationErrorReason {
      return PubNubError(reason, router: self)
    } else if let errorDetail = validationErrorDetail {
      return PubNubError(.missingRequiredParameter, router: self, additional: [errorDetail])
    }
    return nil
  }

  var subscribeKey: String {
    return configuration.subscribeKey.urlEncodeSlash
  }

  var publishKey: String {
    return configuration.publishKey?.urlEncodeSlash ?? ""
  }

  public var keyValidationErrorReason: PubNubError.Reason? {
    switch keysRequired {
    case .none:
      return nil

    case .subscribe:
      if configuration.subscribeKeyExists {
        return nil
      }
      return .missingSubscribeKey
    case .publish:
      if configuration.publishKeyExists {
        return nil
      }
      return .missingPublishKey

    case .publishAndSubscribe:
      switch (configuration.publishKeyExists, configuration.subscribeKeyExists) {
      case (false, false):
        return .missingPublishAndSubscribeKey
      case (true, false):
        return .missingSubscribeKey
      case (false, true):
        return .missingPublishKey
      case (true, true):
        return nil
      }
    }
  }
}

// MARK: - URLRequestConvertible

extension HTTPRouter {
  public var asURL: Result<URL, Error> {
    if let error = validationError {
      return .failure(error)
    }

    return path.flatMap { path -> Result<URLComponents, Error> in
      queryItems.map { query -> URLComponents in
        var urlComponents = URLComponents()
        urlComponents.scheme = configuration.urlScheme
        urlComponents.host = configuration.origin

        urlComponents.path = path
        // URL will double encode our attempts to sanitize '/' inside path inputs
        urlComponents.percentEncodedPath = urlComponents.percentEncodedPath.decodeDoubleEncodedSlash

        urlComponents.queryItems = query

        // URL will not encode `+` or `?`, so we will do it manually
        urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?.additionalQueryEncoding

        return urlComponents
      }
    }.flatMap { $0.asURL }
  }

  public var asURLRequest: Result<URLRequest, Error> {
    return asURL.flatMap { url -> Result<URLRequest, Error> in
      body.flatMap { data in
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = additionalHeaders
        request.httpMethod = method.rawValue
        request.httpBody = data
        return .success(request)
      }
    }
  }
}

// MARK: - CustomStringConvertible

extension HTTPRouter {
  public var description: String {
    return String(describing: Self.self)
  }
}
