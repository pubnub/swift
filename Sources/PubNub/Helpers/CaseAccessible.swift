//
//  CaseAccessible.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

protocol CaseAccessible {
  var casePath: String { get }
  func associatedValue<AssociatedValue>(matching casePath: (AssociatedValue) -> Self) -> AssociatedValue?
}

extension CaseAccessible {
  var casePath: String {
    return Mirror(reflecting: self).children.first?.label ?? String(describing: self)
  }

  func associatedValue<AssociatedValue>(matching casePath: (AssociatedValue) -> Self) -> AssociatedValue? {
    guard let decomposed: (casePath: String, value: AssociatedValue) = decompose(),
          let mirrorCasePath = Mirror(reflecting: casePath(decomposed.value)).children.first?.label,
          decomposed.casePath == mirrorCasePath
    else { return nil }

    return decomposed.1
  }

  private func decompose<AssociatedValue>() -> (casePath: String, value: AssociatedValue)? {
    for case let (casePath?, value) in Mirror(reflecting: self).children {
      if let result = value as? AssociatedValue ?? Mirror(reflecting: value).children.first?.value as? AssociatedValue {
        return (casePath, result)
      }
    }
    return nil
  }

  subscript<AssociatedValue>(
    case path: (AssociatedValue) -> Self
  ) -> AssociatedValue? { return associatedValue(matching: path) }
  subscript<AssociatedValue>(
    case path: (AssociatedValue) -> Self,
    default value: AssociatedValue
  ) -> AssociatedValue { return associatedValue(matching: path) ?? value }
}
