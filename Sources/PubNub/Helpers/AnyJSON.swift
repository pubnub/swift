//
//  AnyJSON.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

/// A `Codable` representation of Any inside a JSON structure
public struct AnyJSON {
  let value: Any

  init(_ value: [Any])  {
    self.value = value
  }

  init(_ value: [String: Any])  {
    self.value = value
  }

  // MARK: - Helpers

  // swiftlint:disable discouraged_optional_collection

  /// The value cast as a JSON Array
  public var arrayValue: [Any]? {
    return value as? [Any]
  }

  /// The value cast as a JSON Dictionary
  public var dictionaryValue: [String: Any]? {
    return value as? [String: Any]
  }

  /// A Boolean value that indicates whether the underlying JSON Collection is empty.
  ///
  /// Will also return `true` if the underlying value is not a JSON Collection type
  public var isEmpty: Bool {
    if let array = arrayValue {
      return array.isEmpty
    } else if let dictionary = dictionaryValue {
      return dictionary.isEmpty
    } else {
      return true
    }
  }

  // swiftlint:enable discouraged_optional_collection
}

extension AnyJSON: Hashable {
  public static func == (lhs: AnyJSON, rhs: AnyJSON) -> Bool {
    return compare(lhs.value, rhs.value)
  }

  // swiftlint:disable:next cyclomatic_complexity
  private static func compare(_ lhs: Any, _ rhs: Any) -> Bool {
    switch (lhs, rhs) {
    case let (lhs as [String: Any], rhs as [String: Any]):
      return compare(lhs, rhs)
    case let (lhs as [Any], rhs as [Any]):
      return compare(lhs, rhs)
    case let (lhs as Date, rhs as Date):
      return lhs == rhs
    case let (lhs as Data, rhs as Data):
      return lhs == rhs
    case let (lhs as Bool, rhs as Bool):
      return lhs == rhs
    case let (lhs as String, rhs as String):
      return lhs == rhs
    case let (lhs as Int, rhs as Int):
      return lhs == rhs
    case let (lhs as Double, rhs as Double):
      return lhs.isEqual(to: rhs)
    case let (lhs as NSDecimalNumber, rhs as NSDecimalNumber):
      return lhs.decimalValue == rhs.decimalValue
    case let (lhs as NSNumber, rhs as NSNumber):
      return lhs.isUnderlyingTypeEqual(to: rhs)
    case let (lhs as NSObject, rhs as NSObject):
      return lhs.isEqual(rhs)
    default:
      return false
    }
  }

  private static func compare(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
    // Ensure the dictionaries have the same number of items
    if lhs.count != rhs.count {
      return false
    }
    // Walk through keys to ensure that each value is equal
    for (key, lhv) in lhs {
      guard let rhv = rhs[key], compare(lhv, rhv) else {
        return false
      }
    }
    return true
  }

  private static func compare(_ lhs: [Any], _ rhs: [Any]) -> Bool {
    // Ensure that each array has the same number of elements
    if lhs.count != rhs.count {
      return false
    }
    // Walk through the arrays and compare
    for index in 0 ..< lhs.count where !compare(lhs[index], rhs[index]) {
      return false
    }
    return true
  }

  public func hash(into hasher: inout Hasher) {
    hash(into: &hasher, value: value)
  }

  private func hash(into hasher: inout Hasher, value: Any) {
    switch value {
    case let value as Bool:
      hasher.combine(value)
    case let value as String:
      hasher.combine(value)
    case let value as Int:
      hasher.combine(value)
    case let value as Double:
      hasher.combine(value)
    case let value as [String: Any]:
      let ordered = value.sorted { $0.key < $1.key }
      ordered.forEach { hash(into: &hasher, value: $0.value) }
    case let value as [Any]:
      value.forEach { hash(into: &hasher, value: $0) }
    default:
      break
    }
  }
}

// MARK: - CustomStringConvertible

extension AnyJSON: CustomStringConvertible {
  public var description: String {
    if let json = try? self.jsonString() {
      return json
    }

    if let value = value as? CustomStringConvertible {
      return value.description
    }

    return String(describing: value)
  }
}

// MARK: - CustomDebugStringConvertible

extension AnyJSON: CustomDebugStringConvertible {
  public var debugDescription: String {

    if let json = try? self.jsonString() {
      return json
    }

    if let value = value as? CustomDebugStringConvertible {
      return value.debugDescription
    }

    return String(describing: value)
  }
}

// MARK: - ExpressibleByArrayLiteral

extension AnyJSON: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Codable...) {
    self.init(elements.map { $0 })
  }
}

// MARK: - ExpressibleByDictionaryLiteral

extension AnyJSON: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, Codable)...) {
    let dictionary = elements.reduce(into: [:]) { result, element in
      result[element.0] = element.1
    }
    self.init(dictionary)
  }
}
