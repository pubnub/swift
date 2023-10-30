//
//  WeakBoxTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

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

  func testWeakBox_ReleaseWeakRef() {
    let expectation = self.expectation(description: "testWeakBoxRetain")

    var testObject: DeinitTest? = DeinitTest(value: "Hello")
    testObject?.deinitClosure = {
      expectation.fulfill()
    }

    let weakBox = WeakBox(testObject)

    testObject = nil

    XCTAssertNil(weakBox.underlying)

    wait(for: [expectation], timeout: 1.0)
  }

  func testWeakBox_ContainsStrongRef() {
    let weakBox = WeakBox(strongValue)

    XCTAssertNotNil(weakBox.underlying)
    XCTAssertEqual(weakBox.underlying, strongValue)
  }

  func testWeakBox_Hashable() {
    let weakOne = WeakBox<NSString>("Test")
    let weakTwo = WeakBox<NSString>("Test")

    XCTAssertEqual(weakOne.underlying, weakTwo.underlying)
    XCTAssertEqual(weakOne, weakTwo)
    XCTAssertEqual(weakOne.hashValue, weakTwo.hashValue)
  }
}

class WeakSetTests: XCTestCase {
  func testAllObject() {
    let testObjects: [NSString] = ["Hello"]

    let weakSet = WeakSet<NSString>(testObjects)

    XCTAssertEqual(weakSet.allObjects, testObjects)
  }

  func testCount() {
    let testObjects: [NSString] = ["Hello"]

    let weakSet = WeakSet<NSString>(testObjects)

    XCTAssertEqual(weakSet.count, testObjects.count)
  }

  func testUpdate() {
    let testObjects: [NSString] = ["Hello"]
    let newObject: NSString = "New"
    var weakSet = WeakSet<NSString>(testObjects)

    XCTAssertEqual(weakSet.count, testObjects.count)

    weakSet.update(newObject)

    XCTAssertEqual(weakSet.count, testObjects.count + 1)

    weakSet.update(newObject)

    XCTAssertEqual(weakSet.count, testObjects.count + 1)
  }

  func testRemove() {
    let testObject: NSString = "Hello"
    let testObjects: [NSString] = [testObject]

    var weakSet = WeakSet<NSString>(testObjects)

    XCTAssertEqual(weakSet.count, testObjects.count)

    weakSet.remove(testObject)

    XCTAssertTrue(weakSet.isEmpty)
  }

  func testRemoveAll() {
    let testObject: NSString = "Hello"
    let testObjects: [NSString] = [testObject]

    var weakSet = WeakSet<NSString>(testObjects)

    XCTAssertEqual(weakSet.count, testObjects.count)

    weakSet.removeAll()

    XCTAssertTrue(weakSet.isEmpty)
  }
}
