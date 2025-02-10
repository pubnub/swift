//
//  Logger.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import os

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension Logger {
  static var subsystem: String { "com.pubnub"}
  static let eventEngine = Logger(subsystem: subsystem, category: LogCategory.eventEngine.rawValue)
  static let defaultLogger = Logger(subsystem: subsystem, category: LogCategory.none.rawValue)
  static let network = Logger(subsystem: subsystem, category: LogCategory.networking.rawValue)
  static let crypto = Logger(subsystem: subsystem, category: LogCategory.crypto.rawValue)
  static let pubNub = Logger(subsystem: subsystem, category: LogCategory.pubNub.rawValue)
}
