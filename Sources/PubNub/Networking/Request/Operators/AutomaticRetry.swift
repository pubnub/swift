//
//  AutomaticRetry.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Reconnection policy which will be used if/when a request fails
public struct AutomaticRetry: RequestOperator, Hashable {
  /// Exponential backoff twice for any 500 response code or `URLError` contained in `defaultRetryableURLErrorCodes`
  public static var `default` = AutomaticRetry()
  /// No retry will be performed
  public static var none = AutomaticRetry(retryLimit: 1)
  /// Retry immediately twice on lost network connection
  public static var connectionLost = AutomaticRetry(policy: .immediately,
                                                    retryableURLErrorCodes: [.networkConnectionLost])
  /// Exponential backoff twice when no internet connection is detected
  public static var noInternet = AutomaticRetry(policy: .defaultExponential,
                                                retryableURLErrorCodes: [.notConnectedToInternet])

  /// Provides the action taken when a retry is to be performed
  public enum ReconnectionPolicy: Hashable {
    /// Exponential backoff with base/scale factor of 2, and a 300s max delay
    public static let defaultExponential: ReconnectionPolicy = .exponential(base: 2, scale: 2, maxDelay: 300)

    /// Linear reconnect every 3 seconds
    public static let defaultLinear: ReconnectionPolicy = .linear(delay: 3)

    /// Attempt to reconnect immediately
    case immediately
    /// Reconnect with an exponential backoff
    case exponential(base: UInt, scale: Double, maxDelay: UInt)
    /// Attempt to reconnect every X seconds
    case linear(delay: Double)

    func delay(for retryAttempt: Int) -> TimeInterval {
      switch self {
      case .immediately:
        return 0.0
      case let .exponential(base, scale, maxDelay):
        return exponentialBackoffDelay(for: base, scale: scale, maxDelay: maxDelay, current: retryAttempt)
      case let .linear(delay):
        return delay
      }
    }

    func exponentialBackoffDelay(for base: UInt, scale: Double, maxDelay: UInt, current retryCount: Int) -> Double {
      return min(pow(Double(base), Double(retryCount)) * scale, Double(maxDelay))
    }
  }

  /// Collection of default `URLError.Code` objects that will trigger a retry
  public static let defaultRetryableURLErrorCodes: Set<URLError.Code> = [
    .badServerResponse,
    .callIsActive,
    .cannotConnectToHost,
    .cannotFindHost,
    .cannotLoadFromNetwork,
    .dataNotAllowed,
    .dnsLookupFailed,
    .internationalRoamingOff,
    .networkConnectionLost,
    .notConnectedToInternet,
    .secureConnectionFailed,
    .serverCertificateHasBadDate,
    .serverCertificateNotYetValid,
    .timedOut
  ]

  /// The max amount of retries before returning an error
  public let retryLimit: UInt
  /// The policy for when a retry will occurr
  public let policy: ReconnectionPolicy
  /// Collection of returned HTTP Status Codes  that will trigger a retry
  public let retryableHTTPStatusCodes: Set<Int>
  /// Collection of returned `URLError.Code` objects that will trigger a retry
  public let retryableURLErrorCodes: Set<URLError.Code>

  public init(
    retryLimit: UInt = 2,
    policy: ReconnectionPolicy = .defaultExponential,
    retryableHTTPStatusCodes: Set<Int> = [500],
    retryableURLErrorCodes: Set<URLError.Code> = AutomaticRetry.defaultRetryableURLErrorCodes
  ) {
    switch policy {
    case let .exponential(base, scale, max):
      switch (true, true) {
      case (base < 2, scale < 0):
        PubNub.log.warn("The `exponential.base` must be a minimum of 2.")
        PubNub.log.warn("The `exponential.scale` must be a positive value.")
        self.policy = .exponential(base: 2, scale: 0, maxDelay: max)
      case (base < 2, scale >= 0):
        PubNub.log.warn("The `exponential.base` must be a minimum of 2.")
        self.policy = .exponential(base: 2, scale: scale, maxDelay: max)
      case (base >= 2, scale < 0):
        PubNub.log.warn("The `exponential.scale` must be a positive value.")
        self.policy = .exponential(base: base, scale: 0, maxDelay: max)
      default:
        self.policy = policy
      }
    case let .linear(delay):
      if delay < 0 {
        PubNub.log.warn("The `linear.delay` must be a positive value.")
        self.policy = .linear(delay: 0)
      } else {
        self.policy = policy
      }
    case .immediately:
      self.policy = policy
    }

    self.retryLimit = retryLimit
    self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
    self.retryableURLErrorCodes = retryableURLErrorCodes
  }

  public func retry(
    _ request: RequestReplaceable,
    for _: SessionReplaceable,
    dueTo error: Error,
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  ) {
    guard request.retryCount < retryLimit, shouldRetry(response: request.urlResponse, error: error) else {
      completion(.failure(error))
      return
    }

    return completion(.success(policy.delay(for: request.retryCount)))
  }

  func shouldRetry(response: HTTPURLResponse?, error: Error) -> Bool {
    if let statusCode = response?.statusCode, retryableHTTPStatusCodes.contains(statusCode) {
      return true
    } else if let errorCode = error.urlError?.code, retryableURLErrorCodes.contains(errorCode) {
      return true
    } else if let errorCode = error.pubNubError?.underlying?.urlError?.code,
              retryableURLErrorCodes.contains(errorCode) {
      return true
    }

    return false
  }
}
