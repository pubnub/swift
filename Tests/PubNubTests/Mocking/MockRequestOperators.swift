//
//  MockRequestOperators.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

struct DefaultOperator: RequestOperator, Equatable {
  let uuid = UUID()
}

class RetryExpector: RequestOperator {
  var retryCount = 0
  let expectation: XCTestExpectation

  init(expectedRetry count: Int = 2, all expectations: inout [XCTestExpectation]) {
    expectation = XCTestExpectation(description: "Retry Expector")
    expectation.expectedFulfillmentCount = count
    expectations.append(expectation)
  }

  var shouldRetry: ((RequestReplaceable, SessionReplaceable, Error, Int) -> (Result<TimeInterval, Error>))?

  func retry(
    _ request: RequestReplaceable,
    for session: SessionReplaceable,
    dueTo error: Error,
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  ) {
    let retry = shouldRetry?(request, session, error, retryCount)
    retryCount += 1
    completion(retry ?? .failure(error))
    expectation.fulfill()
  }
}

struct MutatorExpector: RequestOperator {
  let expectation: XCTestExpectation

  init(expectedRetry count: Int = 1, all expectations: inout [XCTestExpectation]) {
    expectation = XCTestExpectation(description: "Mutator Expector")
    expectation.expectedFulfillmentCount = count
    expectations.append(expectation)
  }

  var mutateRequest: ((URLRequest) -> (Result<URLRequest, Error>))?

  func mutate(
    _ urlRequest: URLRequest,
    for _: SessionReplaceable,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    completion(mutateRequest?(urlRequest) ?? .success(urlRequest))
    expectation.fulfill()
  }
}
