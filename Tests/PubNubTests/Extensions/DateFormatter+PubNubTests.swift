//
//  DateFormatter+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class DateFormatterPubNubTests: XCTestCase {
  func testCurrentDateString() {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .long

    let currentDate = Date()
    guard let dateFormatterDate = formatter.date(from: formatter.currentDateString) else {
      XCTFail("Could not create valid date from Date object.")
      return
    }

    let offset = currentDate.timeIntervalSince(dateFormatterDate)

    // Ensure that the dates are close enough
    XCTAssertLessThanOrEqual(offset, 1.0, "Date interval was off by \(offset)")
    XCTAssertGreaterThanOrEqual(offset, -1.0, "Date interval was off by \(offset)")
  }
}
