//
//  BoundedValue.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A value that has forced constraints on its upper and/or lower bounds
@propertyWrapper public struct BoundedValue<Value>: Comparable where Value: Comparable {
  public static func < (lhs: BoundedValue<Value>, rhs: BoundedValue<Value>) -> Bool {
    return lhs.value < rhs.value
  }

  var value: Value
  let max: Value
  let min: Value

  init(wrappedValue: Value, min: Value, max: Value) {
    value = wrappedValue
    self.min = min
    self.max = max
  }

  /// The bounded value
  public var wrappedValue: Value {
    get { return value }
    set {
      if newValue < min {
        value = min
      } else if newValue > max {
        value = max
      } else {
        value = newValue
      }
    }
  }
}

extension BoundedValue: Hashable where Value: Hashable {}
