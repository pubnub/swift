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

/// Service on the `Endpoint` responsible for processing request
public enum EndpointResponseService: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
  case accessManager
  case balancer
  case channelGroups
  case objects
  case presence
  case publish
  case push
  case unknown(message: String)

  public init(rawValue: String) {
    switch rawValue {
    case "Access Manager":
      self = .accessManager
    case "Balancer":
      self = .balancer
    case "channel-registry":
      self = .channelGroups
    case "objects":
      self = .objects
    case "Presence":
      self = .presence
    case "Publish":
      self = .publish
    case "Push":
      self = .push

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
    case .channelGroups:
      return "channel-registry"
    case .objects:
      return "Objects"
    case .presence:
      return "Presence"
    case .publish:
      return "Publish"
    case .push:
      return "Push"
    case let .unknown(message):
      return "Unknown: \(message)"
    }
  }

  public init(stringLiteral value: String) {
    self.init(rawValue: value)
  }
}

/// The codified message returned by the `Endpoint`
public enum EndpointResponseMessage: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
  case acknowledge
  case badRequest
  case conflict
  case couldNotParseRequest
  case forbidden
  case internalServiceError
  case invalidArguments
  case invalidCharacter
  case invalidDeviceToken
  case invalidSubscribeKey
  case invalidPublishKey
  case invalidJSON
  case maxChannelGroupCountExceeded
  case notFound
  case preconditionFailed
  case pushNotEnabled
  case messageHistoryNotEnabled
  case messageDeletionNotEnabled
  case requestURITooLong
  case serviceUnavailable
  case tooManyRequests
  case unsupportedType
  case unknown(message: String)

  // swiftlint:disable:next cyclomatic_complexity function_body_length
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
    case "Request payload contained invalid input.":
      self = .badRequest
    case "Supplied authorization key does not have the permissions required to perform this operation.":
      self = .forbidden
    case "Requested object was not found.":
      self = .notFound
    case "Object with the requested identifier already exists.":
      self = .conflict
    case "Object already changed by another request since last retrieval.":
      self = .preconditionFailed
    case "Request payload must be in JSON format.":
      self = .unsupportedType
    case "You have exceeded the maximum number of requests per second allowed for your subscriber key.":
      self = .tooManyRequests
    case "An unexpected error ocurred while processing the request.":
      self = .internalServiceError
    case "The server took longer to respond than the maximum allowed processing time.":
      self = .serviceUnavailable
    default:
      self = EndpointResponseMessage.rawValueStartsWith(rawValue)
    }
  }

  static func rawValueStartsWith(_ message: String) -> EndpointResponseMessage {
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
    case .badRequest:
      return "Request payload contained invalid input."
    case .conflict:
      return "Object with the requested identifier already exists."
    case .couldNotParseRequest:
      return "Could Not Parse Request"
    case .forbidden:
      return "Supplied authorization key does not have the permissions required to perform this operation."
    case .internalServiceError:
      return "An unexpected error ocurred while processing the request."
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
      return "Requested object was not found."
    case .preconditionFailed:
      return "Object already changed by another request since last retrieval."
    case .pushNotEnabled:
      return ErrorDescription.EndpointFailureReason.pushNotEnabled
    case .messageHistoryNotEnabled:
      return ErrorDescription.EndpointFailureReason.messageHistoryNotEnabled
    case .messageDeletionNotEnabled:
      return ErrorDescription.EndpointFailureReason.messageDeletionNotEnabled
    case .requestURITooLong:
      return "Request URI Too Long"
    case .serviceUnavailable:
      return "The server took longer to respond than the maximum allowed processing time."
    case .tooManyRequests:
      return "You have exceeded the maximum number of requests per second allowed for your subscriber key."
    case .unsupportedType:
      return "Request payload must be in JSON format."
    case let .unknown(message):
      return "Unknown: \(message)"
    }
  }

  var knownFailureReason: PNError.EndpointFailureReason? {
    switch self {
    case .unknown:
      return nil
    default:
      return endpointFailureReason
    }
  }

  var endpointFailureReason: PNError.EndpointFailureReason? {
    switch self {
    case .couldNotParseRequest:
      return .couldNotParseRequest
    case .forbidden:
      return .forbidden
    case .invalidArguments:
      return .invalidArguments
    case .invalidCharacter:
      return .invalidCharacter
    case .invalidDeviceToken:
      return .invalidDeviceToken
    case .invalidSubscribeKey:
      return .invalidSubscribeKey
    case .invalidPublishKey:
      return .invalidPublishKey
    case .invalidJSON:
      return .requestContainedInvalidJSON
    case .maxChannelGroupCountExceeded:
      return .maxChannelGroupCountExceeded
    case .messageHistoryNotEnabled:
      return .messageHistoryNotEnabled
    case .messageDeletionNotEnabled:
      return .messageDeletionNotEnabled
    case .notFound:
      return .resourceNotFound
    case .pushNotEnabled:
      return .pushNotEnabled
    case .requestURITooLong:
      return .requestURITooLong
    case .serviceUnavailable:
      return .serviceUnavailable
    case .badRequest:
      return .badRequest
    case .conflict:
      return .conflict
    case .internalServiceError:
      return .internalServiceError
    case .preconditionFailed:
      return .preconditionFailed
    case .tooManyRequests:
      return .tooManyRequests
    case .unsupportedType:
      return .unsupportedType
    case let .unknown(message):
      return .unknown(message)
    case .acknowledge:
      return nil
    }
  }

  public init(stringLiteral value: String) {
    self.init(rawValue: value)
  }
}

public struct GenericServicePayloadResponse: Codable, Hashable {
  public let message: EndpointResponseMessage
  public let details: [ErrorDetail]
  public let service: EndpointResponseService
  public let status: HTTPStatus
  public let error: Bool
  public let channels: [String: [String]]

  public init(
    message: EndpointResponseMessage? = nil,
    details: [ErrorDetail] = [],
    service: EndpointResponseService? = nil,
    status: HTTPStatus? = nil,
    error: Bool = false,
    channels: [String: [String]] = [:]
  ) {
    if !error, status == .some(.acknowledge) {
      self.message = .acknowledge
    } else {
      self.message = message ?? "No Message Provided"
    }

    self.details = details
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
    let errorMessage = try container.decodeIfPresent(EndpointResponseMessage.self, forKey: .errorMessage)
    let message = try errorMessage ?? container.decodeIfPresent(EndpointResponseMessage.self, forKey: .message)

    // Sometimes payload can be {"error": "Error Message"}
    let error: EndpointResponseMessage?
    var details: [ErrorDetail] = []
    let isError: Bool
    let service: EndpointResponseService?
    // Use `decodeIfPresent` because it can sometiems be a Bool
    if let errorPayload = try? container.decodeIfPresent(ErrorPayload.self, forKey: .error) {
      error = errorPayload.message
      service = errorPayload.source
      details = errorPayload.details
      isError = true
    } else if let errorAsMessage = try? container.decodeIfPresent(EndpointResponseMessage.self, forKey: .error) {
      service = try container.decodeIfPresent(EndpointResponseService.self, forKey: .service)
      error = errorAsMessage
      isError = true
    } else {
      service = try container.decodeIfPresent(EndpointResponseService.self, forKey: .service)
      error = nil
      isError = try container.decodeIfPresent(Bool.self, forKey: .error) ?? false
    }

    let status = try container.decodeIfPresent(HTTPStatus.self, forKey: .status)
    let channels = try container.decodeIfPresent([String: [String]].self, forKey: .channels) ?? [:]

    self.init(message: message ?? error,
              details: details,
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

  public var endpointFailureReasson: PNError.EndpointFailureReason? {
    return message.endpointFailureReason ?? status.endpointFailureReason
  }
}

// MARK: - Object Error Response

struct ErrorPayload: Codable {
  let message: EndpointResponseMessage
  let source: EndpointResponseService
  let details: [ErrorDetail]
}

public struct ErrorDetail: Codable, Hashable {
  let message: String
  let location: String
  let locationType: String

  // swiftlint:disable:next file_length
}
