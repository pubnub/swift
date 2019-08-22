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
  typealias Payload = GenericServicePayloadResponse
}

struct AnyJSONResponseDecoder: ResponseDecoder {
  typealias Payload = AnyJSON
}

// MARK: - Response Body

// swiftlint:disable:next type_body_length
public struct GenericServicePayloadResponse: Codable, Hashable {
  public enum Message: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    case acknowledge
    case couldNotParseRequest
    case forbidden
    case invalidArguments
    case invalidCharacter
    case invalidDeviceToken
    case invalidSubscribeKey
    case invalidPublishKey
    case invalidJSON
    case maxChannelGroupCountExceeded
    case notFound
    case pushNotEnabled
    case messageHistoryNotEnabled
    case messageDeletionNotEnabled
    case requestURITooLong
    case serviceUnavailable
    case unknown(message: String)

    // swiftlint:disable:next cyclomatic_complexity
    public init(rawValue: String) {
      switch rawValue {
      case "OK":
        self = .acknowledge
      case "Could Not Parse Request":
        self = .couldNotParseRequest
      case "Forbidden":
        self = .forbidden
      case "Invalid Arguments":
        self = .invalidArguments
      case "Reserved character in input parameters.":
        self = .invalidCharacter
      case "Expected 32 or 100 byte hex device token":
        self = .invalidDeviceToken
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
      case "Service Unavailable":
        self = .serviceUnavailable
      default:
        self = Message.rawValueStartsWith(rawValue)
      }
    }

    static func rawValueStartsWith(_ message: String) -> Message {
      if message.starts(with: "Not Found ") {
        return .notFound
      } else if message.starts(with: ErrorDescription.EndpointFailureReason.pushNotEnabled) {
        return .pushNotEnabled
      } else if message.starts(with: ErrorDescription.EndpointFailureReason.messageDeletionNotEnabled) {
        return .messageDeletionNotEnabled
      } else if message.starts(with: ErrorDescription.EndpointFailureReason.messageHistoryNotEnabled) {
        return .messageHistoryNotEnabled
      } else {
        return .unknown(message: message)
      }
    }

    public var rawValue: String {
      switch self {
      case .acknowledge:
        return "OK"
      case .couldNotParseRequest:
        return "Could Not Parse Request"
      case .forbidden:
        return "Forbidden"
      case .invalidArguments:
        return "Invalid Arguments"
      case .invalidCharacter:
        return "Reserved character in input parameters."
      case .invalidDeviceToken:
        return "Expected 32 or 100 byte hex device token"
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
      case .pushNotEnabled:
        return ErrorDescription.EndpointFailureReason.pushNotEnabled
      case .messageHistoryNotEnabled:
        return ErrorDescription.EndpointFailureReason.messageHistoryNotEnabled
      case .messageDeletionNotEnabled:
        return ErrorDescription.EndpointFailureReason.messageDeletionNotEnabled
      case .requestURITooLong:
        return "Request URI Too Long"
      case .serviceUnavailable:
        return "Service Unavailable"
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
    case push
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
      case "Push":
        self = .push
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
      case .push:
        return "Push"
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
    case serviceUnavailable
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
      case 504:
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
      case .serviceUnavailable:
        return 504
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
  public let channels: [String: [String]]

  public init(
    message: Message? = nil,
    service: Service? = nil,
    status: Code? = nil,
    error: Bool = false,
    channels: [String: [String]] = [:]
  ) {
    if !error, status == .some(.acknowledge) {
      self.message = .acknowledge
    } else {
      self.message = message ?? "No Message Provided"
    }

    self.service = service ?? "No Service Provided"
    self.status = status ?? -1
    self.error = error
    self.channels = channels
  }

  enum CodingKeys: String, CodingKey {
    case errorMessage = "error_message"
    case message
    case service
    case status
    case error
    case channels
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Different 'error message' response structures
    let errorMessage = try container.decodeIfPresent(Message.self, forKey: .errorMessage)
    let message = try errorMessage ?? container.decodeIfPresent(Message.self, forKey: .message)

    // Sometimes payload can be {"error": "Error Message"}
    let error: Message?
    let isError: Bool
    // Use `decodeIfPresent` because it can sometiems be a Bool
    if let errorAsMessage = try? container.decodeIfPresent(Message.self, forKey: .error) {
      error = errorAsMessage
      isError = true
    } else {
      error = nil
      isError = try container.decodeIfPresent(Bool.self, forKey: .error) ?? false
    }

    let service = try container.decodeIfPresent(Service.self, forKey: .service)
    let status = try container.decodeIfPresent(Code.self, forKey: .status)
    let channels = try container.decodeIfPresent([String: [String]].self, forKey: .channels) ?? [:]

    self.init(message: message ?? error,
              service: service,
              status: status,
              error: isError,
              channels: channels)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(message.rawValue, forKey: .message)
    try container.encode(service.rawValue, forKey: .service)
    try container.encode(status.rawValue, forKey: .status)
    try container.encode(error, forKey: .error)
    try container.encode(channels, forKey: .channels)
  }
}
