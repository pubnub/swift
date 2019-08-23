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
  var subscribeKey: String? { get }
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
  public var urlScheme: String {
    return useSecureConnections ? "https" : "http"
  }

  public var subscribeKeyExists: Bool {
    guard let subscribeKey = subscribeKey, !subscribeKey.isEmpty else {
      return false
    }
    return true
  }

  public var publishKeyExists: Bool {
    guard let publishKey = publishKey, !publishKey.isEmpty else {
      return false
    }
    return true
  }
}

extension PubNubConfiguration: RouterConfiguration {}

public enum PNKeyRequirement: String {
  public enum Contract {
    case none
    case publish(String)
    case subscribe(String)
    case publishAndSubscribe(publish: String, subscribe: String)
  }

  case none = "None"
  case publish = "Publish"
  case subscribe = "Subscribe"
  case publishAndSubscribe = "Publish & Subscribe"
}

public enum PAMVersionRequirement {
  case none
  case version2
  case version3
}

// public typealias HTTPHeaders = [String: String]

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

// MARK: - Router

public protocol Router: URLRequestConvertible, CustomStringConvertible, Validated {
  var endpoint: Endpoint { get }
  var configuration: RouterConfiguration { get }
  var method: HTTPMethod { get }
  var path: Result<String, Error> { get }
  var queryItems: Result<[URLQueryItem], Error> { get }
  var additionalHeaders: HTTPHeaders { get }
  var body: Result<Data?, Error> { get }

  var keysRequired: PNKeyRequirement { get }
  var pamVersion: PAMVersionRequirement { get }

  func decode<D: ResponseDecoder>(response: Response<Data>, decoder: D) -> Result<Response<D.Payload>, Error>
  func decodeError(endpoint: Endpoint, request: URLRequest, response: HTTPURLResponse, for data: Data?) -> PNError?
}

extension Router {
  // Default Protocol Implementation
  func decode<D: ResponseDecoder>(response: Response<Data>, decoder: D) -> Result<Response<D.Payload>, Error> {
    return decoder.decode(response: response)
  }

  // Default Endpoint Values
  public var defaultQueryItems: [URLQueryItem] {
    var queryItems = [
      Constant.pnSDKURLQueryItem,
      URLQueryItem(name: "uuid", value: configuration.uuid)
    ]
    if pamVersion != .none, let authKey = configuration.authKey {
      queryItems.append(URLQueryItem(name: "auth", value: authKey))
    }
    return queryItems
  }

  // Endpoint Validators
  public var keyValidationError: PNError? {
    switch keysRequired {
    case .none:
      return nil

    case .subscribe:
      if configuration.subscribeKeyExists {
        return nil
      }
      return .requestCreationFailure(.missingSubscribeKey, endpoint)

    case .publish:
      if configuration.publishKeyExists {
        return nil
      }
      return .requestCreationFailure(.missingPublishKey, endpoint)

    case .publishAndSubscribe:
      switch (configuration.publishKeyExists, configuration.subscribeKeyExists) {
      case (false, false):
        return .requestCreationFailure(.missingPublishAndSubscribeKey, endpoint)
      case (true, false):
        return .requestCreationFailure(.missingSubscribeKey, endpoint)
      case (false, true):
        return .requestCreationFailure(.missingPublishKey, endpoint)
      case (true, true):
        return nil
      }
    }
  }

  var validationError: Error? {
    if let invalidKeysError = keyValidationError {
      return invalidKeysError
    } else if let endpointValidationError = endpoint.validationError {
      return endpointValidationError
    }
    return nil
  }
}

// MARK: - URLRequestConvertible

extension Router {
  public var asURL: Result<URL, Error> {
    if let error = validationError {
      return .failure(error)
    }

    return path.flatMap { path -> Result<URLComponents, Error> in
      var urlComponents = URLComponents()
      urlComponents.scheme = configuration.urlScheme
      urlComponents.host = configuration.origin

      urlComponents.path = path
      // URL will double encode our attempts to sanitize '/' inside path inputs
      urlComponents.percentEncodedPath = urlComponents.percentEncodedPath
        .replacingOccurrences(of: "%252F", with: "%2F")

      urlComponents.queryItems = defaultQueryItems

      do {
        try urlComponents.queryItems?.append(contentsOf: queryItems.get())
        // URL will not encode `+`, so we will do it manually
        urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?
          .replacingOccurrences(of: "+", with: "%2B")
      } catch {
        return .failure(error)
      }
      return .success(urlComponents)
    }.mapError { error in
      if error.pubNubError != nil {
        return error
      } else {
        return PNError.requestCreationFailure(.unknown(error), endpoint)
      }
    }.flatMap { $0.asURL }
  }

  public var asURLRequest: Result<URLRequest, Error> {
    return asURL.flatMap { url -> Result<URLRequest, Error> in
      var request = URLRequest(url: url)
      request.headers = additionalHeaders
      request.httpMethod = method.rawValue
      return body.flatMap { data in
        request.httpBody = data
        return .success(request)
      }
    }
  }
}

// MARK: - CustomStringConvertible

extension Router {
  public var description: String {
    return String(describing: Self.self)
  }
}
