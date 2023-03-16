//
//  PubNubError.swift
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

// swiftlint:disable:next type_body_length
public struct PubNubError: Error {
  // MARK: - Properties

  /// The reason why the error occurred
  public let reason: Reason
  /// Any additional details about why the error occurred
  public let details: [String]
  /// The underlying `Error` that caused this `Error` to happen
  public let underlying: Error?

  let coorelation: [CorrelationIdentifier]
  public let affected: [AffectedValue]

  let router: HTTPRouter?

  /// The domain of the `Error`
  public let domain = "PubNub"
  /// The subdomain that this error can be categorized with
  public var subdomain: Domain {
    return reason.domain
  }

  // MARK: - Nested Objects

  enum CorrelationIdentifier: Hashable {
    case pubnub(UUID)
    case session(UUID)
    case request(UUID)
    case urlTask(Int)
  }

  public enum AffectedValue: CaseAccessible, Hashable {
    case uuid(UUID)
    case string(String)
    case data(Data)
    case request(URLRequest)
    case response(HTTPURLResponse)
    case json(AnyJSON)
    case subscribe(SubscribeCursor)
    case channels([String])
    case channelGroups([String])
  }

  /// The PubNubError specific Domain that groups together the different Reasons
  public enum Domain: Int, Error, Hashable, Codable, LocalizedError {
    case urlCreation
    case jsonCodability
    case requestProcessing
    case crypto
    case requestTransmission
    case responseReceiving
    case responseProcessing
    case endpointResponse
    case serviceNotEnabled
    case uncategorized
    case cancellation
    case fileManagement
    case streamFailure
  }

  /// The Reason that causes a PubNubError to occur
  public enum Reason: Int, Equatable, Hashable, Codable {
    // URL Creation Errors
    case missingRequiredParameter
    case invalidEndpointType
    case missingPublishKey
    case missingSubscribeKey
    case missingPublishAndSubscribeKey

    // JSON Errors
    case jsonStringEncodingFailure
    case jsonStringDecodingFailure
    case jsonDataEncodingFailure
    case jsonDataDecodingFailure

    // Crypto
    case missingCryptoKey

    // Request Processing
    case requestMutatorFailure
    case requestRetryFailed

    // Background Session
    case backgroundUpdatesDisabled
    case backgroundInsufficientResources
    case backgroundUserForceQuitApplication

    // Request Transmission
    case timedOut
    case nameResolutionFailure
    case invalidURL
    case connectionFailure
    case connectionOverDataFailure
    case connectionLost
    case secureConnectionFailure
    case certificateTrustFailure

    // Cancellation
    case sessionDeinitialized
    case sessionInvalidated
    case clientCancelled
    case longPollingRestart
    case longPollingReset

    // Response Received
    case badServerResponse
    case responseDecodingFailure
    case dataLengthExceedsMaximum

    // Response Processing
    case missingCriticalResponseData
    case unrecognizedStatusCode
    case malformedResponseBody

    // Endpoint Response
    case invalidArguments
    case invalidCharacter
    case invalidDevicePushToken
    case invalidSubscribeKey
    case invalidPublishKey
    case maxChannelGroupCountExceeded
    case couldNotParseRequest
    case requestContainedInvalidJSON
    case messageCountExceededMaximum
    case messageTooLong
    case invalidUUID
    case nothingToDelete
    case failedToPublish

    // Stream Errors
    case streamCouldNotBeInitialized
    case inputStreamFailure
    case outputStreamFailure

    // File Management
    case fileMissingAtPath
    case fileTooLarge
    case fileAccessDenied
    case fileContentLength

    // Service Not Enabled
    case pushNotEnabled
    case messageHistoryNotEnabled
    case messageDeletionNotEnabled
    case multiplexingNotEnabled

    // Uncategorized
    case protocolTranscodingFailure
    case unknown

    // HTTP Response Code Errors
    // Don't put non-response code errors below here
    case badRequest = 400
    case unauthorized = 401
    case serviceNotEnabled = 402
    case forbidden = 403
    case resourceNotFound = 404
    case conflict = 409
    case preconditionFailed = 412
    case requestURITooLong = 414
    case tooManyRequests = 429
    case unsupportedType = 415
    case malformedFilterExpression = 481
    case internalServiceError = 500
    case serviceUnavailable = 503

    /// The domain this error belongs to
    public var domain: PubNubError.Domain {
      switch self {
      case .missingRequiredParameter, .invalidEndpointType, .missingPublishKey,
           .missingSubscribeKey, .missingPublishAndSubscribeKey:
        return .urlCreation
      case .jsonStringEncodingFailure, .jsonStringDecodingFailure, .jsonDataEncodingFailure, .jsonDataDecodingFailure:
        return .jsonCodability
      case .missingCryptoKey:
        return .crypto
      case .requestMutatorFailure, .requestRetryFailed:
        return .requestProcessing
      case .timedOut, .nameResolutionFailure, .invalidURL,
           .connectionFailure, .connectionOverDataFailure, .connectionLost,
           .secureConnectionFailure, .certificateTrustFailure, .backgroundUpdatesDisabled,
           .backgroundInsufficientResources, .backgroundUserForceQuitApplication:
        return .requestTransmission
      case .clientCancelled, .sessionDeinitialized, .sessionInvalidated, .longPollingRestart, .longPollingReset:
        return .cancellation
      case .badServerResponse, .responseDecodingFailure, .dataLengthExceedsMaximum:
        return .responseReceiving
      case .missingCriticalResponseData, .unrecognizedStatusCode, .malformedResponseBody:
        return .responseProcessing
      case .invalidArguments, .invalidCharacter, .invalidDevicePushToken,
           .invalidSubscribeKey, .invalidPublishKey, .maxChannelGroupCountExceeded, .couldNotParseRequest,
           .requestContainedInvalidJSON, .serviceUnavailable, .messageCountExceededMaximum,
           .badRequest, .conflict, .preconditionFailed, .tooManyRequests, .unsupportedType,
           .unauthorized, .forbidden, .resourceNotFound, .requestURITooLong, .malformedFilterExpression,
           .internalServiceError, .messageTooLong, .invalidUUID, .nothingToDelete, .failedToPublish, .serviceNotEnabled:
        return .endpointResponse
      case .pushNotEnabled, .messageDeletionNotEnabled, .messageHistoryNotEnabled, .multiplexingNotEnabled:
        return .serviceNotEnabled
      case .unknown, .protocolTranscodingFailure:
        return .uncategorized
      case .streamCouldNotBeInitialized, .inputStreamFailure, .outputStreamFailure:
        return .streamFailure
      case .fileTooLarge, .fileMissingAtPath, .fileAccessDenied, .fileContentLength:
        return .fileManagement
      }
    }
  }

  // MARK: - Init

  init(
    _ reason: Reason,
    router: HTTPRouter? = nil,
    coorelation identifiers: [CorrelationIdentifier] = [],
    underlying error: Error? = nil,
    additional details: [String] = [],
    affected: [AffectedValue] = []
  ) {
    self.router = router
    self.reason = reason
    coorelation = identifiers
    underlying = error
    self.details = details
    self.affected = affected
  }

  init(
    reason: Reason?,
    router: HTTPRouter?,
    request: URLRequest?,
    response: HTTPURLResponse?,
    additional details: [ErrorDetail]? = nil,
    affectedChannels channels: [String]? = nil,
    affectedChannelGroups channelGroups: [String]? = nil
  ) {
    var reasonOrResponse = reason

    var affectedValues = [AffectedValue]()

    if let request = request {
      affectedValues.append(.request(request))
    }
    if let response = response {
      reasonOrResponse = reasonOrResponse ?? Reason(rawValue: response.statusCode)
      affectedValues.append(.response(response))
    }
    if let channels = channels {
      affectedValues.append(.channels(channels))
    }
    if let channelGroups = channelGroups {
      affectedValues.append(.channelGroups(channelGroups))
    }

    self.init(reasonOrResponse ?? .unrecognizedStatusCode,
              router: router,
              additional: details?.compactMap { $0.message } ?? [],
              affected: affectedValues)
  }

  init(router: HTTPRouter, request: URLRequest, response: HTTPURLResponse) {
    self.init(
      reason: PubNubError.Reason(rawValue: response.statusCode),
      router: router,
      request: request,
      response: response
    )
  }

  init<ResponseType>(
    _ reason: Reason,
    response: EndpointResponse<ResponseType>,
    error: Error? = nil,
    affected values: [AffectedValue] = []
  ) {
    let affectedValues = [.request(response.request), .response(response.response)] + values

    if let error = error {
      self.init(reason,
                router: response.router,
                underlying: error,
                affected: affectedValues)
    }
    self.init(reason,
              router: response.router,
              affected: affectedValues)
  }
}

// MARK: - Hashable

extension PubNubError: Hashable {
  public static func == (lhs: PubNubError, rhs: PubNubError) -> Bool {
    return lhs.reason == rhs.reason
  }

  public func hash(into hasher: inout Hasher) {
    reason.rawValue.hash(into: &hasher)
  }
}

// MARK: - Error Coersion Helpers

extension PubNubError {
  static func convert(_ error: Error, router: HTTPRouter, default reason: Reason = .unknown) -> PubNubError {
    if let pubnub = error.pubNubError {
      return pubnub
    } else if let reason = error.genericPubNubReason {
      return PubNubError(reason, router: router, underlying: error)
    } else {
      return PubNubError(reason, router: router, underlying: error)
    }
  }

  static func urlCreation(_ error: Error, router: HTTPRouter) -> PubNubError {
    return PubNubError.convert(error, router: router, default: .invalidURL)
  }

  static func sessionDelegate(_ error: Error, router: HTTPRouter) -> PubNubError {
    return PubNubError.convert(error, router: router, default: .unknown)
  }

  static func retry(_ error: Error, router: HTTPRouter) -> PubNubError {
    return PubNubError.convert(error, router: router, default: .requestRetryFailed)
  }

  static func cancellation(_ reason: Reason?, error: Error?, router: HTTPRouter) -> PubNubError {
    if let reason = reason {
      return PubNubError(reason, router: router, underlying: error)
    }

    if let pubnub = error?.pubNubError {
      return pubnub
    } else if let urlError = error?.urlError {
      return PubNubError(.clientCancelled, router: router, underlying: urlError)
    } else {
      return PubNubError(.clientCancelled, router: router, underlying: error)
    }
  }

  static func event(_ error: Error, router: HTTPRouter?) -> PubNubError {
    if let pubnub = error.pubNubError {
      return pubnub
    } else if let urlError = error.urlError {
      return PubNubError(.clientCancelled, router: router, underlying: urlError)
    } else {
      return PubNubError(.unknown, router: router, underlying: error)
    }
  }
}

// MARK: - Cross-Type Equatable

public extension Optional where Wrapped == PubNubError {
  /// Returns a Boolean value indicating whether two values are equal.
  /// - Parameter lhs: The value to compare
  /// - Parameter rhs: The other value to compare
  static func == (lhs: Optional, rhs: PubNubError.Reason?) -> Bool {
    return lhs?.reason == rhs
  }

  /// Returns a Boolean value indicating whether two values are not equal.
  /// - Parameter lhs: The value to compare
  /// - Parameter rhs: The other value to compare
  static func != (lhs: Optional, rhs: PubNubError.Reason?) -> Bool {
    return lhs?.reason != rhs
  }
}

public extension Optional where Wrapped == PubNubError.Reason {
  /// Returns a Boolean value indicating whether two values are equal.
  /// - Parameter lhs: The value to compare
  /// - Parameter rhs: The other value to compare
  static func == (lhs: Optional, rhs: PubNubError?) -> Bool {
    return lhs == rhs?.reason
  }

  /// Returns a Boolean value indicating whether two values are not equal.
  /// - Parameter lhs: The value to compare
  /// - Parameter rhs: The other value to compare
  static func != (lhs: Optional, rhs: PubNubError?) -> Bool {
    return lhs != rhs?.reason
  }
}

// MARK: - Conversions

public extension PubNubError {
  /// The underlying `URLError`, if one exists
  var urlError: URLError? {
    return underlying?.urlError
  }
}

extension EndpointResponseMessage {
  var pubnubReason: PubNubError.Reason? {
    switch self {
    case .acknowledge:
      return nil
    case .badRequest:
      return .badRequest
    case .conflict:
      return .conflict
    case .couldNotParseRequest:
      return .couldNotParseRequest
    case .forbidden:
      return .forbidden
    case .internalServiceError:
      return .internalServiceError
    case .invalidArguments:
      return .invalidArguments
    case .invalidCharacter:
      return .invalidCharacter
    case .invalidDeviceToken:
      return .invalidDevicePushToken
    case .invalidSubscribeKey:
      return .invalidSubscribeKey
    case .invalidPublishKey:
      return .invalidPublishKey
    case .invalidJSON:
      return .requestContainedInvalidJSON
    case .maxChannelGroupCountExceeded:
      return .maxChannelGroupCountExceeded
    case .notFound:
      return .resourceNotFound
    case .preconditionFailed:
      return .preconditionFailed
    case .pushNotEnabled:
      return .pushNotEnabled
    case .messageHistoryNotEnabled:
      return .messageHistoryNotEnabled
    case .messageDeletionNotEnabled:
      return .messageDeletionNotEnabled
    case .multiplexingNotEnabled:
      return .multiplexingNotEnabled
    case .requestURITooLong:
      return .requestURITooLong
    case .serviceUnavailable:
      return .serviceUnavailable
    case .tooManyRequests:
      return .tooManyRequests
    case .unsupportedType:
      return .unsupportedType
    case .messageTooLong:
      return .messageTooLong
    case .invalidUUID:
      return .invalidUUID
    case .nothingToDelete:
      return .nothingToDelete
    case .unknown:
      return .unknown
    case .successFailedToPublishEvent:
      return .failedToPublish
    }
  }
}

extension AnyJSONError {
  var pubnubReason: PubNubError.Reason {
    switch self {
    case .unknownCoding:
      return .jsonDataDecodingFailure
    case .stringCreationFailure:
      return .jsonStringEncodingFailure
    case .dataCreationFailure:
      return .jsonDataEncodingFailure
    }
  }

  var underlying: Error? {
    switch self {
    case let .unknownCoding(error):
      return error
    case let .stringCreationFailure(error):
      return error
    case let .dataCreationFailure(error):
      return error
    }
  }
}

extension URLError {
  var pubnubCancellationReason: PubNubError.Reason {
    if #available(iOS 13.0, macOS 10.15, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, *) {
      switch backgroundTaskCancelledReason {
      case .some(.backgroundUpdatesDisabled):
        return .backgroundUpdatesDisabled
      case .some(.insufficientSystemResources):
        return .backgroundInsufficientResources
      case .some(.userForceQuitApplication):
        return .backgroundUserForceQuitApplication
      default:
        return .clientCancelled
      }
    } else {
      return .clientCancelled
    }
  }

  var pubnubReason: PubNubError.Reason? {
    switch code {
    case .cancelled:
      return pubnubCancellationReason
    case .unknown:
      return .unknown
    case .timedOut:
      return .timedOut
    case .cannotFindHost, .dnsLookupFailed:
      return .nameResolutionFailure
    case .badURL, .unsupportedURL:
      return .invalidURL
    case .cannotConnectToHost, .resourceUnavailable, .notConnectedToInternet:
      return .connectionFailure
    case .internationalRoamingOff, .callIsActive, .dataNotAllowed:
      return .connectionOverDataFailure
    case .networkConnectionLost:
      return .connectionLost
    case .secureConnectionFailed:
      return .secureConnectionFailure
    case .appTransportSecurityRequiresSecureConnection,
         .serverCertificateHasBadDate,
         .serverCertificateUntrusted,
         .serverCertificateHasUnknownRoot,
         .serverCertificateNotYetValid,
         .clientCertificateRejected,
         .clientCertificateRequired:
      return .certificateTrustFailure
    case .badServerResponse, .zeroByteResource:
      return .badServerResponse
    case .cannotDecodeRawData, .cannotDecodeContentData, .cannotParseResponse:
      return .responseDecodingFailure
    case .dataLengthExceedsMaximum:
      return .dataLengthExceedsMaximum
    default:
      return nil
    }
  }
}

extension Collection where Element == PubNubError.AffectedValue {
  func findFirst<AssociatedValue>(by casePath: (AssociatedValue) -> Element) -> AssociatedValue? {
    for value in self {
      if let associatedValue = value[case: casePath] {
        return associatedValue
      }
    }
    return nil
  }

  // swiftlint:disable:next file_length
}
