//
//  XCTestCase+Integration.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest

extension XCTestCase {
  func waitForCompletion<T: Any>(
    timeout: TimeInterval = 10.0,
    file: StaticString = #file,
    line: UInt = #line,
    operation: (@escaping (Result<T, Error>) -> Void) -> Void
  ) {
    let expect = XCTestExpectation(description: "Wait for completion (\(file) \(line)")
    expect.assertForOverFulfill = true
    expect.expectedFulfillmentCount = 1

    operation { result in
      if case .failure(let failure) = result {
        XCTFail("Operation failed with error: \(failure)", file: file, line: line)
      }

      expect.fulfill()
    }

    wait(
      for: [expect],
      timeout: timeout
    )
  }
}
