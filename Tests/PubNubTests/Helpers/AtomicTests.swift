//
//  AtomicTests.swift
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

class AtomicTests: XCTestCase {
  // MARK: - General Functionality

  func testLockedPerform() {
    let lockedPerform = XCTestExpectation(description: "testLockedPerform")

    let closure = {
      lockedPerform.fulfill()
    }
    let atomic = Atomic(1)

    atomic.lockedPerform { closure() }

    wait(for: [lockedPerform], timeout: 1.0)
  }

  func testLockedRead() {
    let value = 0
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.lockedRead { $0 == value })
  }

  func testLockedWrite() {
    let value = 0
    let newValue = 1
    let atomic = Atomic(value)

    XCTAssertEqual(atomic.lockedRead { $0 }, value)

    let writtenValue = atomic.lockedWrite { value -> Int in
      value = newValue
      return value
    }

    XCTAssertEqual(writtenValue, newValue)
  }

  func testLockedTry_Throws() {
    let invalidJson = 0
    let atomic = Atomic(invalidJson)

    XCTAssertThrowsError(try atomic.lockedTry { _ in throw PubNubError(reason: .requestMutatorFailure) })
  }

  func testLockedTry_NoThrows() {
    let validJson = [0]
    let value = AnyJSON(validJson)
    let atomic = Atomic(value)

    XCTAssertNoThrow(try atomic.lockedTry { try $0.jsonDataResult.get() })
  }

  func testIsEmpty() {
    let value = [Int]()
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.isEmpty)
    XCTAssertEqual(atomic.lockedRead { $0 }, value)
  }

  func testAppendElement() {
    let value = [Int]()
    let newValue = 0
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.isEmpty)

    atomic.append(newValue)

    XCTAssertFalse(atomic.isEmpty)
    XCTAssertEqual(atomic.lockedRead { $0.first }, newValue)
  }

  func testAppendSequence() {
    let value = [Int]()
    let newValue = 0
    let sequence = [newValue].makeIterator()
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.isEmpty)

    atomic.append(contentsOf: sequence)

    XCTAssertFalse(atomic.isEmpty)
    XCTAssertEqual(atomic.lockedRead { $0.first }, newValue)
  }

  func testAppendCollection() {
    let value = [Int]()
    let newValue = 0
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.isEmpty)

    atomic.append(contentsOf: [newValue])

    XCTAssertFalse(atomic.isEmpty)
    XCTAssertEqual(atomic.lockedRead { $0.first }, newValue)
  }

  // MARK: - AtomicInt

  func testFetchOrSetsBits() {
    let atomic = AtomicInt(0)
    XCTAssertEqual(atomic.bitwiseOrAssignemnt(0), 0)
    XCTAssertEqual(atomic.bitwiseOrAssignemnt(4), 0)
    XCTAssertEqual(atomic.bitwiseOrAssignemnt(8), 4)
    XCTAssertTrue(atomic.isEqual(to: 12))
  }

  func testAdd() {
    let atomic = AtomicInt(0)
    XCTAssertEqual(atomic.add(4), 0)
    XCTAssertEqual(atomic.add(3), 4)
    XCTAssertEqual(atomic.add(10), 7)
    XCTAssertEqual(atomic.increment(), 17)
    XCTAssertTrue(atomic.isEqual(to: 18))
  }

  func testSub() {
    let atomic = AtomicInt(0)
    XCTAssertEqual(atomic.sub(4), 0)
    XCTAssertEqual(atomic.sub(3), -4)
    XCTAssertEqual(atomic.sub(10), -7)
    XCTAssertEqual(atomic.decrement(), -17)
    XCTAssertTrue(atomic.isEqual(to: -18))
  }

  func testConcurreny_FetchOr() {
    let queue = DispatchQueue(label: "ConcurrenyQueue Fetch", qos: .userInteractive, attributes: .concurrent)
    let repeatCount = 25
    let concurrencyCount = 8
    let fetchCount: Int32 = 1

    for _ in 0 ..< repeatCount {
      let atomic = AtomicInt(0)
      let counter = AtomicInt(0)

      var expectations = [XCTestExpectation]()

      for _ in 0 ..< concurrencyCount {
        let expectation = self.expectation(description: "wait until loop completes")
        queue.async {
          while atomic.get() == 0 {}

          if atomic.bitwiseOrAssignemnt(-1) == fetchCount {
            counter.increment()
          }

          expectation.fulfill()
        }
        expectations.append(expectation)
      }
      atomic.bitwiseOrAssignemnt(fetchCount)

      wait(for: expectations, timeout: 1.0)

      XCTAssertEqual(counter.get(), fetchCount)
    }
  }

  func testConcurreny_Add() {
    let queue = DispatchQueue(label: "ConcurrenyQueue Add", qos: .userInteractive, attributes: .concurrent)
    let repeatCount = 25
    let concurrencyCount: Int32 = 8

    for _ in 0 ..< repeatCount {
      let atomic = AtomicInt(0)
      let counter = AtomicInt(0)

      var expectations = [XCTestExpectation]()

      for _ in 0 ..< concurrencyCount {
        let expectation = self.expectation(description: "wait until loop completes")
        queue.async {
          while atomic.get() == 0 {}

          counter.increment()

          expectation.fulfill()
        }
        expectations.append(expectation)
      }
      atomic.bitwiseOrAssignemnt(1)

      wait(for: expectations, timeout: 1.0)

      XCTAssertEqual(counter.get(), concurrencyCount)
    }
  }
}
