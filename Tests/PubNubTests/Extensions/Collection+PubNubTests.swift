//
//  Collection+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class CollectionPubNubTests: XCTestCase {
  func testPubNubUUID() {
    let csvInput = ["one", "two", "three", "four"]
    let csvOutput = "one,two,three,four"

    XCTAssertEqual(csvInput.csvString, csvOutput)
  }

  func testHeaderQualityEncoded() {
    let headerInput = ["one", "two", "three", "four"]
    let headerOutput = "one;q=1.0, two;q=0.9, three;q=0.8, four;q=0.7"

    XCTAssertEqual(headerInput.headerQualityEncoded, headerOutput)
  }

  func testHeaderQualityEncoded_Overflow() {
    let headerInput = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

    XCTAssertEqual(headerInput.headerQualityEncoded, headerInput.joined(separator: ", "))
  }
}
