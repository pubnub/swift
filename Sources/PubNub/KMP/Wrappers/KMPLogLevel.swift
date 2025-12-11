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
  @objc public static let none: KMPLogLevel = .init(rawValue: 0)
  @objc public static let trace: KMPLogLevel = .init(rawValue: 1 << 0)
  @objc public static let debug: KMPLogLevel = .init(rawValue: 1 << 1)
  @objc public static let info: KMPLogLevel = .init(rawValue: 1 << 2)
  @objc public static let event: KMPLogLevel = .init(rawValue: 1 << 3)
  @objc public static let warn: KMPLogLevel = .init(rawValue: 1 << 4)
  @objc public static let error: KMPLogLevel = .init(rawValue: 1 << 5)
  @objc public static let all: KMPLogLevel = .init(rawValue: UInt32.max)

  @objc public var rawValue: UInt32

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
}
