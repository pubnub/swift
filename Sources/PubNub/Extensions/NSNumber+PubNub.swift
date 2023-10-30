//
//  NSNumber+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension NSNumber {
  /// Attempts to compare the underlying value of the NSNumber for equality
  func isUnderlyingTypeEqual(to other: NSNumber) -> Bool {
    return decimalValue == other.decimalValue ||
      doubleValue == other.doubleValue ||
      floatValue == other.floatValue
  }
}
