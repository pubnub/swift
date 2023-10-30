//
//  Bool+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension Bool {
  /// A string value representing `1` for `true` or `0` for `false`
  var stringNumber: String {
    return self ? "1" : "0"
  }
}
