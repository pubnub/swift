//
//  Bool+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class BoolPubNubTests: XCTestCase {
  func test_StringNumber_WhenTrue_Returns1() {
    XCTAssertEqual(true.stringNumber, "1")
  }

  func test_StringNumber_WhenFalse_Returns0() {
    XCTAssertEqual(false.stringNumber, "0")
  }
}
