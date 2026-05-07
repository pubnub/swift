//
//  URL+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class URLPubNubTests: XCTestCase {
  func test_AppendingQueryItems_WithExistingQuery_AppendsNewItem() throws {
    let testString = "https://example.com?one=two&key=value"
    let url = try XCTUnwrap(URL(string: "https://example.com?one=two"))
    let queryItem = URLQueryItem(name: "key", value: "value")

    let newURL = url.appendingQueryItems([queryItem])

    XCTAssertEqual(newURL?.absoluteString, testString)
  }

  func test_AppendingQueryItems_WithNoExistingQuery_CreatesQueryString() throws {
    let testString = "https://example.com?key=value"
    let url = try XCTUnwrap(URL(string: "https://example.com"))
    let queryItem = URLQueryItem(name: "key", value: "value")

    let newURL = url.appendingQueryItems([queryItem])

    XCTAssertEqual(newURL?.absoluteString, testString)
  }
}
