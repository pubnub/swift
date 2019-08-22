//
//  Data+PubNubTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
