//
//  JSONCodable.swift
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

// MARK: JSONCodable

/// An object that can be represented as JSON
public protocol JSONCodable: Codable {
  /// The concrete type used during `Codable` operations
  var codableValue: AnyJSON { get }
  /// An `Any` representation of the underlying type data
  var rawValue: Any { get }
}

extension JSONCodable {
  public var rawValue: Any {
    return self
  }

  public var codableValue: AnyJSON {
    return AnyJSON(self)
  }

  /// True if the underlying value is a scalar JSON element; false if it's a Collection
  public var isScalar: Bool {
    return codableValue.value.isScalar
  }

  /// A `Result` that is either the underlying value as a JSON `String` or an error why it couldn't be created
  public var jsonStringifyResult: Result<String, Error> {
    return codableValue.jsonStringifyResult
  }

  /// The underlying value as a JSON `String` if it could be created
  public var jsonStringify: String? {
    return codableValue.jsonStringify
  }

  /// A `Result` that is either the underlying value as JSON Encoded `Data` or an error why it couldn't be created
  public var jsonDataResult: Result<Data, Error> {
    return codableValue.jsonDataResult
  }

  /// The underlying value as a JSON encoded `Data` if it could be created
  public var jsonData: Data? {
    return codableValue.jsonData
  }

  /// Whether the underlying value is coded to Null
  public var isNil: Bool {
    return codableValue.isNil
  }

  /// The underlying value as a `String` or nil if the value was not a `String`
  public var stringOptional: String? {
    return rawValue as? String
  }

  /// The underlying value as a `Int` or nil if the value was not a `Int`
  public var intOptional: Int? {
    return rawValue as? Int
  }

  /// The underlying value as a `Double` or nil if the value was not a `Double`
  public var doubleOptional: Double? {
    return rawValue as? Double
  }

  /// The underlying value as a `Bool` or nil if the value was not a `Bool`
  public var boolOptional: Bool? {
    return rawValue as? Bool
  }

  /// The underlying value as a `Date` or nil if the value was not a `Date`
  public var dateOptional: Date? {
    return rawValue as? Date
  }

  /// The underlying value as a `Data` or nil if the value was not a `Data`
  public var dataOptional: Data? {
    if let dataString = stringOptional, let data = Data(base64Encoded: dataString) {
      return data
    }
    return nil
  }
}

extension Array: JSONCodable where Element: JSONCodable {}
extension Dictionary: JSONCodable where Key == String, Value: JSONCodable {}

extension AnyJSON: JSONCodable {
  public var codableValue: AnyJSON {
    return self
  }

  public var rawValue: Any {
    return underlyingValue
  }
}

// MARK: JSONCodableScalar

/// An object that can be represented as JSON Scalar values
public protocol JSONCodableScalar: JSONCodable {
  /// The concrete type used during `Codable` operations
  var scalarValue: JSONCodableScalarType { get }
}

extension JSONCodableScalar {
  public var codableValue: AnyJSON {
    return AnyJSON(scalarValue.underlying)
  }

  /// The underlying value as an `Any`
  public var rawValue: Any {
    return scalarValue.underlying.rawValue
  }
}

extension JSONCodableScalar where Self: Equatable {
  /// A bridge that allows for `Equatable` functionality on non-concrete types
  func isEqual(_ other: JSONCodableScalar?) -> Bool {
    guard let otherSelf = other as? Self else {
      return false
    }
    return self == otherSelf
  }
}

extension String: JSONCodableScalar {
  public var scalarValue: JSONCodableScalarType {
    return JSONCodableScalarType(stringValue: self)
  }
}

extension Int: JSONCodableScalar {
  public var scalarValue: JSONCodableScalarType {
    return JSONCodableScalarType(intValue: self)
  }
}

extension Double: JSONCodableScalar {
  public var scalarValue: JSONCodableScalarType {
    return JSONCodableScalarType(doubleValue: self)
  }
}

extension Bool: JSONCodableScalar {
  public var scalarValue: JSONCodableScalarType {
    return JSONCodableScalarType(boolValue: self)
  }
}

extension Date: JSONCodableScalar {
  public var scalarValue: JSONCodableScalarType {
    return JSONCodableScalarType(dateValue: self)
  }
}

extension JSONCodableScalarType: JSONCodableScalar {
  public var scalarValue: JSONCodableScalarType {
    return self
  }
}

// MARK: JSONCodableScalarType

/// A concrete type used by `JSONCodableScalarType` during `Codable` operations
public struct JSONCodableScalarType: Codable, Hashable {
  /// The underlying value
  let underlying: AnyJSONType

  public init(stringValue: String?) {
    if let value = stringValue {
      underlying = .string(value)
    } else {
      underlying = .null
    }
  }

  public init(intValue: Int) {
    underlying = .integer(intValue as NSNumber)
  }

  public init(boolValue: Bool) {
    underlying = .boolean(boolValue)
  }

  public init(doubleValue: Double) {
    underlying = .double(doubleValue as NSNumber)
  }

  public init(dateValue: Date) {
    underlying = .string(DateFormatter.iso8601.string(from: dateValue))
  }

  // Note: Research why decoding collections containing this object
  // fails when using the synthesized decoder method
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    underlying = try container.decode(AnyJSONType.self)
  }

  // Required or this will default to encoding the `underlying` key
  // instead of a `singleValueContainer` of the underlying value
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(underlying)
  }
}
