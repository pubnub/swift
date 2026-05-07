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

@testable import PubNubSDK
import XCTest

final class URLQueryItemPubNubTests: XCTestCase {
  func test_FirstIndex_WithExistingName_ReturnsCorrectIndex() {
    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "Second", value: "value"),
      URLQueryItem(name: "third", value: "value")
    ]

    XCTAssertEqual(queryItems.firstIndex(of: "first"), 0)
  }

  func test_FirstIndex_WithDifferentCase_ReturnsNil() {
    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "Second", value: "value"),
      URLQueryItem(name: "third", value: "value")
    ]

    XCTAssertEqual(queryItems.firstIndex(of: "second"), nil)
  }

  func test_FirstIndex_WithNonExistentName_ReturnsNil() {
    let queryItems = [
      URLQueryItem(name: "first", value: "value"),
      URLQueryItem(name: "Second", value: "value"),
      URLQueryItem(name: "third", value: "value")
    ]

    XCTAssertEqual(queryItems.firstIndex(of: "nonexistent"), nil)
  }

  func test_Merge_WithOverlappingItems_UpdatesExistingAndAddsNew() {
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

  func test_Merging_WithOverlappingItems_ReturnsNewMergedArray() {
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

  func test_AppendIfPresent_WithNonNilValue_AppendsItem() {
    var query = [URLQueryItem]()
    let queryItem = URLQueryItem(name: "TestKey", value: "TestValue")

    query.appendIfPresent(name: queryItem.name, value: queryItem.value)

    XCTAssertEqual(query.first, queryItem)
  }

  func test_AppendIfPresent_WithNilValue_DoesNotAppend() {
    var query = [URLQueryItem]()
    query.appendIfPresent(name: "TestKey", value: nil)

    XCTAssertTrue(query.isEmpty)
  }

  func test_AppendIfNotEmpty_WithPopulatedArray_AppendsCSVItem() {
    var query = [URLQueryItem]()
    let queryItems = ["TestValue", "OtherValue"]

    query.appendIfNotEmpty(name: "TestKey", value: queryItems)

    XCTAssertEqual(query.first?.value, queryItems.csvString)
  }

  func test_AppendIfNotEmpty_WithEmptyArray_DoesNotAppend() {
    var query = [URLQueryItem]()
    query.appendIfNotEmpty(name: "TestKey", value: [])

    XCTAssertTrue(query.isEmpty)
  }
}
