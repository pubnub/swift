//
//  Int+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class TimetokenTests: XCTestCase {
  func testTimetokenDate() {
    let timetoken = Timetoken(15_614_817_397_828_462)

    let date = Date(timeIntervalSince1970: TimeInterval(timetoken / 10_000_000))

    XCTAssertEqual(timetoken.timetokenDate, date)
  }
}
