//
//  AutomaticRetryTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

class AutomaticRetryTests: XCTestCase {
  let defaultLinearPolicy = AutomaticRetry.ReconnectionPolicy.defaultLinear
  let defaultExpoentialPolicy = AutomaticRetry.ReconnectionPolicy.defaultExponential

  func test_ReconnectionPolicy_DefaultLinear_HasDelayOfThree() {
    switch defaultLinearPolicy {
    case let .linear(delay):
      XCTAssertEqual(delay, 3)
    default:
      XCTFail("Default Linear Policy should only match to linear case")
    }
  }

  func test_ReconnectionPolicy_DefaultExponential_HasMinTwoMaxOneHundredFifty() {
    switch defaultExpoentialPolicy {
    case let .exponential(minDelay, maxDelay):
      XCTAssertEqual(minDelay, 2)
      XCTAssertEqual(maxDelay, 150)
    default:
      XCTFail("Default Exponential Policy should only match to linear case")
    }
  }

  // MARK: - init() & Equatable

  func test_DefaultInit_MatchesDefaultPolicy() {
    let testPolicy = AutomaticRetry.default
    let policy = AutomaticRetry()

    XCTAssertEqual(testPolicy, policy)
  }

  func test_InitWithInvalidLinearDelay_ClampsToMinimumDelay() {
    let invalidBasePolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: -1.0)
    let validBasePolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: 2.0)

    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: invalidBasePolicy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertNotEqual(testPolicy.policy, invalidBasePolicy)
    XCTAssertEqual(testPolicy.policy, validBasePolicy)
  }

  func test_InitWithValidLinearDelay_PreservesPolicy() {
    let validLinearPolicy = AutomaticRetry
      .ReconnectionPolicy
      .linear(delay: 2.0)

    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: validLinearPolicy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertEqual(testPolicy.policy, validLinearPolicy)
  }

  // MARK: shouldRetry(response:error:)

  func test_ResponseMatchesRetryableStatusCode_ReturnsTrue() throws {
    let url = try XCTUnwrap(URL(string: "http://example.com"))
    let testStatusCode = 500

    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: .linear(delay: 2.0),
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

  func test_ResponseIsTooManyRequests_ReturnsTrue() throws {
    let url = try XCTUnwrap(URL(string: "http://example.com"))
    let testStatusCode = 429

    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: .linear(delay: 2.0)
    )
    let testResponse = HTTPURLResponse(
      url: url,
      statusCode: testStatusCode,
      httpVersion: nil,
      headerFields: [:]
    )

    XCTAssertTrue(testPolicy.shouldRetry(response: testResponse, error: PubNubError(.unknown)))
  }

  func test_ErrorMatchesRetryableURLErrorCode_ReturnsTrue() {
    let testURLErrorCode = URLError.Code.timedOut
    let testError = URLError(testURLErrorCode)

    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: .linear(delay: 2.0),
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: [testURLErrorCode]
    )

    XCTAssertTrue(testPolicy.shouldRetry(response: nil, error: testError))
  }

  func test_ErrorNotInRetryableCodes_ReturnsFalse() {
    let testError = URLError(.timedOut)
    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: .linear(delay: 2.0),
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertFalse(testPolicy.shouldRetry(response: nil, error: testError))
  }

  // MARK: - exponentialBackoff(minDelay:maxDelay)

  func test_ReconnectionPolicy_ExponentialBackoff_ReturnsExpectedDelays() {
    let maxRetryCount = 5
    let maxDelay = UInt.max
    let delayForRetry = [2.0...3.0, 4.0...5.0, 8.0...9.0, 16.0...17.0, 32.0...33.0]

    for count in 0..<maxRetryCount {
      let policy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: UInt(2.0), maxDelay: maxDelay)
      let delay = policy.delay(for: count)

      XCTAssertTrue(delayForRetry[count].contains(delay))
    }
  }

  func test_ReconnectionPolicy_ExponentialBackoffExceedsMax_CapsAtMaxDelay() {
    let maxRetryCount = 5
    let maxDelay = 15
    let delayForRetry = [2.0...3.0, 4.0...5.0, 8.0...9.0, 15.0...16.0, 15.0...16.0]

    for count in 0..<maxRetryCount {
      let policy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: UInt(2.0), maxDelay: UInt(maxDelay))
      let delay = policy.delay(for: count)

      XCTAssertTrue(delayForRetry[count].contains(delay))
    }
  }

  func test_ReconnectionPolicy_ExponentialBackoffWithHighMinDelay_StartsAtMinDelay() {
    let maxRetryCount = 5
    let maxDelay = UInt.max
    let delayForRetry = [8.0...9.0, 16...17, 32.0...33.0, 64.0...65.0, 128.0...129.0]

    for count in 0..<maxRetryCount {
      let policy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: UInt(8.0), maxDelay: UInt(maxDelay))
      let delay = policy.delay(for: count)

      XCTAssertTrue(delayForRetry[count].contains(delay))
    }
  }
}
