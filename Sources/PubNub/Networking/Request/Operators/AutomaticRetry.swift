//
//  AutomaticRetry.swift
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

extension URLError.Code: Codable {}

public struct AutomaticRetry: RequestOperator, Hashable {
  public static var `default` = AutomaticRetry()
  public static var none = AutomaticRetry(policy: .none)
  public static var connectionLost = AutomaticRetry(policy: .immediately,
                                                    retryableURLErrorCodes: [.networkConnectionLost])
  public static var noInternet = AutomaticRetry(policy: .defaultExponential,
                                                retryableURLErrorCodes: [.notConnectedToInternet])

  public enum ReconnectionPolicy: Hashable {
    public static let defaultExponential: ReconnectionPolicy = {
      .exponential(base: 2, scale: 2, maxDelay: 300)
    }()

    public static let defaultLinear: ReconnectionPolicy = {
      .linear(delay: 3)
    }()

    case none
    case immediately
    case exponential(base: UInt, scale: Double, maxDelay: UInt)
    case linear(delay: Double)
  }

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

  public static let defaultURLErrorCodesWhitelist: Set<URLError.Code> = [
    .cancelled
  ]

  public let retryLimit: UInt
  public let policy: ReconnectionPolicy
  public let retryableHTTPStatusCodes: Set<Int>
  public let retryableURLErrorCodes: Set<URLError.Code>
  public let whiltelistedURLErrorCodes: Set<URLError.Code>

  public init(retryLimit: UInt = 2,
              policy: ReconnectionPolicy = .defaultExponential,
              retryableHTTPStatusCodes: Set<Int> = [500],
              retryableURLErrorCodes: Set<URLError.Code> = AutomaticRetry.defaultRetryableURLErrorCodes,
              whiltelistedURLErrorCodes: Set<URLError.Code> = AutomaticRetry.defaultURLErrorCodesWhitelist) {
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
    default:
      self.policy = policy
    }

    self.retryLimit = retryLimit
    self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
    self.retryableURLErrorCodes = retryableURLErrorCodes
    self.whiltelistedURLErrorCodes = whiltelistedURLErrorCodes
  }

  public func retry(
    _ request: Request,
    for _: Session,
    dueTo error: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    guard request.retryCount < retryLimit, shouldRetry(response: request.urlResponse, error: error) else {
      if let errorCode = error.urlError?.code, whiltelistedURLErrorCodes.contains(errorCode) {
        completion(.doNotRetry)
      } else {
        completion(.doNotRetryWithError(error))
      }
      return
    }

    switch policy {
    case .none:
      completion(.doNotRetry)
    case .immediately:
      completion(.retryWithDelay(0))
    case let .linear(timeDelay):
      completion(.retryWithDelay(timeDelay))
    case let .exponential(base, scale, max):
      let timeDelay = exponentialBackoffDelay(for: base,
                                              scale: scale,
                                              maxDelay: max,
                                              current: request.retryCount)
      completion(.retryWithDelay(timeDelay))
    }
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

  func exponentialBackoffDelay(for base: UInt, scale: Double, maxDelay: UInt, current retryCount: Int) -> Double {
    return min(pow(Double(base), Double(retryCount)) * scale, Double(maxDelay))
  }
}
