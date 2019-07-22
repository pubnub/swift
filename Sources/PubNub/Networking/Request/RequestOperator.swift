//
//  RequestOperator.swift
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

// MARK: - RequestMutator

public protocol RequestMutator {
  func mutate(
    _ urlRequest: URLRequest,
    for session: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  )
}

// MARK: - Retry

public enum RetryResult {
  case retry
  case retryWithDelay(TimeInterval)
  case doNotRetry
  case doNotRetryWithError(Error)
}

extension RetryResult {
  var isRequired: Bool {
    switch self {
    case .retry, .retryWithDelay:
      return true
    default:
      return false
    }
  }

  var delay: TimeInterval? {
    switch self {
    case let .retryWithDelay(delay):
      return delay
    default:
      return nil
    }
  }

  var error: Error? {
    guard case let .doNotRetryWithError(error) = self else { return nil }
    return error
  }
}

public protocol RequestRetrier {
  func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void)
}

// MARK: - Operator

public protocol RequestOperator: RequestMutator, RequestRetrier {}

extension RequestOperator {
  public func mutate(
    _ urlRequest: URLRequest,
    for _: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    completion(.success(urlRequest))
  }

  public func retry(
    _: Request,
    for _: Session,
    dueTo _: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    completion(.doNotRetry)
  }
}

// MARK: - Multiplexor Operator

public struct MultiplexRequestOperaptor: RequestOperator {
  public let mutators: [RequestMutator]
  public let retriers: [RequestRetrier]

  public init(mutator: RequestMutator? = nil, retrier: RequestRetrier? = nil) {
    if let mutator = mutator {
      mutators = [mutator]
    } else {
      mutators = []
    }
    if let retrier = retrier {
      retriers = [retrier]
    } else {
      retriers = []
    }
  }

  public init(mutators: [RequestMutator] = [], retriers: [RequestRetrier] = []) {
    self.mutators = mutators
    self.retriers = retriers
  }

  public func mutate(
    _ urlRequest: URLRequest,
    for session: Session,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    mutate(urlRequest, for: session, using: mutators, completion: completion)
  }

  private func mutate(
    _ urlRequest: URLRequest,
    for session: Session,
    using mutators: [RequestMutator],
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    var pendingMutators = mutators

    guard !pendingMutators.isEmpty else {
      completion(.success(urlRequest))
      return
    }

    let mutator = pendingMutators.removeFirst()

    mutator.mutate(urlRequest, for: session) { result in
      switch result {
      case let .success(urlRequest):
        self.mutate(urlRequest, for: session, using: pendingMutators, completion: completion)
      case .failure:
        completion(result)
      }
    }
  }

  public func retry(
    _ request: Request,
    for session: Session,
    dueTo error: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    retry(request, for: session, dueTo: error, using: retriers, completion: completion)
  }

  private func retry(
    _ request: Request,
    for session: Session,
    dueTo error: Error,
    using retriers: [RequestRetrier],
    completion: @escaping (RetryResult) -> Void
  ) {
    var pendingRetriers = retriers

    guard !pendingRetriers.isEmpty else {
      completion(.doNotRetry)
      return
    }

    let retrier = pendingRetriers.removeFirst()

    retrier.retry(request, for: session, dueTo: error) { result in
      switch result {
      case .retry, .retryWithDelay, .doNotRetryWithError:
        completion(result)
      case .doNotRetry:
        // Only continue to the next retrier if retry was not triggered and no error was encountered
        self.retry(request, for: session, dueTo: error, using: pendingRetriers, completion: completion)
      }
    }
  }
}
