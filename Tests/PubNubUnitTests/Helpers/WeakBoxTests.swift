//
//  WeakBoxTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

class WeakBoxTests: XCTestCase {
  var strongValue = DeinitTest(value: "TestValue")

  class DeinitTest: Hashable {
    static func == (lhs: WeakBoxTests.DeinitTest, rhs: WeakBoxTests.DeinitTest) -> Bool {
      return lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) {
      value.hash(into: &hasher)
    }

    var value: NSString
    var deinitClosure: (() -> Void)?

    init(value: NSString) {
      self.value = value
    }

    deinit {
      deinitClosure?()
    }
  }

  func test_WithStrongReference_ContainsValue() {
    let weakBox = WeakBox(strongValue)

    XCTAssertNotNil(weakBox.underlying)
    XCTAssertEqual(weakBox.underlying, strongValue)
  }

  func test_EqualValues_AreHashableAndEqual() {
    let weakOne = WeakBox<NSString>("Test")
    let weakTwo = WeakBox<NSString>("Test")

    XCTAssertEqual(weakOne.underlying, weakTwo.underlying)
    XCTAssertEqual(weakOne, weakTwo)
    XCTAssertEqual(weakOne.hashValue, weakTwo.hashValue)
  }
}

class WeakSetTests: XCTestCase {
  func test_AllObjects_ReturnsStoredObjects() {
    let testObjects: [NSString] = ["Hello"]
    let weakSet = WeakSet<NSString>(testObjects)

    XCTAssertEqual(weakSet.allObjects, testObjects)
  }

  func test_Count_MatchesObjectCount() {
    let testObjects: [NSString] = ["Hello"]
    let weakSet = WeakSet<NSString>(testObjects)

    XCTAssertEqual(weakSet.count, testObjects.count)
  }

  func test_UpdateWithNewObject_IncrementsCount() {
    let testObjects: [NSString] = ["Hello"]
    let newObject: NSString = "New"
    var weakSet = WeakSet<NSString>(testObjects)

    XCTAssertEqual(weakSet.count, testObjects.count)

    weakSet.update(newObject)
    XCTAssertEqual(weakSet.count, testObjects.count + 1)
    weakSet.update(newObject)
    XCTAssertEqual(weakSet.count, testObjects.count + 1)
  }

  func test_RemoveObject_BecomesEmpty() {
    let testObject: NSString = "Hello"
    let testObjects: [NSString] = [testObject]

    var weakSet = WeakSet<NSString>(testObjects)

    XCTAssertEqual(weakSet.count, testObjects.count)
    weakSet.remove(testObject)
    XCTAssertTrue(weakSet.isEmpty)
  }

  func test_RemoveAll_BecomesEmpty() {
    let testObject: NSString = "Hello"
    let testObjects: [NSString] = [testObject]

    var weakSet = WeakSet<NSString>(testObjects)
    XCTAssertEqual(weakSet.count, testObjects.count)
    weakSet.removeAll()
    XCTAssertTrue(weakSet.isEmpty)
  }

  func test_InsertEqualObject_DoesNotDuplicate() {
    let firstObject: NSString = "Hello"
    let secondObject: NSString = "Hello"

    var weakSet = WeakSet<NSString>([firstObject])
    XCTAssertEqual(weakSet.count, 1)
    weakSet.update(secondObject)
    XCTAssertEqual(weakSet.count, 1)
  }

  func test_RemoveEqualObject_RemovesFromSet() {
    let firstObject: NSString = "Hello"
    let secondObject: NSString = "Hello"

    var weakSet = WeakSet<NSString>([firstObject])
    XCTAssertEqual(weakSet.count, 1)
    weakSet.remove(secondObject)
    XCTAssertTrue(weakSet.isEmpty)
  }

  func test_InitWithDuplicates_DeduplicatesObjects() {
    let firstObject: NSString = "Hello"
    let secondObject: NSString = "Hello"
    let thirdObject: NSString = "World"

    let weakSet = WeakSet<NSString>([firstObject, secondObject, thirdObject])
    XCTAssertEqual(weakSet.count, 2)
    XCTAssertTrue(weakSet.contains { $0 == "Hello" })
    XCTAssertTrue(weakSet.contains { $0 == "World" })
  }
}
