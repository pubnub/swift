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
  case unknown(message: String, Endpoint)
  case unknownError(Error, Endpoint)
  case missingRequiredParameter(Endpoint)
  case invalidEndpointType(Endpoint)
  case sessionDeinitialized(sessionID: UUID)
  case requestRetryFailed(Endpoint, URLRequest, dueTo: Error, withPreviousError: Error?)

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

  case requestCreationFailure(RequestCreationFailureReason, Endpoint)

  // MARK: - System Created Network Errors

  public enum RequestTransmissionFailureReason: RawRepresentable {
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

    public var rawValue: URLError {
      switch self {
      case let .unknown(error):
        return error
      case let .cancelled(error):
        return error
      case let .timedOut(error):
        return error
      case let .nameResolutionFailure(error):
        return error
      case let .invalidURL(error):
        return error
      case let .connectionFailure(error):
        return error
      case let .connectionOverDataFailure(error):
        return error
      case let .connectionLost(error):
        return error
      case let .secureConnectionFailure(error):
        return error
      case let .secureTrustFailure(error):
        return error
      }
    }

    // swiftlint:disable:next cyclomatic_complexity
    public init?(rawValue: URLError) {
      switch rawValue.code {
      case .cancelled:
        self = .cancelled(rawValue)
      case .unknown:
        self = .unknown(rawValue)
      case .timedOut:
        self = .timedOut(rawValue)
      case .cannotFindHost, .dnsLookupFailed:
        self = .nameResolutionFailure(rawValue)
      case .badURL, .unsupportedURL:
        self = .invalidURL(rawValue)
      case .cannotConnectToHost, .resourceUnavailable, .notConnectedToInternet:
        self = .connectionFailure(rawValue)
      case .internationalRoamingOff, .callIsActive, .dataNotAllowed:
        self = .connectionOverDataFailure(rawValue)
      case .networkConnectionLost:
        self = .connectionLost(rawValue)
      case .secureConnectionFailed:
        self = .secureConnectionFailure(rawValue)
      case .serverCertificateHasBadDate,
           .serverCertificateUntrusted,
           .serverCertificateHasUnknownRoot,
           .serverCertificateNotYetValid,
           .clientCertificateRejected,
           .clientCertificateRequired:
        self = .secureTrustFailure(rawValue)
      default:
        if #available(iOS 9.0, macOS 10.11, *), rawValue.code == .appTransportSecurityRequiresSecureConnection {
          self = .secureTrustFailure(rawValue)
        }

        return nil
      }
    }
  }

  case requestTransmissionFailure(RequestTransmissionFailureReason, Endpoint, URLRequest)

  public enum ResponseProcessingFailureReason: RawRepresentable {
    // System Errors that were returned via URLSessionDelegate
    case receiveFailure(URLError)
    case responseDecodingFailure(URLError)
    case dataLengthExceedsMaximum(URLError)

    public var rawValue: URLError {
      switch self {
      case let .receiveFailure(error):
        return error
      case let .responseDecodingFailure(error):
        return error
      case let .dataLengthExceedsMaximum(error):
        return error
      }
    }

    public init?(rawValue: URLError) {
      switch rawValue.code {
      case .badServerResponse, .zeroByteResource:
        self = .receiveFailure(rawValue)
      case .cannotDecodeRawData, .cannotDecodeContentData, .cannotParseResponse:
        self = .responseDecodingFailure(rawValue)
      case .dataLengthExceedsMaximum:
        self = .dataLengthExceedsMaximum(rawValue)
      default:
        return nil
      }
    }
  }

  case responseProcessingFailure(ResponseProcessingFailureReason, Endpoint, URLRequest, HTTPURLResponse?)

  public enum EndpointFailureReason {
    case malformedResponseBody
    case jsonDataDecodeFailure(Data?, with: Error)

    case invalidArguments
    case invalidCharacter
    case invalidDeviceToken
    case invalidSubscribeKey
    case invalidPublishKey
    case maxChannelGroupCountExceeded
    case pushNotEnabled
    case messageHistoryNotEnabled
    case messageDeletionNotEnabled
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
  case endpointFailure(EndpointFailureReason, Endpoint, URLRequest, HTTPURLResponse)

  // When Error Occurred
  public enum SessionInvalidationReason {
    case explicit
    case implicit(dueTo: Error)
  }

  case sessionInvalidated(SessionInvalidationReason, sessionID: UUID?)
}

extension PNError {
  public var endpoint: Endpoint {
    switch self {
    case let .unknown(_, endpoint):
      return endpoint
    case let .unknownError(_, endpoint):
      return endpoint
    case let .missingRequiredParameter(endpoint):
      return endpoint
    case let .invalidEndpointType(endpoint):
      return endpoint
    case .sessionDeinitialized:
      return .unknown
    case let .requestRetryFailed(endpoint, _, _, _):
      return endpoint
    case let .requestCreationFailure(_, endpoint):
      return endpoint
    case let .requestTransmissionFailure(_, endpoint, _):
      return endpoint
    case let .responseProcessingFailure(_, endpoint, _, _):
      return endpoint
    case let .endpointFailure(_, endpoint, _, _):
      return endpoint
    case .sessionInvalidated:
      return .unknown
    }
  }

  static func convert(
    endpoint: Endpoint,
    error: URLError,
    request: URLRequest?,
    response: HTTPURLResponse?
  ) -> PNError? {
    guard let request = request else {
      return nil
    }

    if let transmissionErrorReason = RequestTransmissionFailureReason(rawValue: error) {
      return .requestTransmissionFailure(transmissionErrorReason, endpoint, request)
    } else if let responseErrorReason = ResponseProcessingFailureReason(rawValue: error) {
      return .responseProcessingFailure(responseErrorReason, endpoint, request, response)
    }

    return .unknownError(error, endpoint)
  }

  static func convert(
    endpoint: Endpoint,
    generalError payload: GenericServicePayloadResponse?,
    request: URLRequest,
    response: HTTPURLResponse?
  ) -> PNError {
    guard let response = response else {
      return PNError.unknown(message: ErrorDescription.UnknownErrorReason.endpointErrorMissingResponse, endpoint)
    }

    // Try to associate with a specific error message
    if let reason = PNError.lookupGeneralErrorMessage(using: payload?.message) {
      return PNError.endpointFailure(reason, endpoint, request, response)
    }

    // Try to associate with a general status code error
    let status = payload?.status ?? GenericServicePayloadResponse.Code(rawValue: response.statusCode)
    if let reason = PNError.lookupGeneralErrorStatus(using: status) {
      return PNError.endpointFailure(reason, endpoint, request, response)
    }

    return PNError.endpointFailure(.unknown(ErrorDescription.UnknownErrorReason.noAppropriateEndpointError),
                                   endpoint,
                                   request,
                                   response)
  }

  // swiftlint:disable:next cyclomatic_complexity
  static func lookupGeneralErrorMessage(
    using message: GenericServicePayloadResponse.Message?
  ) -> EndpointFailureReason? {
    switch message {
    case .couldNotParseRequest?:
      return .couldNotParseRequest
    case .some(.forbidden):
      return .forbidden
    case .some(.invalidArguments):
      return .invalidArguments
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
    case .some(.messageHistoryNotEnabled):
      return .messageHistoryNotEnabled
    case .some(.messageDeletionNotEnabled):
      return .messageDeletionNotEnabled
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
