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
public class AnyJSONObjC : NSObject {
    let value: AnyJSON
    public init(_ value: AnyJSON) {
        self.value = value
    }
    
    @objc
    public func asString() -> String? {
        return value.stringOptional
    }
    
    @objc
    public func asMap() -> [String: Any]? {
        return value.dictionaryOptional
    }
    
    @objc
    public func asList() -> [Any]? {
        return value.arrayOptional
    }
    
    @objc
    public func isNull() -> Bool {
        return value.isNil
    }
    
    @objc
    public func asInt() -> NSNumber? {
        return if let intValue = value.intOptional {
            NSNumber(value: intValue)
        } else {
            nil
        }
    }
    
    @objc
    public func asDouble() -> NSNumber? {
        return if let doubleValue = value.doubleOptional {
            NSNumber(value: doubleValue)
        } else {
            nil
        }
    }
    
    @objc
    public func asBool() -> NSNumber? {
        return if let boolValue = value.boolOptional {
            NSNumber(value: boolValue)
        } else {
            nil
        }
    }
    
    @objc
    public func asNumber() -> NSNumber? {
        return if let doubleValue = value.doubleOptional {
            NSNumber(value: doubleValue)
        } else if let intValue = value.intOptional{
            NSNumber(value: intValue)
        } else {
            nil
        }
    }
    
}
