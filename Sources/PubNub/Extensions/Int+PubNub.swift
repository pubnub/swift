//
//  Int+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension Timetoken {
  /// The `Date` that the timetoken represents
  var timetokenDate: Date {
    // No direct conversion of UInt64 (Timetoken) to TimeInterval, so cast to Int64
    return Date(timeIntervalSince1970: TimeInterval(integerLiteral: Int64(self / 10_000_000)))
  }
}
