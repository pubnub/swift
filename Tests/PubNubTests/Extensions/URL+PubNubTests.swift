//
//  URL+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
