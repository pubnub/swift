//
//  Bool+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class BoolPubNubTests: XCTestCase {
  func testStringNumber_True() {
    XCTAssertEqual(true.stringNumber, "1")
  }

  func testStringNumber_False() {
    XCTAssertEqual(false.stringNumber, "0")
  }
}
