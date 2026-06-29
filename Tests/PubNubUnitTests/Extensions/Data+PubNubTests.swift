//
//  Data+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import XCTest
@testable import PubNubSDK

final class DataPubNubTests: XCTestCase {
  func test_HexEncodedString_WithValidUTF8Data_RoundTripsCorrectly() throws {
    let testString = "Test String To Data Encode"
    let testStringData = try XCTUnwrap(testString.data(using: .utf8))
    let hexString = testStringData.hexEncodedString
    let encodedData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let encodedString = try XCTUnwrap(String(bytes: encodedData, encoding: .utf8))

    XCTAssertEqual(encodedString, testString)
  }

  func test_InitHexEncodedString_WithOddCharacterCount_ReturnsNil() {
    let testString = "AAA"

    XCTAssertTrue(testString.count % 2 == 1)
    XCTAssertNil(Data(hexEncodedString: testString))
  }

  func test_InitHexEncodedString_WithNonHexCharacters_ReturnsNil() {
    let testString = "This Is A Non Hex String"

    XCTAssertTrue(testString.count % 2 == 0)
    XCTAssertNil(Data(hexEncodedString: testString))
  }
}
