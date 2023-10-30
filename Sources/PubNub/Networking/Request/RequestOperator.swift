//
//  RequestOperator.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - RequestMutator

/// Mutation performed on a request prior to transmission
public protocol RequestMutator {
  /// Async function that will mutate the request
  ///
  /// - Parameters:
  ///   - urlRequest: The request to mutate
  ///   - for: The Session that is going to execute the request
  ///   - completion: The mutation `Result` containing either a mutated `URLRequest` or an `Error`
  func mutate(
    _ urlRequest: URLRequest,
    for session: SessionReplaceable,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  )
}

/// Retry action performed after a failed request
public protocol RequestRetrier {
  /// Method that determines if and how the retry should be performed
  ///
  /// - Parameters:
  ///   - request: The request to mutate
  ///   - for: The Session that is going to execute the request
  ///   - dueTo: The `Error` that caused the request to fail
  ///   - completion: The retry `Result` containing either the `TimeInterval` delay for the retry or an `Error`
  func retry(
    _ request: RequestReplaceable,
    for session: SessionReplaceable,
    dueTo error: Error,
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  )
}

// MARK: - Operator

/// An operation that performs some change on a request
public protocol RequestOperator: RequestMutator, RequestRetrier {}

public extension RequestOperator {
  func mutate(
    _ urlRequest: URLRequest,
    for _: SessionReplaceable,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    completion(.success(urlRequest))
  }

  func retry(
    _: RequestReplaceable,
    for _: SessionReplaceable,
    dueTo error: Error,
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  ) {
    completion(.failure(error))
  }

  /// Merge a collection of RequestOperator into a single RequestOperator
  ///
  /// - Parameter operators: The collection of operators to consolidate
  /// - Returns: A single `RequestOperator` that performs the functionality of the merged operators
  func merge(operators: [RequestOperator]) -> RequestOperator {
    var mergedOperators: [RequestOperator] = [self]
    mergedOperators.append(contentsOf: operators)
    return MultiplexRequestOperator(operators: mergedOperators)
  }

  /// Merge an optional RequestOperator into a single RequestOperator
  ///
  /// - Parameter requestOperator: The optional `RequestOperator` to merge
  /// - Returns: A single `RequestOperator` that performs the functionality of the merged operators
  func merge(requestOperator: RequestOperator?) -> RequestOperator {
    if let requestOperator = requestOperator {
      return merge(operators: [requestOperator])
    }
    return self
  }
}

// MARK: - Multiplexor Operator

/// A complex `RequestOperator` that can contain 1-N other `RequestOperator`s
public struct MultiplexRequestOperator: RequestOperator {
  /// The collection of `RequestOperator` that will be performed
  public let operators: [RequestOperator]

  public init(requestOperator: RequestOperator? = nil) {
    if let requestOperator = requestOperator {
      self.init(operators: [requestOperator])
    } else {
      self.init(operators: [])
    }
  }

  public init(operators: [RequestOperator] = []) {
    var flatOperators = [RequestOperator]()
    // Flatten out any nested multiplex operators
    operators.forEach { requestOperator in
      if let multiplex = requestOperator as? MultiplexRequestOperator {
        multiplex.operators.forEach { flatOperators.append($0) }
      } else {
        flatOperators.append(requestOperator)
      }
    }
    self.operators = operators
  }

  public func mutate(
    _ urlRequest: URLRequest,
    for session: SessionReplaceable,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    mutate(urlRequest, for: session, using: operators, completion: completion)
  }

  /// Loop through the stored operator list and perform the mutate functionality of each
  private func mutate(
    _ urlRequest: URLRequest,
    for session: SessionReplaceable,
    using mutators: [RequestOperator],
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
    _ request: RequestReplaceable,
    for session: SessionReplaceable,
    dueTo error: Error,
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  ) {
    retry(request, for: session, dueTo: error, using: operators, completion: completion)
  }

  /// Loop through the stored operator list and perform the retry functionality of each
  private func retry(
    _ request: RequestReplaceable,
    for session: SessionReplaceable,
    dueTo error: Error,
    using retriers: [RequestOperator],
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  ) {
    var pendingRetriers = retriers

    guard !pendingRetriers.isEmpty else {
      completion(.failure(error))
      return
    }

    let retrier = pendingRetriers.removeFirst()

    retrier.retry(request, for: session, dueTo: error) { result in
      switch result {
      case .success:
        completion(result)
      case let .failure(error):
        self.retry(request, for: session, dueTo: error, using: pendingRetriers, completion: completion)
      }
    }
  }
}
