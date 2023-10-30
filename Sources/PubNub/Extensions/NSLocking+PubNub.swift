//
//  NSLocking+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension NSLocking {
  @inline(__always)
  func synchronize(_ closure: () -> Void) {
    lock()
    defer { unlock() }
    return closure()
  }

  @discardableResult
  @inline(__always)
  func synchronize<T>(_ closure: () -> T) -> T {
    lock()
    defer { unlock() }
    return closure()
  }

  @discardableResult
  @inline(__always)
  func synchronize<T>(_ closure: () throws -> T) throws -> T {
    lock()
    defer { unlock() }
    let result = try closure()
    return result
  }
}
