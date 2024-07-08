//
//  Dictionary+ObjCRepresentable.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension AnyJSONType {
  var objCRepresentable: Any? {
    switch self {
    case .string(let string):
      return string
    case .integer(let number):
      return number
    case .double(let number):
      return number
    case .boolean(let booleanLiteral):
      return NSNumber(booleanLiteral: booleanLiteral)
    case .array(let array):
      return array.map { $0.objCRepresentable }
    case .dictionary(let dictionary):
      return dictionary.mapValues { $0.objCRepresentable }
    case .codable(let codableValue):
      return codableValue
    case .unknown(let unknownValue):
      return unknownValue
    case .null:
      return NSNull()
    }
  }
}

extension Dictionary<String, any JSONCodableScalar> {
  func asObjCRepresentable() -> [String: Any] {
    compactMapValues {
      $0.scalarValue.underlying.objCRepresentable
    }.compactMapValues {
      $0
    }
  }
}
