//
//  Collection+PubNubTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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
