//
//  AutomaticRetryTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class AutomaticRetryTests: XCTestCase {
  let defaultLinearPolicy = AutomaticRetry.ReconnectionPolicy.defaultLinear
  let defaultExpoentialPolicy = AutomaticRetry.ReconnectionPolicy.defaultExponential

  func testReconnectionPolicy_DefaultLinearPolicy() {
    switch defaultLinearPolicy {
    case let .linear(delay):
      XCTAssertEqual(delay, 2)
    default:
      XCTFail("Default Linear Policy should only match to linear case")
    }
  }

  func testReconnectionPolicy_DefaultExponentialPolicy() {
    switch defaultExpoentialPolicy {
    case let .exponential(minDelay, maxDelay):
      XCTAssertEqual(minDelay, 2)
      XCTAssertEqual(maxDelay, 150)
    default:
      XCTFail("Default Exponential Policy should only match to linear case")
    }
  }

  // MARK: - init() & Equatable

  func testEquatable_Init_Valid_() {
    let testPolicy = AutomaticRetry.default
    let automaticRetry = AutomaticRetry()

    XCTAssertEqual(testPolicy, automaticRetry)
  }

  func testEquatable_Init_Exponential_InvalidMinDelay() {
    let invalidBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: 0, maxDelay: 30)
    let validBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: 2, maxDelay: 30)
    let automaticRetry = AutomaticRetry(
      retryLimit: 2,
      policy: invalidBasePolicy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertNotEqual(automaticRetry.policy, invalidBasePolicy)
    XCTAssertEqual(automaticRetry.policy, validBasePolicy)
  }
  
  func testEquatable_Init_Exponential_MinDelayGreaterThanMaxDelay() {
    let invalidBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: 10, maxDelay: 5)
    let validBasePolicy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: 10, maxDelay: 10)
    let automaticRetry = AutomaticRetry(
      retryLimit: 2,
      policy: invalidBasePolicy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertNotEqual(automaticRetry.policy, invalidBasePolicy)
    XCTAssertEqual(automaticRetry.policy, validBasePolicy)
  }
  
  func testEquatable_Init_Exponential_TooHighRetryLimit() {
    let policy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: 5, maxDelay: 60)
    let automaticRetry = AutomaticRetry(
      retryLimit: 12,
      policy: policy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertEqual(automaticRetry.policy, policy)
    XCTAssertEqual(automaticRetry.retryLimit, 10)
  }

  func testEquatable_Init_Linear_InvalidDelay() {
    let invalidBasePolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: -1.0)
    let validBasePolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: 2.0)
    let automaticRetry = AutomaticRetry(
      retryLimit: 2,
      policy: invalidBasePolicy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertNotEqual(automaticRetry.policy, invalidBasePolicy)
    XCTAssertEqual(automaticRetry.policy, validBasePolicy)
  }
  
  func testEquatable_Init_Linear_TooHighRetryLimit() {
    let policy = AutomaticRetry.ReconnectionPolicy.linear(delay: 3.0)
    let automaticRetry = AutomaticRetry(
      retryLimit: 12,
      policy: policy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertEqual(automaticRetry.policy, policy)
    XCTAssertEqual(automaticRetry.retryLimit, 10)
  }

  func testEquatable_Init_Linear_Valid() {
    let validLinearPolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: 3.0)
    let automaticRetry = AutomaticRetry(
      retryLimit: 2,
      policy: validLinearPolicy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertEqual(automaticRetry.policy, validLinearPolicy)
  }

  func testEquatable_Init_Other() {
    let linearPolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: 3.0)
    let automaticRetry = AutomaticRetry(
      retryLimit: 2,
      policy: linearPolicy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertEqual(automaticRetry.policy, linearPolicy)
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

    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: .linear(delay: 3.0),
      retryableHTTPStatusCodes: [testStatusCode],
      retryableURLErrorCodes: []
    )
    let testResponse = HTTPURLResponse(
      url: url,
      statusCode: testStatusCode,
      httpVersion: nil,
      headerFields: [:]
    )

    XCTAssertTrue(testPolicy.shouldRetry(response: testResponse, error: PubNubError(.unknown)))
  }

  func testShouldRetry_True_ErrorCodeMatch() {
    let testURLErrorCode = URLError.Code.timedOut
    let testError = URLError(testURLErrorCode)
    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: .linear(delay: 3.0),
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: [testURLErrorCode]
    )

    XCTAssertTrue(testPolicy.shouldRetry(response: nil, error: testError))
  }

  func testShouldRetry_False() {
    let testError = URLError(.timedOut)
    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: .linear(delay: 3.0),
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertFalse(testPolicy.shouldRetry(response: nil, error: testError))
  }

  // MARK: - exponentialBackoffDelay(for:scale:current:)

  func testExponentialBackoffDelay_DefaultScale() {
    let maxRetryCount = 5
    let maxDelay = UInt.max
    // Usage of Range due to random delay (0...1) that's always added to the final value
    let delayForRetry: [ClosedRange<Double>] = [2.0...3.0, 4.0...5.0, 8.0...9.0, 16.0...17.0, 32.0...33.0]

    for count in 0..<maxRetryCount {
      let reconnectionPolicy = AutomaticRetry.ReconnectionPolicy.exponential(
        minDelay: 2,
        maxDelay: maxDelay
      )
      XCTAssertTrue(delayForRetry[count].contains(reconnectionPolicy.delay(for: count)))
    }
  }

  func testExponentialBackoffDelay_MaxDelayHit() {
    // Usage of Range due to random delay (0...1) that's always added to the final value
    let delayForRetry: [ClosedRange<Double>] = [2.0...3.0, 3.0...4.0, 3.0...4.0, 3.0...4.0, 3.0...4.0]
    let maxRetryCount = 5

    for count in 0..<maxRetryCount {
      let reconnectionPolicy = AutomaticRetry.ReconnectionPolicy.exponential(
        minDelay: 2,
        maxDelay: 3
      )
      XCTAssertTrue(delayForRetry[count].contains(reconnectionPolicy.delay(for: count)))
    }
  }
}
