//
//  DateFormatter+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DateFormatterPubNubTests: XCTestCase {
  func test_CurrentDateString_WhenFormatted_MatchesCurrentDateWithinOneSecond() throws {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .long

    let currentDate = Date()
    let dateFormatterDate = try XCTUnwrap(formatter.date(from: formatter.currentDateString))
    let offset = currentDate.timeIntervalSince(dateFormatterDate)

    // Ensure that the dates are close enough
    XCTAssertLessThanOrEqual(offset, 1.0, "Date interval was off by \(offset)")
    XCTAssertGreaterThanOrEqual(offset, -1.0, "Date interval was off by \(offset)")
  }
}
