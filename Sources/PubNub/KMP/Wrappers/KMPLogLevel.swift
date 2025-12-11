//
//  KMPLogLevel.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
//
// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
// While these symbols are public, they are intended strictly for internal usage.
//
// External developers should refrain from directly using these symbols in their code, as their implementation details
// may change in future versions of the framework, potentially leading to breaking changes.

import Foundation

@objc public class KMPLogLevel: NSObject {
  @objc public static let none: KMPLogLevel = .init(rawValue: LogLevel.none.rawValue)
  @objc public static let trace: KMPLogLevel = .init(rawValue: LogLevel.info.rawValue)
  @objc public static let debug: KMPLogLevel = .init(rawValue: LogLevel.debug.rawValue)
  @objc public static let info: KMPLogLevel = .init(rawValue: LogLevel.info.rawValue)
  @objc public static let event: KMPLogLevel = .init(rawValue: LogLevel.event.rawValue)
  @objc public static let warn: KMPLogLevel = .init(rawValue: LogLevel.warn.rawValue)
  @objc public static let error: KMPLogLevel = .init(rawValue: LogLevel.error.rawValue)
  @objc public static let all: KMPLogLevel = .init(rawValue: LogLevel.all.rawValue)

  @objc public private(set) var rawValue: UInt32

  @objc public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }

  func toLogLevel() -> LogLevel {
    LogLevel(rawValue: rawValue)
  }
}
