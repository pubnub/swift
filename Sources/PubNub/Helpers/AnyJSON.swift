//
//  AnyJSON.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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

enum AnyJSONError: Error {
  case stringCreationFailure
}

extension AnyJSONError: LocalizedError {
  var localizedDescription: String {
    switch self {
    case .stringCreationFailure:
      return "`String(data:ecoding:) returned nil when converting JSON Data to a `String`"
    }
  }
}

public struct AnyJSON {
  public let value: Any

  public init(_ value: Any) {
    self.value = value
  }

  public func jsonEncodedData() throws -> Data {
    return try JSONEncoder().encode(self)
  }

  public func jsonString() throws -> String {
    guard let decodedString = try String(data: jsonEncodedData(), encoding: .utf8) else {
      throw AnyJSONError.stringCreationFailure
    }

    return decodedString
  }

  public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    return try JSONDecoder().decode(type, from: jsonEncodedData())
  }
}

extension AnyJSON: Hashable {
  // swiftlint:disable:next cyclomatic_complexity
  public static func == (lhs: AnyJSON, rhs: AnyJSON) -> Bool {
    switch (lhs.value, rhs.value) {
    case let (lhs as NSNumber, rhs as NSNumber):
      return lhs == rhs
    case let (lhs as String, rhs as String):
      return lhs == rhs
    case let (lhs as Data, rhs as Data):
      return lhs == rhs
    case let (lhs as TimeInterval, rhs as TimeInterval):
      return lhs == rhs
    case let (lhs as [String: Any], rhs as [String: Any]):
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
    case let (lhs as [Any], rhs as [Any]):
      // Ensure that each array has the same number of elements
      if lhs.count != rhs.count {
        return false
      }
      // Walk through the arrays and compare
      for index in 0 ..< lhs.count where AnyJSON(lhs[index]) != AnyJSON(rhs[index]) {
        return false
      }
      return true
    default:
      return false
    }
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
    case let value as TimeInterval:
      hasher.combine(value)
    case let value as Data:
      hasher.combine(value)
    case let value as [String: Any]:
      hasher.combine(value.compactMap { [$0.key: $0.value as? AnyJSON] })
    case let value as [Any]:
      hasher.combine(value.compactMap { [$0 as? AnyJSON] })
    default:
      break
    }
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

  /// Creates an instance initialized to the given value.
  public init(arrayLiteral: Any...) {
    let literal: [Any] = arrayLiteral.map { element in
      if let date = element as? Date {
        return date.timeIntervalSinceReferenceDate
      }

      return element
    }

    self.init(literal)
  }

  // MARK: ...BooleanLiteral

  /// Creates an instance initialized to the given value.
  public init(booleanLiteral value: Bool) {
    self.init(value)
  }

  // MARK: ...DictionaryLiteral

  /// Creates an instance initialized to the given value.
  public init(dictionaryLiteral elements: (String, Any)...) {
    let json: [String: Any] = elements.reduce(into: [:]) { result, element in
      if let date = element.1 as? Date {
        result[element.0] = date.timeIntervalSinceReferenceDate
      } else {
        result[element.0] = element.1
      }
    }

    self.init(json)
  }

  // MARK: ...FloatLiteral

  /// Creates an instance initialized to the given value.
  public init(floatLiteral value: FloatLiteralType) {
    self.init(value)
  }

  // MARK: ...IntegerLiteral

  /// Creates an instance initialized to the given value.
  public init(integerLiteral value: Int) {
    self.init(value)
  }

  // MARK: ...StringLiteral

  /// Creates an instance initialized to the given value.
  public init(unicodeScalarLiteral value: StringLiteralType) {
    self.init(value)
  }

  /// Creates an instance initialized to the given value.
  public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
    self.init(value)
  }

  /// Creates an instance initialized to the given value.
  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}

extension AnyJSON: ExpressibleByArrayLiteral {}
extension AnyJSON: ExpressibleByBooleanLiteral {}
extension AnyJSON: ExpressibleByDictionaryLiteral {}
extension AnyJSON: ExpressibleByFloatLiteral {}
extension AnyJSON: ExpressibleByIntegerLiteral {}
extension AnyJSON: ExpressibleByStringLiteral {}
