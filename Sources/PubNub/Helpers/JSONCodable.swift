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

public protocol JSONCodable {
  var codableValue: AnyJSON { get }
  var rawValue: Any { get }
}

extension JSONCodable {
  public var rawValue: Any {
    return self
  }

  public var codableValue: AnyJSON {
    return AnyJSON(self)
  }

  public func decode<RawValue>() -> RawValue? {
    return rawValue as? RawValue
  }

  var jsonStringifyResult: Result<String, Error> {
    return codableValue.jsonStringifyResult
  }

  var jsonStringify: String? {
    return try? jsonStringifyResult.get()
  }

  var jsonDataResult: Result<Data, Error> {
    return codableValue.jsonDataResult
  }

  var jsonData: Data? {
    return try? jsonDataResult.get()
  }
}

extension JSONCodable where Self: Equatable {
  func isEqual(_ other: JSONCodable?) -> Bool {
    print("JSONCodable Equatable")
    guard let otherSelf = other as? Self else {
      return false
    }
    print("JSONCodable Equatable: \(self == otherSelf)")
    return self == otherSelf
  }
}

extension Array: JSONCodable {}
extension Dictionary: JSONCodable where Key == String {}

// MARK: JSONCodableScalar

public protocol JSONCodableScalar: JSONCodable {
  var scalarValue: JSONCodableScalarType { get }
}

extension JSONCodableScalar {
  public var codableValue: AnyJSON {
    return AnyJSON(scalarValue.value)
  }

  var stringOptional: String? {
    return scalarValue.value.rawValue as? String
  }

  var stringValue: String? {
    return stringOptional ?? ""
  }

  var intOptional: Int? {
    return scalarValue.value.rawValue as? Int
  }

  var intValue: Int {
    return intOptional ?? 0
  }

  var doubleOptional: Double? {
    return scalarValue.value.rawValue as? Double
  }

  var doubleValue: Double {
    return doubleOptional ?? 0.0
  }

  var boolOptional: Bool? {
    return scalarValue.value.rawValue as? Bool
  }

  var boolValue: Bool {
    return boolOptional ?? false
  }

  var dateOptional: Date? {
    return scalarValue.value.rawValue as? Date
  }

  var dateValue: Date {
    return dateOptional ?? Date.distantPast
  }

  var dataOptional: Data? {
    if let dataString = stringOptional, let data = Data(base64Encoded: dataString) {
      return data
    }
    return nil
  }

  var dataValue: Data {
    return dataOptional ?? Data()
  }
}

extension JSONCodableScalar where Self: Equatable {
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

public struct JSONCodableScalarType: Codable, Equatable {
  let value: AnyJSONType

  init(stringValue: String) {
    value = .string(stringValue)
  }

  init(intValue: Int) {
    value = .integer(intValue as NSNumber)
  }

  init(boolValue: Bool) {
    value = .boolean(boolValue)
  }

  init(doubleValue: Double) {
    value = .double(doubleValue as NSNumber)
  }

  init(dateValue: Date) {
    value = .string(Constant.iso8601DateFormatter.string(from: dateValue))
  }

  // Note: Research why decoding collections containing this object fails when using the synthesized
  // decoder method
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    value = try container.decode(AnyJSONType.self)
  }
}
