//
//  URLQueryItem+PubNub.swift
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

final class URLQueryItemPubNubTests: XCTestCase {
  func testIndexOf() {
    
    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "Second", value: "value"),
      URLQueryItem(name: "third", value: "value"),
    ]

    XCTAssertEqual(queryItems.firstIndex(of: "first"), 0)
  }
  func testIndexOf_CaseSensitivity() {

    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "Second", value: "value"),
      URLQueryItem(name: "third", value: "value"),
    ]

    XCTAssertEqual(queryItems.firstIndex(of: "second"), nil)
  }
  func testIndexOf_NotFound() {

    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "Second", value: "value"),
      URLQueryItem(name: "third", value: "value"),
    ]

    XCTAssertEqual(queryItems.firstIndex(of: "second"), nil)
  }
  func testMerge() {
    var queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "second", value: "value"),
      URLQueryItem(name: "third", value: "value"),
    ]
    let otherItems = [
      URLQueryItem(name: "fourth", value: "value"),
      URLQueryItem(name: "second", value: "NewValue")
    ]

    queryItems.merge(otherItems)

    XCTAssertEqual(queryItems[1].name, "second")
    XCTAssertEqual(queryItems[1].value, "NewValue")
    XCTAssertNotNil(queryItems.firstIndex(of: "fourth"))
  }
  func testMerging() {
    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "second", value: "value"),
      URLQueryItem(name: "third", value: "value"),
    ]
    let otherItems = [
      URLQueryItem(name: "fourth", value: "value"),
      URLQueryItem(name: "second", value: "NewValue")
    ]

    let newList = queryItems.merging(otherItems)

    XCTAssertEqual(newList[1].name, "second")
    XCTAssertEqual(newList[1].value, "NewValue")
    XCTAssertNotNil(newList.firstIndex(of: "fourth"))
  }
}

