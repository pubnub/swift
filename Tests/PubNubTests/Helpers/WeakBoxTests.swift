//
//  WeakBoxTests.swift
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

    XCTAssertNil(weakBox.unbox)

    wait(for: [expectation], timeout: 1.0)
  }

  func testWeakBox_ContainsStrongRef() {
    let weakBox = WeakBox(strongValue)

    XCTAssertNotNil(weakBox.unbox)
    XCTAssertEqual(weakBox.unbox, strongValue)
  }

  func testWeakBox_Hashable() {
    let weakOne = WeakBox<NSString>("Test")
    let weakTwo = WeakBox<NSString>("Test")

    XCTAssertEqual(weakOne.unbox, weakTwo.unbox)
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
