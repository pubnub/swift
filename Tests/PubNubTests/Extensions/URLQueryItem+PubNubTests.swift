//
//  URLQueryItem+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
//

@testable import PubNub
import XCTest

final class URLQueryItemPubNubTests: XCTestCase {
  func testIndexOf() {
    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "Second", value: "value"),
      URLQueryItem(name: "third", value: "value")
    ]

    XCTAssertEqual(queryItems.firstIndex(of: "first"), 0)
  }

  func testIndexOf_CaseSensitivity() {
    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "Second", value: "value"),
      URLQueryItem(name: "third", value: "value")
    ]

    XCTAssertEqual(queryItems.firstIndex(of: "second"), nil)
  }

  func testIndexOf_NotFound() {
    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "Second", value: "value"),
      URLQueryItem(name: "third", value: "value")
    ]

    XCTAssertEqual(queryItems.firstIndex(of: "second"), nil)
  }

  func testMerge() {
    var queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "second", value: "value"),
      URLQueryItem(name: "third", value: "value")
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
      URLQueryItem(name: "third", value: "value")
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

  func testAppendIfPresent() {
    var query = [URLQueryItem]()
    let queryItem = URLQueryItem(name: "TestKey", value: "TestValue")
    query.appendIfPresent(name: queryItem.name, value: queryItem.value)
    XCTAssertEqual(query.first, queryItem)
  }

  func testAppendIfPresent_Nil() {
    var query = [URLQueryItem]()
    query.appendIfPresent(name: "TestKey", value: nil)
    XCTAssertTrue(query.isEmpty)
  }

  func testAppendIfNotEmpty() {
    var query = [URLQueryItem]()
    let queryItems = ["TestValue", "OtherValue"]
    query.appendIfNotEmpty(name: "TestKey", value: queryItems)
    XCTAssertEqual(query.first?.value, queryItems.csvString)
  }

  func testAppendIfNotEmpty_Empty() {
    var query = [URLQueryItem]()
    query.appendIfNotEmpty(name: "TestKey", value: [])
    XCTAssertTrue(query.isEmpty)
  }
}
