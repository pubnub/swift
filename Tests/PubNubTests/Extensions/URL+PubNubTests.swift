//
//  URL+PubNubTests.swift
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

final class URLPubNubTests: XCTestCase {
  func testAppendingQueryItems() {
    let testString = "https://example.com?one=two&key=value"
    guard let url = URL(string: "https://example.com?one=two") else {
      return XCTFail("Failed to unwrap url string")
    }
    let queryItem = URLQueryItem(name: "key", value: "value")

    let newURL = url.appending(queryItems: [queryItem])

    XCTAssertEqual(newURL?.absoluteString, testString)
  }

  func testAppendingQueryItems_NonePrevious() {
    let testString = "https://example.com?key=value"
    guard let url = URL(string: "https://example.com") else {
      return XCTFail("Failed to unwrap url string")
    }
    let queryItem = URLQueryItem(name: "key", value: "value")

    let newURL = url.appending(queryItems: [queryItem])

    XCTAssertEqual(newURL?.absoluteString, testString)
  }
}
