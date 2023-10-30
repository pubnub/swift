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

@testable import PubNub
import XCTest

final class DataPubNubTests: XCTestCase {
  func testHexEncodedString() {
    let testString = "Test String To Data Encode"

    guard let testStringData = testString.data(using: .utf8) else {
      return XCTFail("Could not create data from test string")
    }

    let hexString = testStringData.hexEncodedString

    guard let encodedData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not create data from hex string")
    }

    guard let encodedString = String(bytes: encodedData, encoding: .utf8) else {
      return XCTFail("Could not turn encoded data into encoded string")
    }

    XCTAssertEqual(encodedString, testString)
  }

  func testInitHexEncodedString_Fail_UnevenStringCount() {
    let testString = "AAA"

    XCTAssertTrue(testString.count % 2 == 1)
    XCTAssertNil(Data(hexEncodedString: testString))
  }

  func testInitHexEncodedString_Fail_NonHexString() {
    let testString = "This Is A Non Hex String"

    XCTAssertTrue(testString.count % 2 == 0)
    XCTAssertNil(Data(hexEncodedString: testString))
  }
}
