//
//  AnyJSONObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
///
/// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
/// While these symbols are public, they are intended strictly for internal usage.
///
/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc
public class KMPAnyJSON: NSObject {
  public let value: AnyJSON

  @objc
  public init(_ value: Any?) {
    if let anyJSON = value as? AnyJSON {
      self.value = anyJSON
    } else if value == nil {
      self.value = AnyJSON(AnyJSONType.null)
    } else {
      self.value = AnyJSON(value as Any)
    }
  }

  @objc
  public func asString() -> String? {
    value.stringOptional
  }

  @objc
  public func asMap() -> [String: Any]? {
    value.dictionaryOptional
  }

  @objc
  public func asList() -> [Any]? {
    value.arrayOptional
  }

  @objc
  public func isNull() -> Bool {
    value.isNil
  }

  @objc
  public func asInt() -> NSNumber? {
    if let intValue = value.intOptional {
      NSNumber(value: intValue)
    } else {
      nil
    }
  }

  @objc
  public func asDouble() -> NSNumber? {
    if let doubleValue = value.doubleOptional {
      NSNumber(value: doubleValue)
    } else {
      nil
    }
  }

  @objc
  public func asBool() -> NSNumber? {
    if let boolValue = value.boolOptional {
      NSNumber(value: boolValue)
    } else {
      nil
    }
  }

  @objc
  public func asNumber() -> NSNumber? {
    if let doubleValue = value.doubleOptional {
      NSNumber(value: doubleValue)
    } else if let intValue = value.intOptional {
      NSNumber(value: intValue)
    } else {
      nil
    }
  }
}
