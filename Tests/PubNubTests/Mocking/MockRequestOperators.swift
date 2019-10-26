//
//  MockRequestOperators.swift
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

  var shouldRetry: ((Request, Session, Error, Int) -> (Result<TimeInterval, Error>))?

  func retry(
    _ request: Request,
    for session: Session,
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

  func mutate(_ urlRequest: URLRequest, for _: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
    completion(mutateRequest?(urlRequest) ?? .success(urlRequest))
    expectation.fulfill()
  }
}
