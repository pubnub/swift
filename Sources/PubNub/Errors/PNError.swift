//
//  PNError.swift
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

public enum PNError: Error {
  // Request Errors

  // NON-Reason Failures
  case unknown(String)
  case unknownError(Error)
  case sessionDeinitialized(for: UUID)
  case requestRetryFailed(URLRequest, dueTo: Error, withPreviousError: Error?)

  public enum RequestCreationFailureReason {
    // URL Creation Errors
    case jsonStringCodingFailure(AnyJSON, dueTo: Error)
    case missingPublishKey
    case missingSubscribeKey
    case missingPublishAndSubscribeKey

    // Reqeuest Creation
    case unknown(Error)
    case jsonDataCodingFailure(AnyJSON, with: Error)
    case requestMutatorFailure(URLRequest, Error)
  }

  case requestCreationFailure(RequestCreationFailureReason)

  // MARK: - System Created Network Errors

  public enum RequestTransmissionFailureReason {
    // Reasons why failed to transmit request
    case unknown(URLError)
    case cancelled(URLError)
    case timedOut(URLError)
    case nameResolutionFailure(URLError)
    case invalidURL(URLError)
    case connectionFailure(URLError)
    case connectionOverDataFailure(URLError)
    case connectionLost(URLError)
    case secureConnectionFailure(URLError)
    case secureTrustFailure(URLError)
  }

  case requestTransmissionFailure(RequestTransmissionFailureReason, forRequest: URLRequest)

  public enum ResponseProcessingFailureReason {
    // System Errors that were returned via URLSessionDelegate
    case receiveFailure(URLError)
    case responseDecodingFailure(URLError)
    case dataLengthExceedsMaximum(URLError)
  }

  case responseProcessingFailure(ResponseProcessingFailureReason, forRequest: URLRequest, onResponse: HTTPURLResponse?)

  public enum EndpointFailureReason {
    case malformedResponseBody
    case jsonDataDecodeFailure(Data?, with: Error)

    case invalidCharacter
    case invalidDeviceToken
    case invalidSubscribeKey
    case invalidPublishKey
    case maxChannelGroupCountExceeded
    case pushNotEnabled
    case couldNotParseRequest
    case requestContainedInvalidJSON
    case serviceUnavailable

    case badRequest
    case unauthorized
    case forbidden
    case resourceNotFound
    case requestURITooLong
    case malformedFilterExpression
    case internalServiceError

    case unrecognizedErrorPayload(GenericServicePayloadResponse)
    case unknown(String)
  }

  /// Indicates that the request/reponse was successfully sent, but the PubNub system returned an error
  case endpointFailure(EndpointFailureReason, forRequest: URLRequest, onResponse: HTTPURLResponse)

  // When Error Occurred
  public enum SessionInvalidationReason {
    case explicit
    case implicit(dueTo: Error)
  }

  case sessionInvalidated(SessionInvalidationReason, sessionID: UUID?)
}

extension PNError {
  // swiftlint:disable:next cyclomatic_complexity function_body_length
  static func convert(error: URLError, request: URLRequest?, response: HTTPURLResponse?) -> PNError? {
    let errorCode = URLError.Code(rawValue: error.errorCode)

    guard let request = request else {
      return nil
    }

    switch errorCode {
    // Unknown
    case .unknown: // rawValue == -1
      return .requestTransmissionFailure(.unknown(error), forRequest: request)

    // Cancelled
    case .cancelled, // rawValue == -999
         .userCancelledAuthentication: // rawValue == -1012
      return .requestTransmissionFailure(
        .cancelled(error), forRequest: request
      )

    // Timed Out
    case .timedOut: // rawValue == -1001
      return .requestTransmissionFailure(
        .timedOut(error), forRequest: request
      )

    // Name Resolution Failure
    case .cannotFindHost, // rawValue == -1003
         .dnsLookupFailed: // rawValue == -1006
      return .requestTransmissionFailure(
        .nameResolutionFailure(error), forRequest: request
      )

    // Invalid URL Issues
    case .badURL, // rawValue == -1000
         .unsupportedURL: // rawValue == -1002
      return .requestTransmissionFailure(
        .invalidURL(error), forRequest: request
      )

    // Connection Issues
    case .cannotConnectToHost, // rawValue == -1004
         .resourceUnavailable, // rawValue == -1008
         .notConnectedToInternet: // rawValue == -1009
      return .requestTransmissionFailure(
        .connectionFailure(error), forRequest: request
      )

    // SIM Related
    case .internationalRoamingOff, // rawValue == -1018
         .callIsActive, // rawValue == -1019
         .dataNotAllowed: // rawValue == -1020
      return .requestTransmissionFailure(
        .connectionOverDataFailure(error), forRequest: request
      )

    // Connection Closed
    case .networkConnectionLost: // rawValue == -1005
      return .requestTransmissionFailure(
        .connectionLost(error), forRequest: request
      )

    // Secure Connection Failure
    case .secureConnectionFailed: // rawValue == -1200
      return .requestTransmissionFailure(
        .secureConnectionFailure(error), forRequest: request
      )

    // Certificate Trust Failure
    case .serverCertificateHasBadDate, // rawValue == -1201
         .serverCertificateUntrusted, // rawValue == -1202
         .serverCertificateHasUnknownRoot, // rawValue == -1203
         .serverCertificateNotYetValid, // rawValue == -1204
         .clientCertificateRejected, // rawValue == -1205
         .clientCertificateRequired: // rawValue == -1206
      return .requestTransmissionFailure(
        .secureTrustFailure(error), forRequest: request
      )

    // Recieve Failure
    case .badServerResponse, // rawValue == -1011
         .zeroByteResource: // rawValue == -1014
      return .responseProcessingFailure(
        .receiveFailure(error),
        forRequest: request,
        onResponse: response
      )

    // Response Decoding Failure
    case .cannotDecodeRawData, // rawValue == -1015
         .cannotDecodeContentData, // rawValue == -1016
         .cannotParseResponse: // rawValue == -1017
      return .responseProcessingFailure(
        .responseDecodingFailure(error),
        forRequest: request,
        onResponse: response
      )

    // Data Length Exceeded
    case .dataLengthExceedsMaximum: // rawValue == -1103
      return .responseProcessingFailure(
        .dataLengthExceedsMaximum(error),
        forRequest: request,
        onResponse: response
      )

    // Not used but will retain reference for completeness
//    case .httpTooManyRedirects: break
//    case .redirectToNonExistentLocation: break
//    case .userAuthenticationRequired: break
//    case .cannotLoadFromNetwork: break
//    case .cannotCreateFile: break
//    case .cannotOpenFile: break
//    case .cannotCloseFile: break
//    case .cannotWriteToFile: break
//    case .cannotRemoveFile: break
//    case .cannotMoveFile: break
//    case .downloadDecodingFailedMidStream: break
//    case .downloadDecodingFailedToComplete: break
//    case .fileDoesNotExist: break
//    case .fileIsDirectory: break
//    case .noPermissionsToReadFile: break
//    case .requestBodyStreamExhausted: break
//    case .backgroundSessionRequiresSharedContainer: break
//    case .backgroundSessionInUseByAnotherProcess: break
//    case .backgroundSessionWasDisconnected: break
    default:
      if #available(OSX 10.11, iOS 9.0, *) {
        if errorCode == .appTransportSecurityRequiresSecureConnection { // rawValue == -1022
          return .requestTransmissionFailure(
            .secureTrustFailure(error), forRequest: request
          )
        }
      }
    }

    return .unknownError(error)
  }

  static func convert(
    generalError payload: GenericServicePayloadResponse?,
    request: URLRequest,
    response: HTTPURLResponse?
  ) -> PNError {
    guard let response = response else {
      return PNError.unknown(ErrorDescription.UnknownErrorReason.endpointErrorMissingResponse)
    }

    // Try to associate with a specific error message
    if let reason = PNError.lookupGeneralErrorMessage(using: payload?.message) {
      return PNError.endpointFailure(reason,
                                     forRequest: request,
                                     onResponse: response)
    }

    // Try to associate with a general status code error
    let status = payload?.status ?? GenericServicePayloadResponse.Code(rawValue: response.statusCode)
    if let reason = PNError.lookupGeneralErrorStatus(using: status) {
      return PNError.endpointFailure(reason,
                                     forRequest: request,
                                     onResponse: response)
    }
//
//    if let payload = payload, !payload.isEmpty {
//      return PNError.endpointFailure(.unrecognizedErrorPayload(payload),
//                                     forRequest: request,
//                                     onResponse: response)
//    }

    return PNError.endpointFailure(.unknown(ErrorDescription.UnknownErrorReason.noAppropriateEndpointError),
                                   forRequest: request,
                                   onResponse: response)
  }

  // swiftlint:disable:next cyclomatic_complexity
  static func lookupGeneralErrorMessage(
    using message: GenericServicePayloadResponse.Message?
  ) -> EndpointFailureReason? {
    switch message {
    case .couldNotParseRequest?:
      return .couldNotParseRequest
    case .some(.invalidCharacter):
      return .invalidCharacter
    case .some(.invalidDeviceToken):
      return .invalidDeviceToken
    case .invalidSubscribeKey?:
      return .invalidSubscribeKey
    case .invalidPublishKey?:
      return .invalidPublishKey
    case .invalidJSON?:
      return .requestContainedInvalidJSON
    case .some(.maxChannelGroupCountExceeded):
      return .maxChannelGroupCountExceeded
    case .notFound?:
      return .resourceNotFound
    case .some(.pushNotEnabled):
      return .pushNotEnabled
    case .requestURITooLong?:
      return .requestURITooLong
    case .some(.serviceUnavailable):
      return .serviceUnavailable
    case .unknown?, .acknowledge?, .none:
      return nil
    }
  }

  static func lookupGeneralErrorStatus(using code: GenericServicePayloadResponse.Code) -> EndpointFailureReason? {
    switch code {
    case .badRequest:
      return .badRequest
    case .unauthorized:
      return .unauthorized
    case .forbidden:
      return .forbidden
    case .notFound:
      return .resourceNotFound
    case .uriTooLong:
      return .requestURITooLong
    case .malformedFilterExpression:
      return .malformedFilterExpression
    case .internalServiceError:
      return .internalServiceError
    case .serviceUnavailable:
      return .serviceUnavailable
    case .acknowledge, .unknown:
      return nil
    }
  }
}
