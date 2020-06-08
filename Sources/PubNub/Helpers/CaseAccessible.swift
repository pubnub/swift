//
//  CaseAccessible.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2020 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
