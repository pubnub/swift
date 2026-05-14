//
//  AtomicTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

class AtomicTests: XCTestCase {

  // MARK: - General Functionality

  func test_Atomic_LockedPerform_ExecutesClosure() {
    let lockedPerform = XCTestExpectation(description: "testLockedPerform")
    let closure = { lockedPerform.fulfill() }
    let atomic = Atomic(1)

    atomic.lockedPerform { closure() }

    wait(for: [lockedPerform], timeout: 1.0)
  }

  func test_Atomic_LockedRead_ReturnsTrue() {
    let value = 0
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.lockedRead { $0 == value })
  }

  func test_Atomic_LockedWrite_UpdatesValue() {
    let value = 0
    let newValue = 1
    let atomic = Atomic(value)

    XCTAssertEqual(atomic.lockedRead { $0 }, value)

    let writtenValue = atomic.lockedWrite { value -> Int in
      value = newValue
      return value
    }

    XCTAssertEqual(writtenValue, newValue)
    XCTAssertEqual(atomic.lockedRead { $0 }, newValue)
  }

  func test_Atomic_LockedTryWithError_ThrowsError() {
    let invalidJson = 0
    let atomic = Atomic(invalidJson)

    XCTAssertThrowsError(try atomic.lockedTry { _ in throw PubNubError(.requestMutatorFailure) }) { error in
      XCTAssertEqual(error as? PubNubError, PubNubError(.requestMutatorFailure))
    }
  }

  func test_Atomic_LockedTryWithValidData_DoesNotThrow() {
    let validJson = [0]
    let value = AnyJSON(validJson)
    let atomic = Atomic(value)

    XCTAssertNoThrow(try atomic.lockedTry { try $0.jsonDataResult.get() })
  }

  func test_Atomic_IsEmptyWithEmptyArray_ReturnsTrue() {
    let value = [Int]()
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.isEmpty)
    XCTAssertEqual(atomic.lockedRead { $0 }, value)
  }

  func test_Atomic_AppendElement_AddsToArray() {
    let value = [Int]()
    let newValue = 0
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.isEmpty)

    atomic.append(newValue)

    XCTAssertFalse(atomic.isEmpty)
    XCTAssertEqual(atomic.lockedRead { $0.first }, newValue)
  }

  func test_Atomic_AppendSequence_AddsToArray() {
    let value = [Int]()
    let newValue = 0
    let sequence = [newValue].makeIterator()
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.isEmpty)

    atomic.append(contentsOf: sequence)

    XCTAssertFalse(atomic.isEmpty)
    XCTAssertEqual(atomic.lockedRead { $0.first }, newValue)
  }

  func test_Atomic_AppendCollection_AddsToArray() {
    let value = [Int]()
    let newValue = 0
    let atomic = Atomic(value)

    XCTAssertTrue(atomic.isEmpty)

    atomic.append(contentsOf: [newValue])

    XCTAssertFalse(atomic.isEmpty)
    XCTAssertEqual(atomic.lockedRead { $0.first }, newValue)
  }

  // MARK: - AtomicInt

  func test_AtomicInt_BitwiseOrAssignment_SetsBitsCorrectly() {
    let atomic = AtomicInt(0)

    XCTAssertEqual(atomic.bitwiseOrAssignemnt(0), 0)
    XCTAssertEqual(atomic.bitwiseOrAssignemnt(4), 0)
    XCTAssertEqual(atomic.bitwiseOrAssignemnt(8), 4)
    XCTAssertTrue(atomic.isEqual(to: 12))
  }

  func test_AtomicInt_Add_ReturnsOldValueAndIncrements() {
    let atomic = AtomicInt(0)

    XCTAssertEqual(atomic.add(4), 0)
    XCTAssertEqual(atomic.add(3), 4)
    XCTAssertEqual(atomic.add(10), 7)
    XCTAssertEqual(atomic.increment(), 17)
    XCTAssertTrue(atomic.isEqual(to: 18))
  }

  func test_AtomicInt_Sub_ReturnsOldValueAndDecrements() {
    let atomic = AtomicInt(0)

    XCTAssertEqual(atomic.sub(4), 0)
    XCTAssertEqual(atomic.sub(3), -4)
    XCTAssertEqual(atomic.sub(10), -7)
    XCTAssertEqual(atomic.decrement(), -17)
    XCTAssertTrue(atomic.isEqual(to: -18))
  }

  func test_AtomicInt_ConcurrentBitwiseOr_OnlyOneThreadSeesExpectedValue() {
    let concurrencyCount = 8
    let fetchCount: Int32 = 1

    for _ in 0..<25 {
      let atomic = AtomicInt(fetchCount)
      let counter = AtomicInt(0)

      performConcurrently(count: concurrencyCount) {
        if atomic.bitwiseOrAssignemnt(-1) == fetchCount {
          counter.increment()
        }
      }

      XCTAssertEqual(counter.get(), fetchCount)
    }
  }

  func test_AtomicInt_ConcurrentIncrement_AllThreadsComplete() {
    let concurrencyCount: Int32 = 8

    for _ in 0..<25 {
      let counter = AtomicInt(0)

      performConcurrently(count: Int(concurrencyCount)) {
        counter.increment()
      }

      XCTAssertEqual(counter.get(), concurrencyCount)
    }
  }
}

private extension AtomicTests {

  /// Executes `action` on `count` threads simultaneously and waits for all to finish.
  func performConcurrently(count: Int, timeout: TimeInterval = 1.0, action: @escaping () -> Void) {
    let queue = DispatchQueue(label: "ConcurrencyQueue", attributes: .concurrent)
    let startGate = DispatchSemaphore(value: 0)
    let readyGate = DispatchSemaphore(value: 0)
    let expectations = (0..<count).map { _ in expectation(description: "concurrent work") }

    for i in 0..<count {
      queue.async {
        readyGate.signal()
        startGate.wait()
        action()
        expectations[i].fulfill()
      }
    }

    for _ in 0..<count {
      readyGate.wait()
    }

    for _ in 0..<count {
      startGate.signal()
    }

    wait(for: expectations, timeout: timeout)
  }
}
