//
//  HTTPHeadersTests.swift
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

class HTTPHeadersTests: XCTestCase {
  func testDictionaryInit() {
    let dict = ["Key": "Value"]
    let headers = PubNubHTTPHeaders(dict)

    XCTAssertEqual(headers.allHTTPHeaderFields, dict)
  }

  func testHTTPHeaderArrayInit() {
    let list = [HTTPHeader(name: "Key", value: "Value")]
    let headers = PubNubHTTPHeaders(list)

    XCTAssertEqual(headers.first?.name, list.first?.name)
    XCTAssertEqual(headers.first?.value, list.first?.value)
  }

  func testUpdate_NoCollision() {
    var headers = PubNubHTTPHeaders(["Key": "Value"])
    headers.update(HTTPHeader(name: "OtherKey", value: "Other"))

    XCTAssertEqual(headers.count, 2)
  }

  func testUpdate_Collision() {
    var headers = PubNubHTTPHeaders(["Key": "Value"])
    headers.update(HTTPHeader(name: "Key", value: "Other"))

    XCTAssertEqual(headers.count, 1)
    XCTAssertEqual(headers.first?.value, "Other")
  }

  func testUpdateNameValue_NoCollision() {
    var headers = PubNubHTTPHeaders(["Key": "Value"])
    headers.update(name: "OtherKey", value: "Other")

    XCTAssertEqual(headers.count, 2)
  }

  func testUpdateNameValue_Collision() {
    var headers = PubNubHTTPHeaders(["Key": "Value"])
    headers.update(name: "Key", value: "Other")

    XCTAssertEqual(headers.count, 1)
    XCTAssertEqual(headers.first?.value, "Other")
  }

  func testAllHTTPHeaderFields() {
    let list = [
      HTTPHeader(name: "Key", value: "Value"),
      HTTPHeader(name: "Key", value: "NextValue")
    ]
    let headers = PubNubHTTPHeaders(list)

    XCTAssertEqual(headers.allHTTPHeaderFields.count, 1)
    XCTAssertEqual(headers.allHTTPHeaderFields, ["Key": "NextValue"])
  }

  func testExpressibleByDictionary() {
    let headers: PubNubHTTPHeaders = ["Key": "Value", "Key": "NextValue"]

    XCTAssertEqual(headers.allHTTPHeaderFields, ["Key": "NextValue"])
  }

  func testExpressibleByArray() {
    let headers: PubNubHTTPHeaders = [
      HTTPHeader(name: "Key", value: "Value"),
      HTTPHeader(name: "Key", value: "NextValue")
    ]

    XCTAssertEqual(headers.allHTTPHeaderFields, ["Key": "NextValue"])
  }

  func testMakeIterator() {
    let headers: PubNubHTTPHeaders = [
      "Key": "Value",
      "OtherKey": "NextValue"
    ]

    var iterator = headers.makeIterator()

    XCTAssertNotNil(iterator.next())
    XCTAssertNotNil(iterator.next())
    XCTAssertNil(iterator.next())
  }
}

class HTTPHeaderTests: XCTestCase {
  func testCustomConvertable() {
    let header = HTTPHeader(name: "Key",
                            value: "Value")
    XCTAssertEqual(header.description, "Key: Value")
  }

  func testDefaultContentType() {
    let header = HTTPHeader(name: "Content-Type",
                            value: "application/json; charset=UTF-8")

    XCTAssertEqual(HTTPHeader.defaultContentType, header)
  }

  func testDefaultAcceptEncoding() {
    let value: String
    if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
      value = "br;q=1.0, gzip;q=0.9, deflate;q=0.8"
    } else {
      value = "gzip;q=1.0, deflate;q=0.9"
    }

    let header = HTTPHeader(name: "Accept-Encoding",
                            value: value)

    XCTAssertEqual(HTTPHeader.defaultAcceptEncoding, header)
  }

  func testDefaultUserAgent() {
    let header = HTTPHeader(name: "User-Agent",
                            value: Constant.defaultUserAgent)
    XCTAssertEqual(HTTPHeader.defaultUserAgent, header)
  }

  func testIndexOf() {
    let headers = [
      HTTPHeader(name: "Key", value: "Value"),
      HTTPHeader(name: "OtherKey", value: "OtherValue")
    ]

    XCTAssertEqual(headers.firstIndex(of: "Key"), 0)
    XCTAssertEqual(headers.firstIndex(of: "key"), 0)
  }

  func testIndexOf_Nil() {
    let headers = [
      HTTPHeader(name: "Key", value: "Value"),
      HTTPHeader(name: "OtherKey", value: "OtherValue")
    ]

    XCTAssertEqual(headers.firstIndex(of: "Missing"), nil)
  }
}
