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

@objc
public class AnyJSONObjC: NSObject {
  let value: AnyJSON

  @objc
  public init(_ value: Any) {
    if let anyJSON = value as? AnyJSON {
      self.value = anyJSON
    } else {
      self.value = AnyJSON(value)
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
