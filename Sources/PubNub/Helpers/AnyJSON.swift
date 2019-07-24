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
  public let value: Any

  public init(_ value: Any) {
    if let list = value as? [Any] {
      self.value = transform(list: list)
    } else if let dict = value as? [String: Any] {
      self.value = transform(dictionary: dict)
    } else {
      self.value = value
    }
  }
}

extension AnyJSON: Hashable {
  public static func == (lhs: AnyJSON, rhs: AnyJSON) -> Bool {
    switch (lhs.value, rhs.value) {
    case let (lhs as NSNumber, rhs as NSNumber):
      return lhs == rhs
    case let (lhs as String, rhs as String):
      return lhs == rhs
    case let (lhs as Data, rhs as Data):
      return lhs == rhs
    case let (lhs as [String: Any], rhs as [String: Any]):
      return compare(lhs: lhs, rhs: rhs)
    case let (lhs as [Any], rhs as [Any]):
      return compare(lhs: lhs, rhs: rhs)
    default:
      return false
    }
  }

  private static func compare(lhs: [String: Any], rhs: [String: Any]) -> Bool {
    // Ensure the dictionaries have the same number of items
    if lhs.count != rhs.count {
      return false
    }
    // Walk through keys to ensure that each value is equal
    for (key, lhv) in lhs {
      guard let rhv = rhs[key], AnyJSON(lhv) == AnyJSON(rhv) else {
        return false
      }
    }
    return true
  }

  private static func compare(lhs: [Any], rhs: [Any]) -> Bool {
    // Ensure that each array has the same number of elements
    if lhs.count != rhs.count {
      return false
    }
    // Walk through the arrays and compare
    for index in 0 ..< lhs.count where AnyJSON(lhs[index]) != AnyJSON(rhs[index]) {
      return false
    }
    return true
  }

  // swiftlint:disable:next cyclomatic_complexity
  public func hash(into hasher: inout Hasher) {
    switch value {
    case let value as Bool:
      hasher.combine(value)
    case let value as Int:
      hasher.combine(value)
    case let value as Int8:
      hasher.combine(value)
    case let value as Int16:
      hasher.combine(value)
    case let value as Int32:
      hasher.combine(value)
    case let value as Int64:
      hasher.combine(value)
    case let value as UInt:
      hasher.combine(value)
    case let value as UInt8:
      hasher.combine(value)
    case let value as UInt16:
      hasher.combine(value)
    case let value as UInt32:
      hasher.combine(value)
    case let value as UInt64:
      hasher.combine(value)
    case let value as Float:
      hasher.combine(value)
    case let value as Double:
      hasher.combine(value)
    case let value as String:
      hasher.combine(value)
    case let value as Data:
      hasher.combine(value)
    case let value as [String: Any]:
      let map = value.compactMapValues { AnyJSON($0) }
      hasher.combine(map)
    case let value as [Any]:
      hasher.combine(value.compactMap { [AnyJSON($0)] })
    default:
      break
    }
  }
}

func transform(list elements: [Any]) -> [Any] {
  let json: [Any] = elements.map { element in
    if let date = element as? Date {
      return Constant.iso8601Full.string(from: date)
    }
    return element
  }
  return json
}

func transform(sequnce pairs: [(String, Any)]) -> [String: Any] {
  return pairs.reduce(into: [:]) { result, element in
    if let date = element.1 as? Date {
      result[element.0] = Constant.iso8601Full.string(from: date)
    } else {
      result[element.0] = element.1
    }
  }
}

func transform(dictionary pairs: [String: Any]) -> [String: Any] {
  return pairs.mapValues { value in
    if let date = value as? Date {
      return Constant.iso8601Full.string(from: date)
    }
    return value
  }
}

// MARK: - CustomStringConvertible

extension AnyJSON: CustomStringConvertible {
  public var description: String {
    if let value = value as? CustomStringConvertible {
      return value.description
    }

    return String(describing: value)
  }
}

// MARK: - CustomDebugStringConvertible

extension AnyJSON: CustomDebugStringConvertible {
  public var debugDescription: String {
    if let value = value as? CustomDebugStringConvertible {
      return value.debugDescription
    }

    return String(describing: value)
  }
}

// MARK: - ExpressibleBy...

extension AnyJSON {
  // MARK: ...ArrayLiteral

  public init(arrayLiteral elements: Any...) {
    self.init(transform(list: elements))
  }

  // MARK: ...BooleanLiteral

  public init(booleanLiteral value: Bool) {
    self.init(value)
  }

  // MARK: ...DictionaryLiteral

  public init(dictionaryLiteral elements: (String, Any)...) {
    self.init(transform(sequnce: elements))
  }

  // MARK: ...FloatLiteral

  public init(floatLiteral value: FloatLiteralType) {
    self.init(value)
  }

  // MARK: ...IntegerLiteral

  public init(integerLiteral value: Int) {
    self.init(value)
  }

  // MARK: ...StringLiteral

  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}

// MARK: ExpiressibleBy... Inheritance

extension AnyJSON: ExpressibleByArrayLiteral {}
extension AnyJSON: ExpressibleByBooleanLiteral {}
extension AnyJSON: ExpressibleByDictionaryLiteral {}
extension AnyJSON: ExpressibleByFloatLiteral {}
extension AnyJSON: ExpressibleByIntegerLiteral {}
extension AnyJSON: ExpressibleByStringLiteral {}
