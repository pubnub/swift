//
//  PNError+LocalizedError.swift
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

extension PNError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case let .unknown(message, _):
      return "\(ErrorDescription.PNError.unknown) \(message)"
    case let .unknownError(error):
      return "\(ErrorDescription.PNError.unknownError) \(error)"
    case .missingRequiredParameter:
      return ErrorDescription.PNError.missingRequiredParameter
    case .invalidEndpointType:
      return ErrorDescription.PNError.invalidEndpointType
    case let .sessionInvalidated(reason, sessionID: _):
      return "\(ErrorDescription.PNError.sessionInvalidated) \(reason)"
    case .sessionDeinitialized:
      return ErrorDescription.PNError.sessionDeinitialized
    case let .requestRetryFailed(_, _, error, _):
      return "\(ErrorDescription.PNError.requestRetryFailed) \(error)"
    case let .requestCreationFailure(reason):
      return "\(ErrorDescription.PNError.requestCreationFailure) \(reason)"
    case let .requestTransmissionFailure(reason):
      return "\(ErrorDescription.PNError.requestTransmissionFailure) \(reason)"
    case let .responseProcessingFailure(reason):
      return "\(ErrorDescription.PNError.responseProcessingFailure) \(reason)"
    case let .endpointFailure(reason, _, _, _):
      return "\(ErrorDescription.PNError.endpointFailure) \(reason)"
    }
  }
}

// MARK: - Localized Strings

public protocol LocalizedErrorReason {
  /// A localized message describing what error occurred.
  var errorDescription: String { get }

  /// A localized message describing the reason for the failure.
  var failureReason: String { get }

  /// A localized message describing how one might recover from the failure.
  var recoverySuggestion: String { get }
}

extension LocalizedErrorReason {
  public var failureReason: String {
    return ErrorDescription.defaultFailureReason
  }

  public var recoverySuggestion: String {
    return ErrorDescription.defaultRecoverySuggestion
  }
}

// "Request Creation Failed: \(reason)"
extension PNError.RequestCreationFailureReason: LocalizedErrorReason {
  public var errorDescription: String {
    switch self {
    case .jsonStringCodingFailure:
      return ErrorDescription.RequestCreationFailureReason.jsonStringCodingFailure
    case .missingPublishKey:
      return ErrorDescription.RequestCreationFailureReason.missingPublishKey
    case .missingSubscribeKey:
      return ErrorDescription.RequestCreationFailureReason.missingSubscribeKey
    case .missingPublishAndSubscribeKey:
      return ErrorDescription.RequestCreationFailureReason.missingPublishAndSubscribeKey
    case .unknown:
      return ErrorDescription.RequestCreationFailureReason.unknown
    case .jsonDataCodingFailure:
      return ErrorDescription.RequestCreationFailureReason.jsonDataCodingFailure
    case .requestMutatorFailure:
      return ErrorDescription.RequestCreationFailureReason.requestMutatorFailure
    }
  }
}

//  "Transmission Failure: \(reason)"
extension PNError.RequestTransmissionFailureReason: LocalizedErrorReason {
  public var errorDescription: String {
    switch self {
    case let .unknown(urlError):
      return urlError.localizedDescription
    case let .cancelled(urlError):
      return urlError.localizedDescription
    case let .timedOut(urlError):
      return urlError.localizedDescription
    case let .nameResolutionFailure(urlError):
      return urlError.localizedDescription
    case let .invalidURL(urlError):
      return urlError.localizedDescription
    case let .connectionFailure(urlError):
      return urlError.localizedDescription
    case let .connectionOverDataFailure(urlError):
      return urlError.localizedDescription
    case let .connectionLost(urlError):
      return urlError.localizedDescription
    case let .secureConnectionFailure(urlError):
      return urlError.localizedDescription
    case let .secureTrustFailure(urlError):
      return urlError.localizedDescription
    }
  }
}

// "Response Failure: \(reason)"
extension PNError.ResponseProcessingFailureReason: LocalizedErrorReason {
  public var errorDescription: String {
    switch self {
    case let .receiveFailure(urlError):
      return urlError.localizedDescription
    case let .responseDecodingFailure(urlError):
      return urlError.localizedDescription
    case let .dataLengthExceedsMaximum(urlError):
      return urlError.localizedDescription
    }
  }
}

// "Operation Error: \(reason)"
extension PNError.EndpointFailureReason: LocalizedErrorReason {
  public var errorDescription: String {
    switch self {
    case .malformedResponseBody:
      return ErrorDescription.EndpointFailureReason.malformedResponseBody
    case .jsonDataDecodeFailure:
      return ErrorDescription.EndpointFailureReason.jsonDataDecodeFailure
    case .invalidArguments:
      return ErrorDescription.EndpointFailureReason.invalidArguments
    case .invalidCharacter:
      return ErrorDescription.EndpointFailureReason.invalidCharacter
    case .invalidDeviceToken:
      return ErrorDescription.EndpointFailureReason.invalidDeviceToken
    case .invalidSubscribeKey:
      return ErrorDescription.EndpointFailureReason.invalidSubscribeKey
    case .invalidPublishKey:
      return ErrorDescription.EndpointFailureReason.invalidPublishKey
    case .maxChannelGroupCountExceeded:
      return ErrorDescription.EndpointFailureReason.maxChannelGroupCountExceeded
    case .pushNotEnabled:
      return ErrorDescription.EndpointFailureReason.pushNotEnabled
    case .messageHistoryNotEnabled:
      return ErrorDescription.EndpointFailureReason.messageHistoryNotEnabled
    case .messageDeletionNotEnabled:
      return ErrorDescription.EndpointFailureReason.messageDeletionNotEnabled
    case .requestContainedInvalidJSON:
      return ErrorDescription.EndpointFailureReason.requestContainedInvalidJSON
    case .serviceUnavailable:
      return ErrorDescription.EndpointFailureReason.serviceUnavailable
    case .couldNotParseRequest:
      return ErrorDescription.EndpointFailureReason.couldNotParseRequest
    case .badRequest:
      return ErrorDescription.EndpointFailureReason.badRequest
    case .unauthorized:
      return ErrorDescription.EndpointFailureReason.unauthorized
    case .forbidden:
      return ErrorDescription.EndpointFailureReason.forbidden
    case .resourceNotFound:
      return ErrorDescription.EndpointFailureReason.resourceNotFound
    case .requestURITooLong:
      return ErrorDescription.EndpointFailureReason.requestURITooLong
    case .malformedFilterExpression:
      return ErrorDescription.EndpointFailureReason.malformedFilterExpression
    case .internalServiceError:
      return ErrorDescription.EndpointFailureReason.internalServiceError
    case .unrecognizedErrorPayload:
      return ErrorDescription.EndpointFailureReason.unrecognizedErrorPayload
    case .unknown:
      return ErrorDescription.EndpointFailureReason.unknown
    }
  }
}

extension PNError.SessionInvalidationReason: LocalizedErrorReason {
  public var errorDescription: String {
    switch self {
    case .explicit:
      return ErrorDescription.SessionInvalidationReason.explicit
    case .implicit:
      return ErrorDescription.SessionInvalidationReason.implicit
    }
  }
}

extension String.StringInterpolation {
  mutating func appendInterpolation(_ value: Error) {
    appendLiteral(value.localizedDescription)
  }

  mutating func appendInterpolation(_ value: PNError.RequestCreationFailureReason) {
    appendLiteral(value.errorDescription)
  }

  mutating func appendInterpolation(_ value: PNError.RequestTransmissionFailureReason) {
    appendLiteral(value.errorDescription)
  }

  mutating func appendInterpolation(_ value: PNError.ResponseProcessingFailureReason) {
    appendLiteral(value.errorDescription)
  }

  mutating func appendInterpolation(_ value: PNError.EndpointFailureReason) {
    appendLiteral(value.errorDescription)
  }

  mutating func appendInterpolation(_ value: PNError.SessionInvalidationReason) {
    appendLiteral(value.errorDescription)
  }
}
