//
//  PNError.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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
  case requestRetryFailed(URLRequest, dueTo: Error, withPreviousError: Error)

  public enum RequestCreationFailureReason {
    // URL Creation Errors
    case jsonStringCodingFailure(AnyJSON, dueTo: Error)
    case missingPubNubKey(PNKeyRequirement, for: Endpoint)

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
    case accessDenied
    case malformedFilterExpression
    case malformedResponseBody
    case jsonDataDecodeFailure(Data?, with: Error)
    case decryptionFailure
    // Contains Server Response Message
    case invalidSubscribeKey(EndpointErrorPayload)
    case invalidPublishKey(EndpointErrorPayload)
    case couldNotParseRequest(EndpointErrorPayload)

    case badRequest(EndpointErrorPayload)
    case forbidden(EndpointErrorPayload)
    case resourceNotFound(EndpointErrorPayload)
    case requestURITooLong(EndpointErrorPayload)

    case unknown(EndpointErrorPayload)
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
    case .unknown:
      return .requestTransmissionFailure(.unknown(error), forRequest: request)

    // Cancelled
    case .cancelled,
         .userCancelledAuthentication:
      return .requestTransmissionFailure(
        .cancelled(error), forRequest: request
      )

    // Timed Out
    case .timedOut:
      return .requestTransmissionFailure(
        .timedOut(error), forRequest: request
      )

    // Name Resolution Failure
    case .cannotFindHost,
         .dnsLookupFailed:
      return .requestTransmissionFailure(
        .nameResolutionFailure(error), forRequest: request
      )

    // Connection Issues
    case .badURL,
         .unsupportedURL:
      return .requestTransmissionFailure(
        .invalidURL(error), forRequest: request
      )

    case .cannotConnectToHost,
         .resourceUnavailable,
         .notConnectedToInternet:
      return .requestTransmissionFailure(
        .connectionFailure(error), forRequest: request
      )

    // SIM Related
    case .internationalRoamingOff,
         .callIsActive,
         .dataNotAllowed:
      return .requestTransmissionFailure(
        .connectionOverDataFailure(error), forRequest: request
      )

    // Connection Closed
    case .networkConnectionLost:
      return .requestTransmissionFailure(
        .connectionLost(error), forRequest: request
      )

    // Secure Connection Failure
    case .secureConnectionFailed:
      return .requestTransmissionFailure(
        .secureConnectionFailure(error), forRequest: request
      )

    // Certificate Trust Failure
    case .serverCertificateHasBadDate: break
    case .serverCertificateUntrusted: break
    case .serverCertificateHasUnknownRoot: break
    case .serverCertificateNotYetValid: break
    case .clientCertificateRejected: break
    case .clientCertificateRequired:
      return .requestTransmissionFailure(
        .secureTrustFailure(error), forRequest: request
      )

    // Something wrong with the server
    case .badServerResponse,
         .zeroByteResource:
      return .responseProcessingFailure(
        .receiveFailure(error),
        forRequest: request,
        onResponse: response
      )

    case .cannotDecodeRawData,
         .cannotDecodeContentData,
         .cannotParseResponse:
      return .responseProcessingFailure(
        .responseDecodingFailure(error),
        forRequest: request,
        onResponse: response
      )

    // Data Length Exceeded
    case .dataLengthExceedsMaximum:
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
        if errorCode == .appTransportSecurityRequiresSecureConnection {
          return .requestTransmissionFailure(
            .secureTrustFailure(error), forRequest: request
          )
        }
      }
    }

    return .unknownError(error)
  }

  static func convert(
    generalError payload: EndpointErrorPayload,
    request: URLRequest,
    response: HTTPURLResponse
  ) -> PNError {
    // Try to associate with a specific error message
    if let reason = PNError.lookupGeneralErrorMessage(using: payload) {
      return PNError.endpointFailure(reason,
                                     forRequest: request,
                                     onResponse: response)
    }

    // Try to associate with a general status code error
    let status = payload.status ?? EndpointErrorPayload.Code(rawValue: response.statusCode)
    if let reason = PNError.lookupGeneralErrorStatus(using: status, for: payload) {
      return PNError.endpointFailure(reason,
                                     forRequest: request,
                                     onResponse: response)
    }

    return PNError.endpointFailure(.unknown(payload),
                                   forRequest: request,
                                   onResponse: response)
  }

  static func lookupGeneralErrorMessage(using payload: EndpointErrorPayload) -> EndpointFailureReason? {
    switch payload.message {
    case .couldNotParseRequest:
      return .couldNotParseRequest(payload)
    case .invalidSubscribeKey:
      return .invalidSubscribeKey(payload)
    case .invalidPublishKey:
      return .invalidPublishKey(payload)
    case .notFound:
      return .resourceNotFound(payload)
    case .requestURITooLong:
      return .requestURITooLong(payload)
    case .unknown:
      return nil
    }
  }

  static func lookupGeneralErrorStatus(
    using code: EndpointErrorPayload.Code,
    for payload: EndpointErrorPayload
  ) -> EndpointFailureReason? {
    switch code {
    case .badRequest:
      return .badRequest(payload)
    case .forbidden:
      return .forbidden(payload)
    case .notFound:
      return .resourceNotFound(payload)
    case .uriTooLong:
      return .requestURITooLong(payload)
    case .unknown:
      return nil
    }
  }
}
