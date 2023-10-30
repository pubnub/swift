//
//  Thread+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension Thread {
  /// The name describing the current executing Thread
  static var currentName: String {
    if Thread.isMainThread {
      return "Thread.Main"
    } else if let threadName = Thread.current.name, !threadName.isEmpty {
      return threadName
    } else {
      return String(format: "%p", Thread.current).uppercased()
    }
  }
}
