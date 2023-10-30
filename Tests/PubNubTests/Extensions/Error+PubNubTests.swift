//
//  Error+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class ErrorPubNubTests: XCTestCase {
  func testPubNubErrorCast() {
    let error: Error = PubNubError(.unknown)

    XCTAssertNotNil(error.pubNubError)
    XCTAssertNil(error.urlError)
  }

  func testURLErrorCast() {
    let error: Error = URLError(.unknown)

    XCTAssertNotNil(error.urlError)
    XCTAssertNil(error.pubNubError)
  }
}
