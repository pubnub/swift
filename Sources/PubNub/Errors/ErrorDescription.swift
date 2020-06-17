//
//  ErrorDescription.swift
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

struct ErrorDescription {
  static let stringEncodingFailure: String = {
    "`String(data:encoding:)` returned nil when converting JSON Data to a `String`"
  }()

  static let defaultRecoverySuggestion: String = {
    "No recover suggestion was provided."
  }()

  static let missingCryptoKey: String = {
    "Missing cipher key from `PubNubConfiguration`"
  }()

  static let rootLevelDecoding: String = {
    "AnyJSON could not decode invalid root-level JSON object"
  }()

  static let keyedContainerDecoding: String = {
    "AnyJSON could not decode value inside `KeyedDecodingContainer`"
  }()

  static let unkeyedContainerDecoding: String = {
    "AnyJSON could not decode value inside `UnkeyedDecodingContainer`"
  }()

  static let rootLevelEncoding: String = {
    "AnyJSON could not encode invalid root-level JSON object"
  }()

  static let pushNotEnabled: String = {
    "Use of the mobile push notifications API requires Push Notifications which is not enabled for this subscribe key"
  }()

  static let messageDeletionNotEnabled: String = {
    // swiftlint:disable:next line_length
    "Use of the history Delete API requires both Storage & Playback and Storage Delete enabled, one of which is not enabled for this subscribe key"
  }()

  static let messageHistoryNotEnabled: String = {
    "Use of the history API requires the Storage & Playback which is not enabled for this subscribe key"
  }()

  static let cryptoStringEncodeFailed: String = {
    "Decrypted payload failed to String encode using default Coder string encoding"
  }()
}

extension ErrorDescription {
  static let emptyChannelString: String = {
    "Channel is an empty `String`"
  }()

  static let emptyChannelArray: String = {
    "Channels is an empty `Array`"
  }()

  static let emptyGroupString: String = {
    "Group is an empty `String`"
  }()

  static let missingChannelsAnyGroups: String = {
    "No Channels or Groups were provided"
  }()

  static let missingTimetoken: String = {
    "No `Timetoken` value provided"
  }()

  static let invalidHistoryTimetokens: String = {
    "Timetokens `Array` count does not match Channels `Array` count"
  }()

  static let invalidMessageAction: String = {
    "Message Action is invalid"
  }()

  static let emptyMessagePayload: String = {
    "Message is an empty Object"
  }()

  static let emptyUUIDString: String = {
    "UUID is an empty `String`"
  }()

  static let emptyDeviceTokenData: String = {
    "Device Token is an empty `Data`"
  }()

  static let emptyUUIDMetadataId: String = {
    "The UUID MetadataId `String` cannot be empty"
  }()

  static let invalidUUIDMetadata: String = {
    "The Object is not valid UUID Metadata"
  }()

  static let emptyChannelMetadataId: String = {
    "The Channel MetadataId `String` cannot be empty"
  }()

  static let invalidChannelMetadata: String = {
    "The Object is not a valid Channel Metadata"
  }()
}

extension PubNubError: LocalizedError, CustomStringConvertible {
  public var description: String {
    return errorDescription ?? reason.description
  }

  public var errorDescription: String? {
    switch (reason.errorDescription, failureReason) {
    case let (.some(description), .some(reason)):
      return "\(description): \(reason)"
    case let (.some(description), nil):
      return description
    case let (nil, .some(reason)):
      return "\(reason.description): \(reason)"
    case (nil, nil):
      return reason.description
    }
  }

  public var failureReason: String? {
    return details.isEmpty ? nil : details.joined(separator: ", ")
  }
}

extension PubNubError.Domain: CustomStringConvertible {
  public var description: String {
    switch self {
    case .urlCreation:
      return "Failure during URL Creation"
    case .jsonCodability:
      return "Failed encoding or decoding a `Codable` object"
    case .requestProcessing:
      return "Failed during Request Processing"
    case .crypto:
      return "Failure performing a `Crypto` operation"
    case .requestTransmission:
      return "Failure transmitting the request"
    case .responseReceiving:
      return "Client platform failed receiving the response"
    case .responseProcessing:
      return "Response was malformed in some way"
    case .endpointResponse:
      return "Endpoint responded with an Error"
    case .serviceNotEnabled:
      return "Failure due to at least one service not being enabled"
    case .uncategorized:
      return "An unknown error has occurred"
    case .cancellation:
      return "The request was cancelled before completing"
    }
  }
}

extension PubNubError.Reason: CustomStringConvertible, LocalizedError {
  public var description: String {
    switch self {
    case .missingRequiredParameter:
      return "A required parameter was missing or empty"
    case .invalidEndpointType:
      return "The endpoint is invalid for the action being performed"
    case .missingPublishKey:
      return "Required PubNub Publish key is missing"
    case .missingSubscribeKey:
      return "Required PubNub Subscribe key is missing"
    case .missingPublishAndSubscribeKey:
      return "Required PubNub Publish & Subscribe keys are missing"
    case .jsonStringEncodingFailure:
      return "The object could not be encoded into strinigified JSON"
    case .jsonStringDecodingFailure:
      return "The strinigified JSON could not be decoded into the requested object"
    case .jsonDataEncodingFailure:
      return "The object could not be encoded into JSON data"
    case .jsonDataDecodingFailure:
      return "The JSON data could not be decoded into the requested object"
    case .sessionDeinitialized:
      return "Session Deinitialized: This `Session` was deinitialized while tasks were still executing"
    case .sessionInvalidated:
      return "This Session's underlying `URLSession` was invalidated"
    case .missingCryptoKey:
      return "Missing cipher key from `PubNubConfiguration`"
    case .requestMutatorFailure:
      return "The request mutation failed"
    case .requestRetryFailed:
      return "The request reached max retry count"
    case .clientCancelled:
      return "The request was cancelled by the system/user without error"
    case .longPollingRestart:
      return "The long polling request needed to be cancelled to restart with new data"
    case .timedOut:
      return "An asynchronous operation timed out"
    case .nameResolutionFailure:
      return "The host name for an URL could not be resolved"
    case .invalidURL:
      return "A malformed/unsupported URL prevented an URL request from being initiated"
    case .connectionFailure:
      // swiftlint:disable line_length
      return "A network resource was requested, but an internet connection hasn’t been established and can’t be established automatically"
    case .connectionOverDataFailure:
      return "The request couldn't be completed due to issues with the cellular network"
    case .connectionLost:
      return "A client or server connection was severed in the middle of a request"
    case .secureConnectionFailure:
      return "An attempt to establish a secure connection failed for reasons that can’t be expressed more specifically"
    case .certificateTrustFailure:
      return "There was an issue with the secure server certificate"
    case .badServerResponse:
      return "The URL Loading system received bad data from the server"
    case .responseDecodingFailure:
      return "Client system could not parse network response"
    case .dataLengthExceedsMaximum:
      return "The length of the resource data exceeds the maximum allowed"
    case .missingCriticalResponseData:
      return "Request and/or Response nil w/o an underlying error"
    case .unrecognizedStatusCode:
      return "An unrecognized response error code was received and couldn't be categorized"
    case .malformedResponseBody:
      return "Response is valid JSON but not formatted as expected"
    case .badRequest:
      return "An unexpected error occurred while processing the request"
    case .unauthorized:
      return "Access was denied due to insufficient authentication/authorization"
    case .forbidden:
      return "Authorization key is missing or does not have the permissions required to perform this operation"
    case .resourceNotFound:
      return "Requested resource not found at that endpoint"
    case .conflict:
      return "Object already changed by another request since last retrieval"
    case .preconditionFailed:
      return "Request payload must be in JSON format"
    case .requestURITooLong:
      return "URI of the request was too long to be processed"
    case .tooManyRequests:
      return "You have exceeded the maximum number of requests per second allowed for your subscriber key"
    case .unsupportedType:
      return "There was an unsupported object sent to the server"
    case .malformedFilterExpression:
      return "The supplied filter expression was malformed"
    case .internalServiceError:
      return "An unexpected error occurred while processing the request"
    case .serviceUnavailable:
      return "The server took longer to respond than the maximum allowed processing time"
    case .invalidArguments:
      return "At least one `Request` parameters were invalid"
    case .invalidCharacter:
      return "At least one invalid character was used in the request"
    case .invalidDevicePushToken:
      return "The provided device token is not a valid push token"
    case .invalidSubscribeKey:
      return "The PubNub Subscribe key used for the request is invalid"
    case .invalidPublishKey:
      return "The PubNub Publish key used for the request is invalid"
    case .maxChannelGroupCountExceeded:
      return "The maximum number of channel groups has been reached"
    case .pushNotEnabled:
      return "Use of the mobile push notifications API requires Push Notifications which is not enabled for this subscribe key"
    case .messageHistoryNotEnabled:
      return "Use of the history API requires the Storage & Playback which is not enabled for this subscribe key"
    case .messageDeletionNotEnabled:
      return "Use of the history Delete API requires both Storage & Playback and Storage Delete enabled, one of which is not enabled for this subscribe key"
    case .multiplexingNotEnabled:
      return "Use of Multiplexing requires Stream Controller to be enabled for this subscribe key"
    case .couldNotParseRequest:
      return "The PubNub server was unable to parse the request"
    case .requestContainedInvalidJSON:
      return "The request contained a malformed JSON payload"
    case .messageCountExceededMaximum:
      return "The amount of messages returned exceeded the maximum allowed"
    case .messageTooLong:
      return "The message you attempted to publish was too large to transmit successfully"
    case .invalidUUID:
      return "Could not complete action due to wrong uuid specified"
    case .nothingToDelete:
      return "There was nothing to delete"
    case .unknown:
      return "Reason could not be parsed from existing strings"
    case .failedToPublish:
      return "The operation successfully stored the value, but failed to publish"
    }
  }

  public var errorDescription: String? {
    return description
  }
}

// swiftlint:enable line_length
