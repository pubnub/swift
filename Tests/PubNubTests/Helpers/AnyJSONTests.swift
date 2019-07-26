//
//  AnyJSONTests.swift
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

@testable import PubNub
import XCTest

struct SomeJSON: Codable {
  var something: AnyJSON
}

class AnyJSONTests: XCTestCase {
  struct NonHashable {
    var value: String
  }

  // MARK: Hashable

  func testHashble_NonHashable() {
    let nonHashable = NonHashable(value: "value")

    let json = AnyJSON(nonHashable)

    XCTAssertNotEqual(json, AnyJSON(nonHashable))
    XCTAssertEqual(json.hashValue, AnyJSON(nonHashable).hashValue)
  }

  func testArrayEquatible_Mismatch() {
    let json = AnyJSON([1, 2, 3])
    let otherJson = AnyJSON([1, 2, "3"])

    XCTAssertNotEqual(json, otherJson)
  }

  func testArrayEquatible_MismatchSizes() {
    let json = AnyJSON([1, 2, 3])
    let otherJson = AnyJSON([1, 2])

    XCTAssertNotEqual(json, otherJson)
  }

  func testDictionaryEquatible_Mismatch() {
    let json = AnyJSON(["one": 1, "two": 2, "three": 3])
    let otherJson = AnyJSON(["one": 1, "two": 2, "three": "3"])

    XCTAssertNotEqual(json, otherJson)
  }

  func testDictionaryEquatible_MismatchSizes() {
    let json = AnyJSON(["one": 1, "two": 2, "three": 3])
    let otherJson = AnyJSON(["one": 1, "two": 2])

    XCTAssertNotEqual(json, otherJson)
  }

  // MARK: ExpressibleBy...

  func testHashableExpressible_Array() {
    let date = Date()
    let literal: [Any] = ["One", 2, true, date, Data(), 3.0]

    let json: AnyJSON = ["One", 2, true, date, Data(), 3.0]

    XCTAssertEqual(json, AnyJSON(literal))
    XCTAssertEqual(json.hashValue, AnyJSON(literal).hashValue)
    XCTAssertNotNil(json.arrayValue)
  }

  func testHashableExpressible_Dictionary() {
    let date = Date()
    let literal: [String: Any] = [
      "String": "One",
      "Int": 2,
      "Bool": true,
      "Date": date,
      "Data": Data(),
      "Float": 3.0
    ]

    let json: AnyJSON = [
      "String": "One",
      "Int": 2,
      "Bool": true,
      "Date": date,
      "Data": Data(),
      "Float": 3.0
    ]

    XCTAssertEqual(json, AnyJSON(literal))
    XCTAssertEqual(json.hashValue, AnyJSON(literal).hashValue)
    XCTAssertNotNil(json.dictionaryValue)
  }

  // MARK: - Convertible

  func testCustomStringConvertible() {
    let testString = "String Describing This Object"

    let test = NonHashable(value: testString)

    let json = AnyJSON(test)
    XCTAssertEqual(json.description, "NonHashable(value: \"\(testString)\")")

    let stringJSON = AnyJSON(testString)
    XCTAssertEqual(stringJSON.description, testString)
  }

  func testCustomDebugStringConvertible() {
    let testString = "String Describing This Object"
    let test = NonHashable(value: testString)

    let json = AnyJSON(test)
    XCTAssertEqual(json.debugDescription, "NonHashable(value: \"\(testString)\")")

    let stringJSON = AnyJSON(testString)
    XCTAssertEqual(stringJSON.debugDescription, "\"\(testString)\"")
  }
}
