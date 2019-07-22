//
//  LockBox.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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
final class UnfairLock: NSObject, NSLocking {
  private var unfairLock = os_unfair_lock()

  func lock() {
    os_unfair_lock_lock(&unfairLock)
  }

  func unlock() {
    os_unfair_lock_unlock(&unfairLock)
  }
}

final class Atomic<T> {
  private let lock: NSLocking
  private var value: T

  init(_ value: T, locker: NSLocking? = nil) {
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
      self.lock = locker ?? UnfairLock()
    } else {
      lock = locker ?? NSLock()
    }

    self.value = value
  }

  var lockedValue: T {
    get {
      return lock.keyhole { value }
    }
    set {
      lock.keyhole { value = newValue }
    }
  }

  @discardableResult
  func read<V>(_ closure: (T) -> V) -> V {
    return lock.keyhole { closure(self.value) }
  }

  func write<V>(_ closure: (inout T) -> V) -> V {
    return lock.keyhole { closure(&self.value) }
  }

  @discardableResult
  func swap(_ value: T) -> T {
    return lock.keyhole {
      let current = self.value
      self.value = value
      return current
    }
  }
}

extension Atomic where T: Collection {
  var isEmpty: Bool {
    return lock.keyhole { value.isEmpty }
  }
}

extension Atomic where T: RangeReplaceableCollection {
  func append(_ element: T.Element) {
    write { (collection: inout T) in
      collection.append(element)
    }
  }

  func append<S: Sequence>(contentsOf elements: S) where S.Element == T.Element {
    write { (sequence: inout T) in
      sequence.append(contentsOf: elements)
    }
  }

  func append<C: Collection>(contentsOf elements: C) where C.Element == T.Element {
    write { (collection: inout T) in
      collection.append(contentsOf: elements)
    }
  }
}

extension Atomic where T == Request.InternalState {
  func attemptToTransitionTo(_ state: Request.TaskState) -> Bool {
    return lock.keyhole {
      guard value.taskState.canTransition(to: state) else { return false }

      value.taskState = state

      return true
    }
  }

  func withTaskState(perform closure: (Request.TaskState) -> Void) {
    lock.keyhole { closure(value.taskState) }
  }
}
