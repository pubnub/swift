//
//  PNError+Equatable.swift
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

extension PNError: Equatable {
  public static func == (lhs: PNError, rhs: PNError) -> Bool {
    switch (lhs, rhs) {
    case let (.unknown(lhsMessage), .unknown(rhsMessage)):
      return lhsMessage == rhsMessage
    case let (.unknownError(lhsError), .unknownError(rhsError)):
      return lhsError.localizedDescription == rhsError.localizedDescription
    case let (.sessionDeinitialized(lhsUUID), .sessionDeinitialized(rhsUUID)):
      return lhsUUID == rhsUUID
    case let (.requestRetryFailed(lhsParams), .requestRetryFailed(rhsParams)):
      return lhsParams.0 == rhsParams.0 &&
        lhsParams.dueTo.localizedDescription == rhsParams.dueTo.localizedDescription &&
        lhsParams.withPreviousError?.localizedDescription == rhsParams.withPreviousError?.localizedDescription
    case let (.requestCreationFailure(lhsReason), .requestCreationFailure(rhsReason)):
      return lhsReason == rhsReason
    case let (.requestTransmissionFailure(lhsReason), .requestTransmissionFailure(rhsReason)):
      return lhsReason == rhsReason
    case let (.responseProcessingFailure(lhsReason), .responseProcessingFailure(rhsReason)):
      return lhsReason == rhsReason
    case let (.endpointFailure(lhsReason), .endpointFailure(rhsReason)):
      return lhsReason == rhsReason
    case let (.sessionInvalidated(lhsReason), .sessionInvalidated(rhsReason)):
      return lhsReason == rhsReason
    default:
      return false
    }
  }
}

extension PNError.RequestCreationFailureReason: Equatable {
  public static func == (
    lhs: PNError.RequestCreationFailureReason,
    rhs: PNError.RequestCreationFailureReason
  ) -> Bool {
    switch (lhs, rhs) {
    case (.jsonStringCodingFailure, .jsonStringCodingFailure):
      return true
    case (.missingPublishKey, .missingPublishKey):
      return true
    case (.missingSubscribeKey, .missingSubscribeKey):
      return true
    case (.missingPublishAndSubscribeKey, .missingPublishAndSubscribeKey):
      return true
    case let (.unknown(lhsError), .unknown(rhsError)):
      return lhsError.localizedDescription == rhsError.localizedDescription
    case (.jsonDataCodingFailure, .jsonDataCodingFailure):
      return true
    case let (.requestMutatorFailure(lhsRequest, lhsError), .requestMutatorFailure(rhsRequest, rhsError)):
      return lhsRequest == rhsRequest &&
        lhsError.localizedDescription == rhsError.localizedDescription
    default:
      return false
    }
  }
}

extension PNError.RequestTransmissionFailureReason: Equatable {
  // swiftlint:disable:next cyclomatic_complexity
  public static func == (
    lhs: PNError.RequestTransmissionFailureReason,
    rhs: PNError.RequestTransmissionFailureReason
  ) -> Bool {
    switch (lhs, rhs) {
    case let (.unknown(lhsError), .unknown(rhsError)):
      return lhsError.code == rhsError.code
    case let (.cancelled(lhsError), .cancelled(rhsError)):
      return lhsError.code == rhsError.code
    case let (.timedOut(lhsError), .timedOut(rhsError)):
      return lhsError.code == rhsError.code
    case let (.nameResolutionFailure(lhsError), .nameResolutionFailure(rhsError)):
      return lhsError.code == rhsError.code
    case let (.invalidURL(lhsError), .invalidURL(rhsError)):
      return lhsError.code == rhsError.code
    case let (.connectionFailure(lhsError), .connectionFailure(rhsError)):
      return lhsError.code == rhsError.code
    case let (.connectionOverDataFailure(lhsError), .connectionOverDataFailure(rhsError)):
      return lhsError.code == rhsError.code
    case let (.connectionLost(lhsError), .connectionLost(rhsError)):
      return lhsError.code == rhsError.code
    case let (.secureConnectionFailure(lhsError), .secureConnectionFailure(rhsError)):
      return lhsError.code == rhsError.code
    case let (.secureTrustFailure(lhsError), .secureTrustFailure(rhsError)):
      return lhsError.code == rhsError.code
    default:
      return false
    }
  }
}

extension PNError.ResponseProcessingFailureReason: Equatable {
  public static func == (
    lhs: PNError.ResponseProcessingFailureReason,
    rhs: PNError.ResponseProcessingFailureReason
  ) -> Bool {
    switch (lhs, rhs) {
    case let (.receiveFailure(lhsError), .receiveFailure(rhsError)):
      return lhsError.code == rhsError.code
    case let (.responseDecodingFailure(lhsError), .responseDecodingFailure(rhsError)):
      return lhsError.code == rhsError.code
    case let (.dataLengthExceedsMaximum(lhsError), .dataLengthExceedsMaximum(rhsError)):
      return lhsError.code == rhsError.code
    default:
      return false
    }
  }
}

extension PNError.EndpointFailureReason: Equatable {
  // swiftlint:disable:next cyclomatic_complexity
  public static func == (lhs: PNError.EndpointFailureReason, rhs: PNError.EndpointFailureReason) -> Bool {
    switch (lhs, rhs) {
    case (.malformedResponseBody, .malformedResponseBody):
      return true
    case let (.jsonDataDecodeFailure(lhsData, lhsError), .jsonDataDecodeFailure(rhsData, rhsError)):
      return lhsData == rhsData && lhsError.localizedDescription == rhsError.localizedDescription
    case (.invalidCharacter, .invalidCharacter):
      return true
    case (.invalidSubscribeKey, .invalidSubscribeKey):
      return true
    case (.invalidPublishKey, .invalidPublishKey):
      return true
    case (.maxChannelGroupCountExceeded, .maxChannelGroupCountExceeded):
      return true
    case (.requestContainedInvalidJSON, .requestContainedInvalidJSON):
      return true
    case (.couldNotParseRequest, .couldNotParseRequest):
      return true
    case (.badRequest, .badRequest):
      return true
    case (.unauthorized, .unauthorized):
      return true
    case (.forbidden, .forbidden):
      return true
    case (.resourceNotFound, .resourceNotFound):
      return true
    case (.requestURITooLong, .requestURITooLong):
      return true
    case let (.unrecognizedErrorPayload(lhsPayload), .unrecognizedErrorPayload(rhsPayload)):
      return lhsPayload == rhsPayload
    case (.malformedFilterExpression, .malformedFilterExpression):
      return true
    case (.internalServiceError, .internalServiceError):
      return true
    case let (.unknown(lhsMessage), .unknown(rhsMessage)):
      return lhsMessage == rhsMessage
    default:
      return false
    }
  }
}

extension PNError.SessionInvalidationReason: Equatable {
  public static func == (lhs: PNError.SessionInvalidationReason, rhs: PNError.SessionInvalidationReason) -> Bool {
    switch (lhs, rhs) {
    case (.explicit, .explicit):
      return true
    case let (.implicit(lhsError), .implicit(rhsError)):
      return lhsError.localizedDescription == rhsError.localizedDescription
    default:
      return false
    }
  }
}
