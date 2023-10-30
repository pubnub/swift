//
//  ValidatedTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class ValidatedTests: XCTestCase {
  struct TestValidated: Validated {
    var mockError: Error?

    var validationError: Error? {
      return mockError
    }
  }

  func testIsValid() {
    let validTest = TestValidated()
    XCTAssertNil(validTest.validationError)
    XCTAssertTrue(validTest.isValid)

    let error = PubNubError(.invalidEndpointType)
    let invalidTest = TestValidated(mockError: error)
    XCTAssertNotNil(invalidTest.validationError)
    XCTAssertFalse(invalidTest.isValid)
  }

  func testValidResult() {
    let validTest = TestValidated()
    XCTAssertNil(validTest.validationError)
    XCTAssertNoThrow(try validTest.validResult.get())

    let testError = PubNubError(.invalidEndpointType)
    let invalidTest = TestValidated(mockError: testError)
    XCTAssertNotNil(invalidTest.validationError)
    XCTAssertThrowsError(try invalidTest.validResult.get(), "An error should be thrown") { error in
      XCTAssertEqual(error.pubNubError, testError)
    }
  }
}
