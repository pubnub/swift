//
//  Atomic.swift
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

import Foundation

@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
final class UnfairLock: NSLocking {
  private var unfairLock: UnsafeMutablePointer<os_unfair_lock>

  init() {
    unfairLock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
    unfairLock.initialize(to: os_unfair_lock())
  }

  deinit {
    unfairLock.deinitialize(count: 1)
    unfairLock.deallocate()
  }

  @inline(__always)
  func lock() {
    os_unfair_lock_lock(unfairLock)
  }

  @inline(__always)
  func unlock() {
    os_unfair_lock_unlock(unfairLock)
  }
}

final class Atomic<Locked> {
  private let lock: NSLocking
  private var value: Locked

  init(_ value: Locked, locker: NSLocking? = nil) {
    if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
      self.lock = locker ?? UnfairLock()
    } else {
      lock = locker ?? NSLock()
    }

    self.value = value
  }

  /// Thread-safe access of locked value
  @inline(__always)
  func lockedRead<Value>(_ closure: (Locked) -> Value) -> Value {
    return lock.synchronize { closure(self.value) }
  }

  /// Thread-safe mutation of locked value
  @discardableResult
  @inline(__always)
  func lockedWrite<Value>(_ closure: (inout Locked) -> Value) -> Value {
    return lock.synchronize { closure(&self.value) }
  }

  /// Thread-safe execution of a closure
  @inline(__always)
  func lockedPerform(_ closure: () -> Void) {
    return lock.synchronize { closure() }
  }

  /// Thread-safe execution of a closure that can throw exceptions
  @inline(__always)
  func lockedTry<Value>(_ closure: (inout Locked) throws -> Value) throws -> Value {
    return try lock.synchronize { try closure(&self.value) }
  }
}

extension Atomic where Locked: Collection {
  @inline(__always)
  var isEmpty: Bool {
    return lock.synchronize { value.isEmpty }
  }
}

extension Atomic where Locked: RangeReplaceableCollection {
  @inline(__always)
  func append(_ element: Locked.Element) {
    lockedWrite { (collection: inout Locked) in
      collection.append(element)
    }
  }

  @inline(__always)
  func append<S: Sequence>(contentsOf elements: S) where S.Element == Locked.Element {
    lockedWrite { (sequence: inout Locked) in
      sequence.append(contentsOf: elements)
    }
  }

  @inline(__always)
  func append<C: Collection>(contentsOf elements: C) where C.Element == Locked.Element {
    lockedWrite { (collection: inout Locked) in
      collection.append(contentsOf: elements)
    }
  }
}

extension AtomicInt {
  /// Adds a value to the existing locked value
  /// - parameters:
  ///   - addValue: The value added to the locked value
  /// - returns: The previous value before the addition
  @discardableResult
  @inline(__always)
  func add(_ addValue: Int32) -> Int32 {
    return lockedWrite { value in
      let oldValue = value
      value += addValue
      return oldValue
    }
  }

  /// Increments the locked value by `1`
  /// - returns: The previous value before the addition
  @discardableResult
  @inline(__always)
  func increment() -> Int32 {
    return add(1)
  }

  /// Subtracts a value from the existing locked value
  /// - parameters:
  ///   - subValue: The value subtracted from the locked value
  /// - returns: The previous value before the subtraction
  @discardableResult
  @inline(__always)
  func sub(_ subValue: Int32) -> Int32 {
    return lockedWrite { value in
      let oldValue = value
      value -= subValue
      return oldValue
    }
  }

  /// Decrements the locked value by `1`
  /// - returns: The previous value before the subtraction
  @discardableResult
  @inline(__always)
  func decrement() -> Int32 {
    return sub(1)
  }

  /// Performs a bitwise OR with and assigns the resulting value
  /// - parameters:
  ///   - orValue: The value to use when perfroming the operation
  /// - returns: The previous value before the assignment
  @discardableResult
  @inline(__always)
  func bitwiseOrAssignemnt(_ orValue: Int32) -> Int32 {
    return lockedWrite { value in
      let oldValue = value
      value |= orValue
      return oldValue
    }
  }

  /// The currently stored value
  @inline(__always)
  func get() -> Int32 {
    return lockedRead { $0 }
  }

  /// Checks if the stored value is equal to the provided parameter
  /// - parameters:
  ///   - to: The value to be checked against
  /// - returns: `true` if the values matches; otherwise `false`
  @inline(__always)
  func isEqual(to flag: Int32) -> Bool {
    return (get() & flag) != 0
  }
}
