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
  public static var connectionLost = AutomaticRetry(
    policy: .defaultLinear,
    retryableURLErrorCodes: [.networkConnectionLost]
  )
  /// Exponential backoff twice when no internet connection is detected
  public static var noInternet = AutomaticRetry(
    policy: .defaultExponential,
    retryableURLErrorCodes: [.notConnectedToInternet]
  )
  // The minimum value allowed between retries
  static let minDelay: UInt = 2

  /// Provides the action taken when a retry is to be performed
  public enum ReconnectionPolicy: Hashable, Equatable {
    /// Exponential backoff with base/scale factor of 2, and a 150s max delay
    public static let defaultExponential: ReconnectionPolicy = .legacyExponential(base: 2, scale: 2, maxDelay: 300)
    /// Linear reconnect every 3 seconds
    public static let defaultLinear: ReconnectionPolicy = .linear(delay: Double(3))

    /// Reconnect with an exponential backoff
    case exponential(minDelay: UInt, maxDelay: UInt)
    /// Attempt to reconnect every X seconds
    case linear(delay: Double)
    /// Reconnect with an exponential backoff
    @available(*, deprecated, message: "Use exponential(minDelay:maxDelay:) instead")
    case legacyExponential(base: UInt, scale: Double, maxDelay: UInt)

    func delay(for retryAttempt: Int) -> TimeInterval {
      /// Generates a random interval that's added to the final value
      /// Mitigates receiving 429 status code that's the result of too many requests in a given amount of time
      let randomDelay = Double.random(in: 0...1)

      switch self {
      case let .legacyExponential(base, scale, maxDelay):
        return legacyExponentialBackoffDelay(for: base, scale: scale, maxDelay: maxDelay, current: retryAttempt) + randomDelay
      case let .exponential(minDelay, maxDelay):
        return min(Double(maxDelay), Double(minDelay) * pow(2, Double(retryAttempt))) + randomDelay
      case let .linear(delay):
        return delay + randomDelay
      }
    }

    func legacyExponentialBackoffDelay(for base: UInt, scale: Double, maxDelay: UInt, current retryCount: Int) -> Double {
      max(min(pow(Double(base), Double(retryCount)) * scale, Double(maxDelay)), Double(AutomaticRetry.minDelay))
    }
  }

  /// List of known endpoint groups (by context) possible to retry
  public enum Endpoint {
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

  public init(
    retryLimit: UInt = 6,
    policy: ReconnectionPolicy = .defaultExponential,
    retryableHTTPStatusCodes: Set<Int> = [500, 429],
    retryableURLErrorCodes: Set<URLError.Code> = AutomaticRetry.defaultRetryableURLErrorCodes,
    excluded endpoints: [AutomaticRetry.Endpoint] = [
      .messageSend,
      .files,
      .messageStorage,
      .channelGroups,
      .devicePushNotifications,
      .appContext,
      .messageActions
    ]
  ) {
    self.retryLimit = Self.validate(
      value: UInt(retryLimit),
      using: retryLimit < 10,
      replaceOnFailure: UInt(10),
      warningMessage: "The `retryLimit` must be less than or equal 10"
    )

    switch policy {
    case let .exponential(minDelay, maxDelay):
      let validatedMinDelay = Self.validate(
        value: minDelay,
        using: minDelay > Self.minDelay,
        replaceOnFailure: Self.minDelay,
        warningMessage: "The `minDelay` must be a minimum of \(Self.minDelay)"
      )
      let validatedMaxDelay = Self.validate(
        value: maxDelay,
        using: maxDelay >= minDelay,
        replaceOnFailure: Self.minDelay,
        warningMessage: "The `maxDelay` must be greater than or equal \(Self.minDelay)"
      )
      self.policy = .exponential(
        minDelay: validatedMinDelay,
        maxDelay: validatedMaxDelay
      )
    case let .linear(delay):
      self.policy = .linear(delay: Self.validate(
        value: delay,
        using: delay >= Double(Self.minDelay),
        replaceOnFailure: Double(Self.minDelay),
        warningMessage: "The `linear.delay` must be greater than or equal \(Self.minDelay)."
      ))
    case let .legacyExponential(base, scale, maxDelay):
      self.policy = .legacyExponential(
        base: Self.validate(
          value: base,
          using: base >= 2,
          replaceOnFailure: 2,
          warningMessage: "The `exponential.base` must be a minimum of 2."
        ),
        scale: Self.validate(
          value: scale,
          using: scale > 0,
          replaceOnFailure: 0,
          warningMessage: "The `exponential.scale` must be a positive value."
        ),
        maxDelay: maxDelay
      )
    }

    self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
    self.retryableURLErrorCodes = retryableURLErrorCodes
    self.excluded = endpoints
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
  static func validate<T>(value: T, using condition: Bool, replaceOnFailure: T, warningMessage message: String) -> T {
    guard condition else {
      PubNub.log.warn(message); return replaceOnFailure
    }
    return value
  }
}
