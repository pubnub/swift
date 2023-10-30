//
//  DispatchQueue+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension DispatchQueue {
  /// The label of the current `DispatchQueue`
  /// or `"Unknown Queue"` if no label was set
  static var currentLabel: String {
    return String(validatingUTF8: __dispatch_queue_get_label(nil)) ?? "Unknown Queue"
  }
}
