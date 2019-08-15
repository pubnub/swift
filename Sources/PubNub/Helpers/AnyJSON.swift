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

// swiftlint:disable discouraged_optional_boolean discouraged_optional_collection

/// A `Codable` representation of Any inside a JSON structure
public struct AnyJSON {
  let value: AnyJSONType

  public init(_ value: Any) {
    self.value = AnyJSONType(rawValue: value)
  }

  public init(reverse stringify: String) {
    let rawString = stringify.reverseJSONDescription
    if let bool = Bool(rawString) {
      value = AnyJSONType(rawValue: bool)
    } else if let integer = Int(rawString) {
      value = AnyJSONType(rawValue: integer)
    } else if let double = Double(rawString) {
      value = AnyJSONType(rawValue: double)
    } else if stringify == Constant.jsonNull {
      value = AnyJSONType(rawValue: NSNull())
    } else if let jsonStringData = rawString.data(using: .utf8),
      let decodedAny = try? Constant.jsonDecoder.decode(AnyJSON.self, from: jsonStringData) {
      self = decodedAny
    } else {
      value = AnyJSONType(rawValue: rawString)
    }
  }

  // MARK: - Helpers

  /// A Boolean value that indicates whether the underlying JSON Collection is empty.
  ///
  /// Will also return `true` if the underlying value is not a JSON Collection type or nil
  public var isEmpty: Bool {
    switch value {
    case let .array(value):
      return value.isEmpty
    case let .dictionary(value):
      return value.isEmpty
    case .null:
      return true
    default:
      return false
    }
  }
}

// MARK: - Codable

extension AnyJSON: Codable {
  public init(from decoder: Decoder) throws {
    let jsonTypeValue = try AnyJSONType(from: decoder)
    value = jsonTypeValue
  }

  public func encode(to encoder: Encoder) throws {
    try value.encode(to: encoder)
  }

  /// Decode the internal value to a given `Decodable` type
  /// - parameters:
  ///   - type: The `Type` of the `Any` value contained inside the `AnyJSON`
  /// - returns: The JSON represented as the `Type` value
  /// - throws: A Encoding/Decoding error if the stored `Any` is not valid JSON,
  /// or whose structure does not match the provided `Type`
  public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    return try Constant.jsonDecoder.decode(type, from: Constant.jsonEncoder.encode(self))
  }
}

// MARK: - Collection

public enum AnyJSONIndex: Comparable {
  case arrayIndex(Int)
  case dictionaryIndex(DictionaryIndex<String, Any>)
  case null

  public static func == (lhs: AnyJSONIndex, rhs: AnyJSONIndex) -> Bool {
    switch (lhs, rhs) {
    case let (.arrayIndex(left), .arrayIndex(right)):
      return left == right
    case let (.dictionaryIndex(left), .dictionaryIndex(right)):
      return left == right
    case (.null, .null):
      return true
    default:
      return false
    }
  }

  public static func < (lhs: AnyJSONIndex, rhs: AnyJSONIndex) -> Bool {
    switch (lhs, rhs) {
    case let (.arrayIndex(left), .arrayIndex(right)):
      return left < right
    case let (.dictionaryIndex(left), .dictionaryIndex(right)):
      return left < right
    default:
      return false
    }
  }
}

extension AnyJSON: Collection {
  public var startIndex: AnyJSONIndex {
    switch value {
    case .array:
      return .arrayIndex(arrayValue.startIndex)
    case .dictionary:
      return .dictionaryIndex(dictionaryValue.startIndex)
    default:
      return .null
    }
  }

  public var endIndex: AnyJSONIndex {
    switch value {
    case .array:
      return .arrayIndex(arrayValue.endIndex)
    case .dictionary:
      return .dictionaryIndex(dictionaryValue.endIndex)
    default:
      return .null
    }
  }

  public func index(after index: AnyJSONIndex) -> AnyJSONIndex {
    switch index {
    case let .arrayIndex(index):
      return .arrayIndex(arrayValue.index(after: index))
    case let .dictionaryIndex(index):
      return .dictionaryIndex(dictionaryValue.index(after: index))
    default:
      return .null
    }
  }

  public subscript(position: AnyJSONIndex) -> (String, Any) {
    switch position {
    case let .arrayIndex(index):
      return (String(index), AnyJSON(arrayValue[index]))
    case let .dictionaryIndex(index):
      return (dictionaryValue[index].key, AnyJSON(dictionaryValue[index].value))
    default:
      return ("", AnyJSON(NSNull()))
    }
  }
}

// MARK: - Equatable

extension AnyJSON: Equatable {
  public static func == (lhs: AnyJSON, rhs: AnyJSON) -> Bool {
    return lhs.value == rhs.value
  }
}

// MARK: - JSON Objects

extension AnyJSON {
  var jsonStringifyResult: Result<String, Error> {
    return value.stringify.map { $0.replacingOccurrences(of: "\\/", with: "/") }
  }

  var jsonStringify: String? {
    return try? jsonStringifyResult.get()
  }

  var jsonDataResult: Result<Data, Error> {
    return value.jsonEncodedData
  }

  var jsonData: Data? {
    return try? jsonDataResult.get()
  }
}

// MARK: - Underlying Data Casting

extension AnyJSON {
  /// The underlying `Any` stored inside the `AnyJSON`
  public var underlyingValue: Any {
    return value.rawValue
  }

  public var isNil: Bool {
    return value == .null
  }

  public var stringOptional: String? {
    return underlyingValue as? String
  }

  public var stringValue: String {
    return stringOptional ?? ""
  }

  public var dataOptional: Data? {
    return Data(base64Encoded: stringValue)
  }

  public var dataValue: Data {
    return dataOptional ?? Data()
  }

  public var boolOptional: Bool? {
    return underlyingValue as? Bool
  }

  public var boolValue: Bool {
    return boolOptional ?? false
  }

  public var intOptional: Int? {
    return underlyingValue as? Int
  }

  public var intValue: Int {
    return intOptional ?? 0
  }

  public var doubleOptional: Double? {
    return underlyingValue as? Double
  }

  public var doubleValue: Double {
    return doubleOptional ?? 0.0
  }

  public var arrayOptional: [Any]? {
    return underlyingValue as? [Any]
  }

  public var arrayValue: [Any] {
    return arrayOptional ?? []
  }

  public var wrappedUnderlyingArray: [AnyJSON] {
    return value.rawArray.map { AnyJSON($0) }
  }

  public var dictionaryOptional: [String: Any]? {
    return underlyingValue as? [String: Any]
  }

  public var dictionaryValue: [String: Any] {
    return dictionaryOptional ?? [:]
  }

  public var wrappedUnderlyingDictionary: [String: AnyJSON] {
    return value.rawDictionary.mapValues { AnyJSON($0) }
  }
}

// MARK: - CustomStringConvertible

// MARK: - CustomDebugStringConvertible

extension AnyJSON: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    return jsonStringify ?? Constant.jsonNull
  }

  public var debugDescription: String {
    return String(describing: underlyingValue)
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
    let dictionary = elements.reduce(into: [:]) { $0[$1.0] = $1.1 }

    self.init(dictionary)
  }
}

// MARK: - ExpressibleByBooleanLiteral

extension AnyJSON: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: BooleanLiteralType) {
    self.init(value)
  }
}

// MARK: - ExpressibleByFloatLiteral

extension AnyJSON: ExpressibleByFloatLiteral {
  public init(floatLiteral value: FloatLiteralType) {
    self.init(value)
  }
}

// MARK: - ExpressibleByIntegerLiteral

extension AnyJSON: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: IntegerLiteralType) {
    self.init(value)
  }
}

// MARK: - ExpressibleByStringLiteral

extension AnyJSON: ExpressibleByStringLiteral {
  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}

// MARK: - AnyJSONError

enum AnyJSONError: Error {
  case unknownCoding(Error)
  case stringCreationFailure(Error?)
  case dataCreationFailure(Error?)
}

extension AnyJSONError: LocalizedError {
  var localizedDescription: String {
    switch self {
    case .unknownCoding:
      return "An unknown error occurred while performing `Codable` functions"
    case .stringCreationFailure:
      return ErrorDescription.AnyJSONError.stringCreationFailure
    case .dataCreationFailure:
      return "Failed to create JSONEncoded data"
    }
  }
}

// swiftlint:enable discouraged_optional_boolean discouraged_optional_collection
