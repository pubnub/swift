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

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
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

  func lock() {
    os_unfair_lock_lock(unfairLock)
  }

  func unlock() {
    os_unfair_lock_unlock(unfairLock)
  }
}

final class Atomic<Locked> {
  private let lock: NSLocking
  private var value: Locked

  init(_ value: Locked, locker: NSLocking? = nil) {
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
      self.lock = locker ?? UnfairLock()
    } else {
      lock = locker ?? NSLock()
    }

    self.value = value
  }

  var lockedValue: Locked {
    get { return lock.synchronize { value } }
    set { lock.synchronize { value = newValue } }
  }

  @discardableResult
  func lockedRead<Value>(_ closure: (Locked) -> Value) -> Value {
    return lock.synchronize { closure(self.value) }
  }

  func lockedWrite<Value>(_ closure: (inout Locked) -> Value) -> Value {
    return lock.synchronize { closure(&self.value) }
  }
}

extension Atomic where Locked: Collection {
  var isEmpty: Bool {
    return lock.synchronize { value.isEmpty }
  }
}

extension Atomic where Locked: RangeReplaceableCollection {
  func append(_ element: Locked.Element) {
    lockedWrite { (collection: inout Locked) in
      collection.append(element)
    }
  }

  func append<S: Sequence>(contentsOf elements: S) where S.Element == Locked.Element {
    lockedWrite { (sequence: inout Locked) in
      sequence.append(contentsOf: elements)
    }
  }

  func append<C: Collection>(contentsOf elements: C) where C.Element == Locked.Element {
    lockedWrite { (collection: inout Locked) in
      collection.append(contentsOf: elements)
    }
  }
}

extension Atomic where Locked == Request.InternalState {
  func attemptToTransitionTo(_ state: Request.TaskState) -> Bool {
    return lock.synchronize {
      guard value.taskState.canTransition(to: state) else { return false }

      value.taskState = state

      return true
    }
  }

  func withTaskState(perform closure: (Request.TaskState) -> Void) {
    lock.synchronize { closure(value.taskState) }
  }
}
