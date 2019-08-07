//
//  GenericServicePayloadResponse.swift
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

struct GenericServiceResponseDecoder: ResponseDecoder {
  func decode(response: Response<Data>) -> Result<Response<GenericServicePayloadResponse>, Error> {
    do {
      let decodedPayload = try Constant.jsonDecoder.decode(GenericServicePayloadResponse.self, from: response.payload)

      let decodedResponse = Response<GenericServicePayloadResponse>(router: response.router,
                                                                    request: response.request,
                                                                    response: response.response,
                                                                    data: response.data,
                                                                    payload: decodedPayload)

      return .success(decodedResponse)
    } catch {
      return .failure(PNError
        .endpointFailure(.jsonDataDecodeFailure(response.data, with: error),
                         forRequest: response.request,
                         onResponse: response.response))
    }
  }

  func decodeError(request: URLRequest, response: HTTPURLResponse, for data: Data?) -> PNError? {
    // Attempt to decode based on general system response payload
    if let data = data,
      let generalErrorPayload = try? Constant.jsonDecoder.decode(GenericServicePayloadResponse.self, from: data) {
      let pnError = PNError.convert(generalError: generalErrorPayload,
                                    request: request,
                                    response: response)

      return pnError
    }

    return nil
  }
}

struct AnyJSONResponseDecoder: ResponseDecoder {
  func decode(response: Response<Data>) -> Result<Response<AnyJSON>, Error> {
    do {
      let decodedPayload = try Constant.jsonDecoder.decode(AnyJSON.self, from: response.payload)

      let decodedResponse = Response<AnyJSON>(router: response.router,
                                              request: response.request,
                                              response: response.response,
                                              data: response.data,
                                              payload: decodedPayload)

      return .success(decodedResponse)
    } catch {
      return .failure(PNError
        .endpointFailure(.jsonDataDecodeFailure(response.data, with: error),
                         forRequest: response.request,
                         onResponse: response.response))
    }
  }
}

public struct GenericServicePayloadResponse: Codable, Hashable {
  public enum Message: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    case acknowledge
    case couldNotParseRequest
    case invalidCharacter
    case invalidSubscribeKey
    case invalidPublishKey
    case invalidJSON
    case maxChannelGroupCountExceeded
    case notFound
    case requestURITooLong
    case unknown(message: String)

    public init(rawValue: String) {
      switch rawValue {
      case "OK":
        self = .acknowledge
      case "Could Not Parse Request":
        self = .couldNotParseRequest
      case "Reserved character in input parameters.":
        self = .invalidCharacter
      case "Invalid Subscribe Key":
        self = .invalidSubscribeKey
      case "Invalid Key":
        self = .invalidPublishKey
      case "Invalid JSON":
        self = .invalidJSON
      case "Maximum channel group count exceeded.":
        self = .maxChannelGroupCountExceeded
      case "Request URI Too Long":
        self = .requestURITooLong
      default:
        if rawValue.starts(with: "Not Found ") {
          self = .notFound
        }

        self = .unknown(message: rawValue)
      }
    }

    public var rawValue: String {
      switch self {
      case .acknowledge:
        return "OK"
      case .couldNotParseRequest:
        return "Could Not Parse Request"
      case .invalidCharacter:
        return "Reserved character in input parameters."
      case .invalidSubscribeKey:
        return "Invalid Subscribe Key"
      case .invalidPublishKey:
        return "Invalid Publish Key"
      case .invalidJSON:
        return "Invalid JSON"
      case .maxChannelGroupCountExceeded:
        return "Maximum channel group count exceeded."
      case .notFound:
        return "Resource Not Found"
      case .requestURITooLong:
        return "Request URI Too Long"
      case let .unknown(message):
        return "Unknown: \(message)"
      }
    }

    public init(stringLiteral value: String) {
      self.init(rawValue: value)
    }
  }

  public enum Service: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    case accessManager
    case balancer
    case presence
    case publish
    case channelGroups
    case unknown(message: String)

    public init(rawValue: String) {
      switch rawValue {
      case "Access Manager":
        self = .accessManager
      case "Balancer":
        self = .balancer
      case "Presence":
        self = .presence
      case "Publish":
        self = .publish
      case "channel-registry":
        self = .channelGroups
      default:
        self = .unknown(message: rawValue)
      }
    }

    public var rawValue: String {
      switch self {
      case .accessManager:
        return "Access Manager"
      case .balancer:
        return "Balancer"
      case .presence:
        return "Presence"
      case .publish:
        return "Publish"
      case .channelGroups:
        return "channel-registry"
      case let .unknown(message):
        return "Unknown: \(message)"
      }
    }

    public init(stringLiteral value: String) {
      self.init(rawValue: value)
    }
  }

  public enum Code: RawRepresentable, Codable, Hashable, ExpressibleByIntegerLiteral {
    case acknowledge
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case uriTooLong
    case malformedFilterExpression
    case internalServiceError
    case unknown(code: Int)

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
      case 414:
        self = .uriTooLong
      case 481:
        self = .malformedFilterExpression
      case 500:
        self = .internalServiceError
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
      case .unauthorized:
        return 401
      case .forbidden:
        return 403
      case .notFound:
        return 404
      case .uriTooLong:
        return 414
      case .malformedFilterExpression:
        return 481
      case .internalServiceError:
        return 500
      case let .unknown(code):
        return code
      }
    }

    public init(integerLiteral value: Int) {
      self.init(rawValue: value)
    }
  }

  public let message: Message
  public let service: Service
  public let status: Code
  public let error: Bool
}
