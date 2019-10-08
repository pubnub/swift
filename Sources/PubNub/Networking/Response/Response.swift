//
//  Response.swift
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

public struct Response<Value> {
  public let router: Router
  public let request: URLRequest
  public let response: HTTPURLResponse
  public let data: Data?

  public let payload: Value
}

extension Response {
  var endpoint: Endpoint {
    return router.endpoint
  }

  public func copy<T>(with value: T) -> Response<T> {
    return Response<T>(router: router, request: request, response: response, data: data, payload: value)
  }

  public func map<T>(_ transform: (Value) -> T) -> Response<T> {
    return Response<T>(router: router,
                       request: request,
                       response: response,
                       data: data,
                       payload: transform(payload))
  }
}

extension Response where Value == Data {
  init(router: Router, request: URLRequest, response: HTTPURLResponse, payload: Data) {
    self.router = router
    self.request = request
    self.response = response
    data = payload
    self.payload = payload
  }
}

public enum HTTPStatus: RawRepresentable, Codable, Hashable, ExpressibleByIntegerLiteral, CustomStringConvertible {
  case acknowledge
  case badRequest
  case conflict
  case unauthorized
  case forbidden
  case notFound
  case unsupportedType
  case requestURITooLong
  case malformedFilterExpression
  case internalServiceError
  case serviceUnavailable
  case tooManyRequests
  case preconditionFailed
  case unknown(code: Int)

  // swiftlint:disable:next cyclomatic_complexity
  public init(rawValue: Int) {
    switch rawValue {
    case 200:
      self = .acknowledge
    case 400:
      self = .badRequest
    case 401:
      self = .unauthorized
    case 403:
      self = .forbidden
    case 404:
      self = .notFound
    case 409:
      self = .conflict
    case 412:
      self = .preconditionFailed
    case 414:
      self = .requestURITooLong
    case 415:
      self = .unsupportedType
    case 429:
      self = .tooManyRequests
    case 481:
      self = .malformedFilterExpression
    case 500:
      self = .internalServiceError
    case 503:
      self = .serviceUnavailable
    default:
      self = .unknown(code: rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .acknowledge:
      return 200
    case .badRequest:
      return 400
    case .conflict:
      return 409
    case .unauthorized:
      return 401
    case .forbidden:
      return 403
    case .notFound:
      return 404
    case .preconditionFailed:
      return 412
    case .requestURITooLong:
      return 414
    case .unsupportedType:
      return 415
    case .tooManyRequests:
      return 429
    case .malformedFilterExpression:
      return 481
    case .internalServiceError:
      return 500
    case .serviceUnavailable:
      return 503
    case let .unknown(code):
      return code
    }
  }

  public var description: String {
    switch self {
    case .acknowledge:
      return EndpointResponseMessage.acknowledge.rawValue
    case .badRequest:
      return EndpointResponseMessage.badRequest.rawValue
    case .conflict:
      return EndpointResponseMessage.conflict.rawValue
    case .unauthorized:
      return "Unauthenticated/Unauthorized"
    case .forbidden:
      return EndpointResponseMessage.forbidden.rawValue
    case .notFound:
      return EndpointResponseMessage.notFound.rawValue
    case .unsupportedType:
      return EndpointResponseMessage.unsupportedType.rawValue
    case .requestURITooLong:
      return EndpointResponseMessage.requestURITooLong.rawValue
    case .malformedFilterExpression:
      return "Malformed Filter Expression"
    case .internalServiceError:
      return EndpointResponseMessage.internalServiceError.rawValue
    case .serviceUnavailable:
      return EndpointResponseMessage.serviceUnavailable.rawValue
    case .tooManyRequests:
      return EndpointResponseMessage.tooManyRequests.rawValue
    case .preconditionFailed:
      return EndpointResponseMessage.preconditionFailed.rawValue
    case let .unknown(code):
      return "Unknown match for status code: \(code)"
    }
  }

  var endpointFailureReason: PNError.EndpointFailureReason? {
    switch self {
    case .acknowledge:
      return nil
    case .badRequest:
      return .badRequest
    case .conflict:
      return .conflict
    case .unauthorized:
      return .unauthorized
    case .forbidden:
      return .forbidden
    case .notFound:
      return .resourceNotFound
    case .unsupportedType:
      return .unsupportedType
    case .requestURITooLong:
      return .requestURITooLong
    case .malformedFilterExpression:
      return .malformedFilterExpression
    case .internalServiceError:
      return .internalServiceError
    case .serviceUnavailable:
      return .serviceUnavailable
    case .tooManyRequests:
      return .tooManyRequests
    case .preconditionFailed:
      return .preconditionFailed
    case .unknown:
      return .unknown(self.description)
    }
  }

  public init(integerLiteral value: Int) {
    self.init(rawValue: value)
  }
}
