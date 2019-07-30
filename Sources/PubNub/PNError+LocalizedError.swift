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
    case let .unknown(message):
      return "Unkonwn Error: An unknown error occurred with the supplied message: \(message)"
    case let .unknownError(error):
      return "Unkonwn Error: An unkonwn error occurred with the supplied error: \(error)"
    case let .sessionInvalidated(reason, sessionId):
      let idString = sessionId?.uuidString ?? "<Unknown>"
      return "Session Invalidated: The underlying `URLSession` for `Session` \(idString) was invalidated \(reason)"
    case let .sessionDeinitialized(sessionID):
      return "Session Deinitialized: `Session` \(sessionID) was deinitialized while tasks were still executing."
    case let .requestRetryFailed(_, error, _):
      return "Request Retry Failed: Request reached max retry count with final error \(error)"
    case let .requestCreationFailure(reason):
      return "Request Creation Failed: \(reason)"
    case let .requestTransmissionFailure(reason):
      return "Transmission Failure: \(reason)"
    case let .responseProcessingFailure(reason):
      return "Response Failure: \(reason)"
    case let .endpointFailure(reason, _, _):
      return "Endpoint Error: \(reason)"
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
    return "No failure reason was provied."
  }

  public var recoverySuggestion: String {
    return "No recover suggestion was provided."
  }
}

// "Request Creation Failed: \(reason)"
extension PNError.RequestCreationFailureReason: LocalizedErrorReason {
  public var errorDescription: String {
    switch self {
    case .jsonStringCodingFailure:
      return "The JSON object could not be serialized into a `String`"
    case .missingPubNubKey:
      return "One or more required PubNub Keys are missing"
    case .unknown:
      return "An unknown error occured"
    case .jsonDataCodingFailure:
      return "The JSON object could be serizlied into a `Data` object."
    case .requestMutatorFailure:
      return "The request mutation failued resulting in an error"
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
      return "Unable to decode the response body"
    case .jsonDataDecodeFailure:
      return "An error was thrown attempting to decode the response body"
    case .invalidSubscribeKey:
      return "The PubNub Subscribe key used for the request is invalid"
    case .invalidPublishKey:
      return "The PubNub Publish key used for the request is invalid"
    case .couldNotParseRequest:
      return "The PubNub server was unable to parse the request"
    case .badRequest:
      return "Bad request on that endpoint"
    case .unauthorized:
      return "Access was denied due to insuffienct authorization"
    case .forbidden:
      return "Operation forbidden on that endpoint"
    case .resourceNotFound:
      return "Resource not found at that endpoint"
    case .requestURITooLong:
      return "URI of the request was too long to be processed"
    case .malformedFilterExpression:
      return "The supplied filter expression was malformed"
    case .internalServiceError:
      return "The server encountered an unforseen error while processing the request"
    case .unrecognizedErrorPayload:
      return "A payload not matching any konwn reason was received"
    case let .unknown(message):
      return "Unknown Reason: \(message)."
    }
  }
}

extension PNError.SessionInvalidationReason: LocalizedErrorReason {
  public var errorDescription: String {
    switch self {
    case .explicit:
      return "Explicitly"
    case .implicit:
      return "Inplicitly"
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
