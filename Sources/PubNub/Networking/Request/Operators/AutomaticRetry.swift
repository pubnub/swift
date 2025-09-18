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
  /// Retry on lost network connection
  public static var connectionLost = AutomaticRetry(policy: .defaultLinear, retryableURLErrorCodes: [.networkConnectionLost])
  /// Exponential backoff twice when no internet connection is detected
  public static var noInternet = AutomaticRetry(policy: .defaultExponential, retryableURLErrorCodes: [.notConnectedToInternet])

  // The minimum value allowed between retries
  static let minDelay: UInt = 2
  // The maximum value allowed between retries
  static let maxDelay: UInt = 150

  /// Provides the action taken when a retry is to be performed
  public enum ReconnectionPolicy: Hashable, Equatable {
    /// Exponential backoff with base/scale factor of 2, and a 150s max delay
    public static let defaultExponential: ReconnectionPolicy = .exponential(minDelay: minDelay, maxDelay: maxDelay)
    /// Linear reconnect every 3 seconds
    public static let defaultLinear: ReconnectionPolicy = .linear(delay: Double(3))

    /// Reconnect with an exponential backoff
    case exponential(minDelay: UInt, maxDelay: UInt)
    /// Attempt to reconnect every X seconds
    case linear(delay: Double)

    func delay(for retryAttempt: Int) -> TimeInterval {
      /// Generates a random interval that's added to the final value.
      /// Mitigates receiving 429 status code that's the result of too many requests in a given amount of time
      let randomDelay = Double.random(in: 0...1)

      switch self {
      case let .exponential(minDelay, maxDelay):
        return min(Double(maxDelay), Double(minDelay) * pow(2, Double(retryAttempt))) + randomDelay
      case let .linear(delay):
        return delay + randomDelay
      }
    }

    func maximumRetryLimit() -> Int {
      switch self {
      case .linear:
        return 10
      case .exponential:
        return 6
      }
    }
  }

  /// List of known endpoint groups (by context) possible to retry
  public enum Endpoint: String, CustomStringConvertible {
    /// Sending a message
    case messageSend
    /// Subscribing to channels and channel groups
    case subscribe
    /// Presence related methods
    case presence
    /// List Files, publish a File, remove a File
    /// - Important: File download and upload aren't part of retrying.
    case files
    /// History related methods
    case messageStorage
    /// Managing channel groups
    case channelGroups
    /// Managing devices to receive push notifications
    case devicePushNotifications
    /// Accessing and managing AppContext objects
    case appContext
    /// Accessing and managing Message Actions
    case messageActions

    public var description: String {
      rawValue
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
  /// The list of endpoints excluded from retrying
  public let excluded: [AutomaticRetry.Endpoint]
  /// Collection of validation warnings generated during initialization
  let validationWarnings: [String]

  /// The list of endpoints excluded from retrying by default
  public static let defaultExcludedEndpoints: [AutomaticRetry.Endpoint] = [
    .presence,
    .messageSend,
    .files,
    .messageStorage,
    .channelGroups,
    .devicePushNotifications,
    .appContext,
    .messageActions
  ]

  public init(
    retryLimit: UInt = 6,
    policy: ReconnectionPolicy = .defaultExponential,
    retryableHTTPStatusCodes: Set<Int> = [500, 429],
    retryableURLErrorCodes: Set<URLError.Code> = AutomaticRetry.defaultRetryableURLErrorCodes,
    excluded endpoints: [AutomaticRetry.Endpoint] = AutomaticRetry.defaultExcludedEndpoints
  ) {
    // Collect validation warnings
    var warnings: [String] = []

    self.policy = Self.validatePolicy(policy, warnings: &warnings)
    self.retryLimit = Self.validateRetryLimit(retryLimit, for: self.policy, warnings: &warnings)
    self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
    self.retryableURLErrorCodes = retryableURLErrorCodes
    self.excluded = endpoints
    self.validationWarnings = warnings
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

    let urlResponse = request.urlResponse
    let retryAfterValue = urlResponse?.allHeaderFields[Constant.retryAfterHeaderKey]

    if let retryAfterValue = retryAfterValue as? TimeInterval {
      return completion(.success(retryAfterValue + Double.random(in: 0...1)))
    } else {
      return completion(.success(policy.delay(for: request.retryCount)))
    }
  }

  public func retryOperator(for endpoint: AutomaticRetry.Endpoint) -> RequestOperator? {
    excluded.contains(endpoint) ? nil : self
  }

  func shouldRetry(response: HTTPURLResponse?, error: Error) -> Bool {
    if let statusCode = response?.statusCode {
      return retryableHTTPStatusCodes.contains(statusCode)
    } else if let errorCode = error.urlError?.code, retryableURLErrorCodes.contains(errorCode) {
      return true
    } else if let errorCode = error.pubNubError?.underlying?.urlError?.code, retryableURLErrorCodes.contains(errorCode) {
      return true
    }
    return false
  }
}

private extension AutomaticRetry {
  static func validate<T>(
    value: T,
    using condition: Bool,
    replaceOnFailure: T,
    warningMessage message: String,
    warnings: inout [String]
  ) -> T {
    guard condition else {
      warnings.append(message)
      return replaceOnFailure
    }
    return value
  }

  static func validatePolicy(_ policy: ReconnectionPolicy, warnings: inout [String]) -> ReconnectionPolicy {
    switch policy {
    case let .exponential(minDelay, maxDelay):
      let validatedMinDelay = Self.validate(
        value: minDelay,
        using: minDelay >= Self.minDelay,
        replaceOnFailure: Self.minDelay,
        warningMessage: "minDelay too low, using \(Self.minDelay)s",
        warnings: &warnings
      )
      let validatedMaxDelay = Self.validate(
        value: maxDelay,
        using: maxDelay >= validatedMinDelay && maxDelay <= Self.maxDelay,
        replaceOnFailure: max(validatedMinDelay, min(maxDelay, Self.maxDelay)),
        warningMessage: "maxDelay out of range, using \(max(validatedMinDelay, min(maxDelay, Self.maxDelay)))s",
        warnings: &warnings
      )
      return .exponential(
        minDelay: validatedMinDelay,
        maxDelay: validatedMaxDelay
      )
    case let .linear(delay):
      let validatedDelay = Self.validate(
        value: delay,
        using: delay >= Double(Self.minDelay) && delay <= Double(Self.maxDelay),
        replaceOnFailure: max(Double(Self.minDelay), min(delay, Double(Self.maxDelay))),
        warningMessage: "delay out of range, using \(max(Double(Self.minDelay), min(delay, Double(Self.maxDelay))))s",
        warnings: &warnings
      )
      return .linear(delay: validatedDelay)
    }
  }

  static func validateRetryLimit(_ retryLimit: UInt, for policy: ReconnectionPolicy, warnings: inout [String]) -> UInt {
    // Get the maximum retry limit for the policy
    let maxRetryLimit = UInt(policy.maximumRetryLimit())

    // Validate minimum retry limit (must be at least 1)
    let minLimit = Self.validate(
      value: retryLimit,
      using: retryLimit >= 1,
      replaceOnFailure: 1,
      warningMessage: "retryLimit must be at least 1, using 1",
      warnings: &warnings
    )

    // Validate maximum retry limit against policy
    let validatedRetryLimit = Self.validate(
      value: minLimit,
      using: minLimit <= maxRetryLimit,
      replaceOnFailure: maxRetryLimit,
      warningMessage: "retryLimit (\(minLimit)) exceeds maximum allowed for \(policy) policy, using \(maxRetryLimit)",
      warnings: &warnings
    )

    return validatedRetryLimit
  }
}
