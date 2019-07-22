//
//  Endpoint.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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
public protocol EndpointConfiguration {
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
}

extension EndpointConfiguration {
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

extension PubNubConfiguration: EndpointConfiguration {}

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

public protocol ResponseDecoder {
  associatedtype Payload

  func decode(response: Response<Data>, completion: (Result<Response<Payload>, Error>) -> Void)
}

public protocol Endpoint: URLRequestConvertible, CustomStringConvertible {
  var operation: PubNubOperation { get }
  var configuration: EndpointConfiguration { get }
  var method: HTTPMethod { get }
  func path() throws -> String
  var additionalHeaders: HTTPHeaders { get }
  func queryItems() throws -> [URLQueryItem]
  var body: AnyJSON? { get }

  var keysRequired: PNKeyRequirement { get }
  var pamVersion: PAMVersionRequirement { get }

  func decode<D: ResponseDecoder>(
    response: Response<Data>,
    decoder: D,
    completion: (Result<Response<D.Payload>, Error>) -> Void
  )

  func decodeError(request: URLRequest, response: HTTPURLResponse, for data: Data?) -> PNError?
}

extension Endpoint {
  // Default Protocol Implementation

  func decode<D: ResponseDecoder>(
    response: Response<Data>,
    decoder: D,
    completion: (Result<Response<D.Payload>, Error>) -> Void
  ) {
    decoder.decode(response: response, completion: completion)
  }

  func decodeError(request: URLRequest, response: HTTPURLResponse, for data: Data?) -> PNError? {
    // Attempt to decode based on general system response payload
    if let data = data,
      let generalErrorPayload = try? JSONDecoder().decode(GeneralSystemErrorPayload.self, from: data) {
      let pnError = PNError.convert(generalError: generalErrorPayload,
                                    request: request,
                                    response: response)

      return pnError
    }

    return nil
  }

  // Default Endpoint Values
  public var defaultQueryItems: [URLQueryItem] {
    var queryItems = [
      URLQueryItem(name: "pnsdk", value: StringConstant.pnSDKQueryParameterValue),
      URLQueryItem(name: "uuid", value: configuration.uuid)
    ]
    if let authKey = configuration.authKey {
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
      return .requestCreationFailure(.missingPubNubKey(.subscribe, for: operation))

    case .publish:
      if configuration.publishKeyExists {
        return nil
      }
      return .requestCreationFailure(.missingPubNubKey(.publish, for: operation))

    case .publishAndSubscribe:
      switch (configuration.publishKeyExists, configuration.subscribeKeyExists) {
      case (false, false):
        return .requestCreationFailure(
          .missingPubNubKey(.publishAndSubscribe, for: operation))
      case (true, false):
        return .requestCreationFailure(
          .missingPubNubKey(.subscribe, for: operation))
      case (false, true):
        return .requestCreationFailure(
          .missingPubNubKey(.publish, for: operation))
      case (true, true):
        return nil
      }
    }
  }
}

// MARK: - URLRequestConvertible

extension Endpoint {
  public var asURL: Result<URL, Error> {
    if let invalidKeysError = keyValidationError {
      return .failure(invalidKeysError)
    }

    var urlComponents = URLComponents()
    urlComponents.scheme = configuration.urlScheme
    urlComponents.host = configuration.origin

    do {
      urlComponents.path = try path()
      urlComponents.queryItems = try queryItems()
    } catch let error as PNError {
      return .failure(error)
    } catch {
      return .failure(PNError.requestCreationFailure(.unknown(error)))
    }

    // URL will not encode `+`, so we will do it manually
    let encodedQuery = urlComponents.percentEncodedQuery?.replacingOccurrences(of: "+",
                                                                               with: "%2B")
    urlComponents.percentEncodedQuery = encodedQuery

    return urlComponents.asURL
  }

  public var asURLRequest: Result<URLRequest, Error> {
    let requestResult = asURL.flatMap { url -> Result<URLRequest, Error> in
      var request = URLRequest(url: url)
      request.headers = additionalHeaders
      request.httpMethod = method.rawValue
      if let body = body {
        do {
          request.httpBody = try body.jsonEncodedData()
        } catch {
          return .failure(PNError
            .requestCreationFailure(
              .jsonDataCodingFailure(body, with: error)))
        }
      }
      return .success(request)
    }

    return requestResult
  }
}

// MARK: - CustomStringConvertible

extension Endpoint {
  public var description: String {
    return String(describing: Self.self)
  }
}
