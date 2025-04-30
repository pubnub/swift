//
//  AutomaticRetryTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
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
    let policy = AutomaticRetry()

    XCTAssertEqual(testPolicy, policy)
  }

  func testEquatable_Init_Linear_InvalidDelay() {
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

  func testEquatable_Init_Linear_Valid() {
    let validLinearPolicy = AutomaticRetry.ReconnectionPolicy.linear(delay: 2.0)
    let testPolicy = AutomaticRetry(
      retryLimit: 2,
      policy: validLinearPolicy,
      retryableHTTPStatusCodes: [],
      retryableURLErrorCodes: []
    )

    XCTAssertEqual(testPolicy.policy, validLinearPolicy)
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
  
  func testShouldRetry_True_TooManyRequestsStatusCode() {
    guard let url = URL(string: "http://example.com") else {
      return XCTFail("Could not create URL")
    }
    
    let testStatusCode = 429
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

  func testShouldRetry_True_ErrorCodeMatch() {
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

  func testShouldRetry_False() {
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
  
  func testExponentialBackoffDelay() {
    let maxRetryCount = 5
    let maxDelay = UInt.max
    let delayForRetry = [2.0...3.0, 4.0...5.0, 8.0...9.0, 16.0...17.0, 32.0...33.0]
    
    for count in 0..<maxRetryCount {
      let policy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: UInt(2.0), maxDelay: maxDelay)
      let delay = policy.delay(for: count)
      XCTAssertTrue(delayForRetry[count].contains(delay))
    }
  }
  
  func testExponentialBackoffDelay_MaxDelayHit() {
    let maxRetryCount = 5
    let maxDelay = 15
    let delayForRetry = [2.0...3.0, 4.0...5.0, 8.0...9.0, 15.0...16.0, 15.0...16.0]
    
    for count in 0..<maxRetryCount {
      let policy = AutomaticRetry.ReconnectionPolicy.exponential(minDelay: UInt(2.0), maxDelay: UInt(maxDelay))
      let delay = policy.delay(for: count)
      XCTAssertTrue(delayForRetry[count].contains(delay))
    }
  }
  
  func testExponentialBackoffDelay_MinDelayHit() {
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
