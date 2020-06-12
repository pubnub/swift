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

/// The codified message returned by the `Endpoint`
enum EndpointResponseMessage: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
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
  case multiplexingNotEnabled
  case requestURITooLong
  case serviceUnavailable
  case tooManyRequests
  case unsupportedType
  case messageTooLong
  case successFailedToPublishEvent
  case invalidUUID
  case nothingToDelete
  case unknown(message: String)

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  public init(rawValue: String) {
    switch rawValue {
    case "OK":
      self = .acknowledge
    case "Could Not Parse Request":
      self = .couldNotParseRequest
    case "Forbidden",
         "Supplied authorization key does not have the permissions required to perform this operation.":
      self = .forbidden
    case "Invalid Arguments":
      self = .invalidArguments
    case "Reserved character in input parameters.":
      self = .invalidCharacter
    case "Expected 32 or 100 byte hex device token":
      self = .invalidDeviceToken
    case "Invalid Subscribe Key", "Invalid Subkey":
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
    case "Requested object was not found.":
      self = .notFound
    case "Object with the requested identifier already exists.", "Action Already Added":
      self = .conflict
    case "Object already changed by another request since last retrieval.":
      self = .preconditionFailed
    case "Request payload must be in JSON format.":
      self = .unsupportedType
    case "You have exceeded the maximum number of requests per second allowed for your subscriber key.":
      self = .tooManyRequests
    case "Too many requests.":
      self = .internalServiceError
    case "The server took longer to respond than the maximum allowed processing time.":
      self = .serviceUnavailable
    case "Message Too Large", "Signal size too large":
      self = .messageTooLong
    case "Stored but failed to publish message action.", "Deleted but failed to publish removed events.":
      self = .successFailedToPublishEvent
    case "Not deleting message action: wrong uuid specified":
      self = .invalidUUID
    case "No matching message actions to delete":
      self = .nothingToDelete
    case "Multiplexing not enabled":
      self = .multiplexingNotEnabled
    default:
      self = EndpointResponseMessage.rawValueStartsWith(rawValue)
    }
  }

  static func rawValueStartsWith(_ message: String) -> EndpointResponseMessage {
    if message.starts(with: "Not Found ") {
      return .notFound
    } else if message.starts(with: ErrorDescription.pushNotEnabled) {
      return .pushNotEnabled
    } else if message.starts(with: ErrorDescription.messageDeletionNotEnabled) {
      return .messageDeletionNotEnabled
    } else if message.starts(with: ErrorDescription.messageHistoryNotEnabled) {
      return .messageHistoryNotEnabled
    } else {
      return .unknown(message: message)
    }
  }

  var rawValue: String {
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
      return ErrorDescription.pushNotEnabled
    case .messageHistoryNotEnabled:
      return ErrorDescription.messageHistoryNotEnabled
    case .messageDeletionNotEnabled:
      return ErrorDescription.messageDeletionNotEnabled
    case .multiplexingNotEnabled:
      return "Multiplexing not enabled"
    case .requestURITooLong:
      return "Request URI Too Long"
    case .serviceUnavailable:
      return "The server took longer to respond than the maximum allowed processing time."
    case .tooManyRequests:
      return "You have exceeded the maximum number of requests per second allowed for your subscriber key."
    case .unsupportedType:
      return "Request payload must be in JSON format."
    case .messageTooLong:
      return "Message Too Large"
    case .successFailedToPublishEvent:
      return "Stored but failed to publish message action."
    case .invalidUUID:
      return "Not deleting message action: wrong uuid specified"
    case .nothingToDelete:
      return "No matching message actions to delete"
    case let .unknown(message):
      return "Unknown: \(message)"
    }
  }

  init(stringLiteral value: String) {
    self.init(rawValue: value)
  }
}

struct GenericServicePayloadResponse: Codable, Hashable {
  let message: EndpointResponseMessage
  let details: [ErrorDetail]
  let service: String
  let status: Int
  let error: Bool
  let channels: [String: [String]]

  init(
    message: EndpointResponseMessage? = nil,
    details: [ErrorDetail] = [],
    service: String? = nil,
    status: Int? = nil,
    error: Bool = false,
    channels: [String: [String]] = [:]
  ) {
    if !error, HTTPURLResponse.successfulStatusCodes.contains(status ?? 0) {
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

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Different 'error message' response structures
    let errorMessage = try container.decodeIfPresent(EndpointResponseMessage.self, forKey: .errorMessage)
    let message = try errorMessage ?? container.decodeIfPresent(EndpointResponseMessage.self, forKey: .message)

    // Sometimes payload can be {"error": "Error Message"}
    let error: EndpointResponseMessage?
    var details: [ErrorDetail] = []
    let isError: Bool
    let service: String?
    // Use `decodeIfPresent` because it can sometiems be a Bool
    if let errorPayload = try? container.decodeIfPresent(ErrorPayload.self, forKey: .error) {
      error = errorPayload.message
      service = errorPayload.source
      details = errorPayload.details
      isError = true
    } else if let errorAsMessage = try? container.decodeIfPresent(EndpointResponseMessage.self, forKey: .error) {
      service = try container.decodeIfPresent(String.self, forKey: .service)
      error = errorAsMessage
      isError = true
    } else {
      service = try container.decodeIfPresent(String.self, forKey: .service)
      error = nil
      isError = try container.decodeIfPresent(Bool.self, forKey: .error) ?? false
    }

    let status = try container.decodeIfPresent(Int.self, forKey: .status)
    let channels = try container.decodeIfPresent([String: [String]].self, forKey: .channels) ?? [:]

    self.init(message: message ?? error,
              details: details,
              service: service,
              status: status,
              error: isError,
              channels: channels)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(message.rawValue, forKey: .message)
    try container.encode(service, forKey: .service)
    try container.encode(status, forKey: .status)
    try container.encode(error, forKey: .error)
    try container.encode(channels, forKey: .channels)
  }

  var pubnubReason: PubNubError.Reason? {
    if message.pubnubReason == .some(.unknown) {
      return PubNubError.Reason(rawValue: status)
    }
    return message.pubnubReason ?? PubNubError.Reason(rawValue: status)
  }
}

// MARK: - Object Error Response

struct ErrorPayload: Codable, Hashable {
  let message: EndpointResponseMessage
  let source: String
  let details: [ErrorDetail]

  init(message: EndpointResponseMessage, source: String, details: [ErrorDetail] = []) {
    self.message = message
    self.source = source
    self.details = details
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    message = try container.decode(EndpointResponseMessage.self, forKey: .message)
    source = try container.decode(String.self, forKey: .source)
    details = try container.decodeIfPresent([ErrorDetail].self, forKey: .details) ?? []
  }
}

struct ErrorDetail: Codable, Hashable, CustomStringConvertible {
  let message: String
  let location: String
  let locationType: String

  var description: String {
    return message
  }
}
