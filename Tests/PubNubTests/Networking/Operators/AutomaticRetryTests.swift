//
//  AutomaticRetryTests.swift
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

class AutomaticRetryTests: XCTestCase {
  let defaultLinearPolicy = AutomaticRetry.ReconnectionPolicy.defaultLinear
  let defaultExpoentialPolicy = AutomaticRetry.ReconnectionPolicy.defaultExponential

  func testReconnectionPolicy_DefaultLinearPolicy() {
    switch defaultLinearPolicy {
    case let .linear(delay):
      XCTAssertEqual(delay, 3)
    default:
      XCTFail("Default Linear Policy should only match to linear case")
    }
  }

  func testReconnectionPolicy_DefaultExponentialPolicy() {
    switch defaultExpoentialPolicy {
    case let .exponential(base, scale, max):
      XCTAssertEqual(base, 2)
      XCTAssertEqual(scale, 2)
      XCTAssertEqual(max, 300)
    default:
      XCTFail("Default Exponential Policy should only match to linear case")
    }
  }

  // MARK: - init() & Equatable

  func testEquatable_Init_Valid_() {
    let testPolicy = AutomaticRetry.default
    let policy = AutomaticRetry()

    XCTAssertEqual(testPolicy, policy)
  }

  func testEquatable_Init_Exponential_InvalidBase() {
    let invalidBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(base: 0, scale: 3.0, maxDelay: 1)
    let validBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(base: 2, scale: 3.0, maxDelay: 1)
    let testPolicy = AutomaticRetry(retryLimit: 2,
                                    policy: invalidBasePolicy,
                                    retryableHTTPStatusCodes: [],
                                    retryableURLErrorCodes: [])

    XCTAssertNotEqual(testPolicy.policy, invalidBasePolicy)
    XCTAssertEqual(testPolicy.policy, validBasePolicy)
  }

  func testEquatable_Init_Exponential_InvalidScale() {
    let invalidBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(base: 2, scale: -1.0, maxDelay: 1)
    let validBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(base: 2, scale: 0.0, maxDelay: 1)
    let testPolicy = AutomaticRetry(retryLimit: 2,
                                    policy: invalidBasePolicy,
                                    retryableHTTPStatusCodes: [],
                                    retryableURLErrorCodes: [])

    XCTAssertNotEqual(testPolicy.policy, invalidBasePolicy)
    XCTAssertEqual(testPolicy.policy, validBasePolicy)
  }

  func testEquatable_Init_Exponential_InvalidBaseAndScale() {
    let invalidBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(base: 0, scale: -1.0, maxDelay: 1)
    let validBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(base: 2, scale: 0.0, maxDelay: 1)
    let testPolicy = AutomaticRetry(retryLimit: 2,
                                    policy: invalidBasePolicy,
                                    retryableHTTPStatusCodes: [],
                                    retryableURLErrorCodes: [])

    XCTAssertNotEqual(testPolicy.policy, invalidBasePolicy)
    XCTAssertEqual(testPolicy.policy, validBasePolicy)
  }

  func testEquatable_Init_Linear_InvalidDelay() {
    let invalidBasePolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: -1.0)
    let validBasePolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: 0.0)
    let testPolicy = AutomaticRetry(retryLimit: 2,
                                    policy: invalidBasePolicy,
                                    retryableHTTPStatusCodes: [],
                                    retryableURLErrorCodes: [])

    XCTAssertNotEqual(testPolicy.policy, invalidBasePolicy)
    XCTAssertEqual(testPolicy.policy, validBasePolicy)
  }

  func testEquatable_Init_Linear_Valid() {
    let validLinearPolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: 1.0)
    let testPolicy = AutomaticRetry(retryLimit: 2,
                                    policy: validLinearPolicy,
                                    retryableHTTPStatusCodes: [],
                                    retryableURLErrorCodes: [])

    XCTAssertEqual(testPolicy.policy, validLinearPolicy)
  }

  func testEquatable_Init_Other() {
    let immediateasePolicy = AutomaticRetry.ReconnectionPolicy.immediately
    let testPolicy = AutomaticRetry(retryLimit: 2,
                                    policy: immediateasePolicy,
                                    retryableHTTPStatusCodes: [],
                                    retryableURLErrorCodes: [])

    XCTAssertEqual(testPolicy.policy, immediateasePolicy)
  }

  // MARK: - retry(:session:for:dueTo:completion:)

  func testRetry_RetryLimitReached() {}

  func testRetry_ShouldRetryTrue() {}

  func testRetry_WhitelistedError() {}

  func testRetry_Policy_None() {}

  func testRetry_Policy_Immediately() {}

  func testRetry_Policy_Linear() {}

  func testRetry_Policy_Exponential() {}

  // MARK: shouldRetry(response:error:)

  func testShouldRetry_True_StatusCodeMatch() {
    guard let url = URL(string: "http://example.com") else {
      return XCTFail("Could not create URL")
    }
    let testStatusCode = 500

    let testPolicy = AutomaticRetry(retryLimit: 2,
                                    policy: .immediately,
                                    retryableHTTPStatusCodes: [testStatusCode],
                                    retryableURLErrorCodes: [])
    let testResponse = HTTPURLResponse(url: url,
                                       statusCode: testStatusCode,
                                       httpVersion: nil,
                                       headerFields: [:])

    XCTAssertTrue(testPolicy.shouldRetry(response: testResponse,
                                         error: PubNubError(reason: .unknown)))
  }

  func testShouldRetry_True_ErrorCodeMatch() {
    let testURLErrorCode = URLError.Code.timedOut
    let testError = URLError(testURLErrorCode)
    let testPolicy = AutomaticRetry(retryLimit: 2,
                                    policy: .immediately,
                                    retryableHTTPStatusCodes: [],
                                    retryableURLErrorCodes: [testURLErrorCode])

    XCTAssertTrue(testPolicy.shouldRetry(response: nil,
                                         error: testError))
  }

  func testShouldRetry_False() {
    let testError = URLError(.timedOut)
    let testPolicy = AutomaticRetry(retryLimit: 2,
                                    policy: .immediately,
                                    retryableHTTPStatusCodes: [],
                                    retryableURLErrorCodes: [])

    XCTAssertFalse(testPolicy.shouldRetry(response: nil,
                                          error: testError))
  }

  // MARK: - exponentialBackoffDelay(for:scale:current:)

  func testExponentialBackoffDelay_DefaultScale() {
    let maxRetryCount = 5
    let scale = 2.0
    let base: UInt = 2
    let maxDelay: UInt = UInt.max

    let delayForRetry = [4.0, 8.0, 16.0, 32.0, 64.0]

    for count in 1 ... maxRetryCount {
      XCTAssertEqual(AutomaticRetry.ReconnectionPolicy
        .exponential(base: base, scale: scale, maxDelay: maxDelay).delay(for: count),
                     delayForRetry[count - 1])
    }
  }

  func testExponentialBackoffDelay_MaxDelayHit() {
    let maxRetryCount = 5
    let scale = 2.0
    let base: UInt = 2
    let maxDelay: UInt = 0

    let delayForRetry = [0.0, 0.0, 0.0, 0.0, 0.0]

    for count in 1 ... maxRetryCount {
      XCTAssertEqual(AutomaticRetry.ReconnectionPolicy
        .exponential(base: base, scale: scale, maxDelay: maxDelay).delay(for: count),
                     delayForRetry[count - 1])
    }
  }
}
