//
//  AtomicWrapper.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@propertyWrapper
final class AtomicWrapper<Value> {
  private let atomic: Atomic<Value>

  init(wrappedValue: Value) {
    self.atomic = Atomic(wrappedValue)
  }

  var wrappedValue: Value {
    get { atomic.lockedRead { $0 } }
    set { atomic.lockedWrite { $0 = newValue } }
  }
}
