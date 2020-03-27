//
//  AnyJSONType.swift
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

/// The evaluated type of the Any stored inside an `AnyJSON`
public enum AnyJSONType {
  case string(String)
  case integer(NSNumber)
  case double(NSNumber)
  case boolean(Bool)
  case null
  case array([AnyJSONType])
  case dictionary([String: AnyJSONType])

  case codable(Codable)
  case unknown(Any)
}

// MARK: - Codable

extension AnyJSONType: Codable {
  struct AnyJSONTypeCodingKey: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
      self.stringValue = stringValue
    }

    init(stringValue: String, intValue: Int?) {
      self.stringValue = stringValue
      self.intValue = intValue
    }

    // JSON doesn't allow for non-string keys
    var intValue: Int?
    init?(intValue: Int) {
      stringValue = "\(intValue)"
    }
  }

  public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    let data = try Constant.jsonEncoder.encode(self)
    return try Constant.jsonDecoder.decode(type, from: data)
  }

  public init(from decoder: Decoder) throws {
    if let keyed = try? decoder.container(keyedBy: AnyJSONTypeCodingKey.self) {
      self = try AnyJSONType.decode(from: keyed)
    } else if let unkeyed = try? decoder.unkeyedContainer() {
      self = try AnyJSONType.decode(from: unkeyed)
    } else if var singleContainer = try? decoder.singleValueContainer() {
      self = try AnyJSONType.decode(from: &singleContainer)
    } else {
      let context = DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: ErrorDescription.rootLevelDecoding
      )
      throw DecodingError.dataCorrupted(context)
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  private static func decode(from container: inout SingleValueDecodingContainer) throws -> AnyJSONType {
    if container.decodeNil() {
      return .null
    } else if let val = try? container.decode(Bool.self) {
      return .boolean(val)
    } else if let val = try? container.decode(Int.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(Int8.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(Int16.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(Int32.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(Int64.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(UInt.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(UInt8.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(UInt16.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(UInt32.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(UInt64.self) {
      return .integer(val as NSNumber)
    } else if let val = try? container.decode(Double.self) {
      return .double(val as NSNumber)
    } else if let val = try? container.decode(String.self) {
      return .string(val)
    } else {
      let context = DecodingError.Context(
        codingPath: container.codingPath,
        debugDescription: ErrorDescription.rootLevelDecoding
      )
      throw DecodingError.dataCorrupted(context)
    }
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  private static func decode(from container: UnkeyedDecodingContainer) throws -> AnyJSONType {
    var container = container
    var jsonArray = [AnyJSONType]()
    while !container.isAtEnd {
      if try container.decodeNil() {
        jsonArray.append(.null)
      } else if let keyed = try? container.nestedContainer(keyedBy: AnyJSONTypeCodingKey.self) {
        jsonArray.append(try AnyJSONType.decode(from: keyed))
      } else if let unkeyed = try? container.nestedUnkeyedContainer() {
        jsonArray.append(try AnyJSONType.decode(from: unkeyed))

      } else if let val = try? container.decode(Bool.self) {
        jsonArray.append(.boolean(val))
      } else if let val = try? container.decode(Int.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(Int8.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(Int16.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(Int32.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(Int64.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(UInt.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(UInt8.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(UInt16.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(UInt32.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(UInt64.self) {
        jsonArray.append(.integer(val as NSNumber))
      } else if let val = try? container.decode(Double.self) {
        jsonArray.append(.double(val as NSNumber))
      } else if let val = try? container.decode(String.self) {
        jsonArray.append(.string(val))
      } else {
        let context = DecodingError
          .Context(codingPath: container.codingPath,
                   debugDescription: ErrorDescription.unkeyedContainerDecoding)
        throw DecodingError.dataCorrupted(context)
      }
    }
    return .array(jsonArray)
  }

  // swiftlint:disable:next cyclomatic_complexity
  private static func decode(from container: KeyedDecodingContainer<AnyJSONTypeCodingKey>) throws -> AnyJSONType {
    var json = [String: AnyJSONType]()
    for key in container.allKeys {
      if try container.decodeNil(forKey: key) {
        json[key.stringValue] = .null
      } else if let keyed = try? container.nestedContainer(keyedBy: AnyJSONTypeCodingKey.self, forKey: key) {
        json[key.stringValue] = try AnyJSONType.decode(from: keyed)
      } else if let unkeyed = try? container.nestedUnkeyedContainer(forKey: key) {
        json[key.stringValue] = try AnyJSONType.decode(from: unkeyed)
      } else if let val = try? container.decode(Bool.self, forKey: key) {
        json[key.stringValue] = .boolean(val)
      } else if let val = try? container.decode(Int.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(Int8.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(Int16.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(Int32.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(Int64.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(UInt.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(UInt8.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(UInt16.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(UInt32.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(UInt64.self, forKey: key) {
        json[key.stringValue] = .integer(val as NSNumber)
      } else if let val = try? container.decode(Double.self, forKey: key) {
        json[key.stringValue] = .double(val as NSNumber)
      } else if let val = try? container.decode(String.self, forKey: key) {
        json[key.stringValue] = .string(val)
      } else {
        let context = DecodingError
          .Context(codingPath: container.codingPath,
                   debugDescription: ErrorDescription.keyedContainerDecoding)
        throw DecodingError.dataCorrupted(context)
      }
    }
    return .dictionary(json)
  }

  // MARK: - Encoder

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .array:
      try container.encode(rawArray)
    case .dictionary:
      try container.encode(rawDictionary)
    case .integer:
      try encodeRawNumber(&container)
    case .double:
      try encodeRawNumber(&container)
    case let .string(value):
      try container.encode(value)
    case let .boolean(value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    case let .codable(value):
      try value.encode(from: &container)
    default:
      let context = EncodingError.Context(
        codingPath: encoder.codingPath,
        debugDescription: ErrorDescription.rootLevelEncoding
      )
      throw EncodingError.invalidValue(self, context)
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  func encodeRawNumber(_ container: inout SingleValueEncodingContainer) throws {
    switch self {
    case let .integer(number):
      switch number {
      case let intValue as Int:
        try container.encode(intValue)
      case let int8Value as Int8:
        try container.encode(int8Value)
      case let int32Value as Int32:
        try container.encode(int32Value)
      case let int64Value as Int64:
        try container.encode(int64Value)
      case let uintValue as UInt:
        try container.encode(uintValue)
      case let uint8Value as UInt8:
        try container.encode(uint8Value)
      case let uint16Value as UInt16:
        try container.encode(uint16Value)
      case let uint32Value as UInt32:
        try container.encode(uint32Value)
      case let uint64Value as UInt64:
        try container.encode(uint64Value)
      default:
        try container.encodeNil()
      }
    case let .double(doubleValue as Double):
      try container.encode(doubleValue)
    default:
      try container.encodeNil()
    }
  }
}

// MARK: - RawRepresentable

extension AnyJSONType: RawRepresentable {
  public var rawValue: Any {
    switch self {
    case let .string(value):
      return value
    case let .integer(value):
      return value
    case let .double(value):
      return value
    case let .boolean(value):
      return value
    case .null:
      return Constant.jsonNullObject
    case let .array(value):
      return value.map { $0.rawValue }
    case let .dictionary(value):
      return value.mapValues { $0.rawValue }
    case let .codable(value):
      return value
    case let .unknown(value):
      return value
    }
  }

  public var isNil: Bool {
    return self == .null
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  public init(rawValue: Any) {
    switch rawValue {
    case let value as AnyJSON:
      self = value.value
    case let value as AnyJSONType:
      self = value
    case let value as String:
      self = .string(value)
    case let value as Bool:
      self = .boolean(value)
    case let intValue as Int:
      self = .integer(intValue as NSNumber)
    case let intValue as Int8:
      self = .integer(intValue as NSNumber)
    case let intValue as Int16:
      self = .integer(intValue as NSNumber)
    case let intValue as Int32:
      self = .integer(intValue as NSNumber)
    case let intValue as Int64:
      self = .integer(intValue as NSNumber)
    case let intValue as UInt:
      self = .integer(intValue as NSNumber)
    case let intValue as UInt8:
      self = .integer(intValue as NSNumber)
    case let intValue as UInt16:
      self = .integer(intValue as NSNumber)
    case let intValue as UInt32:
      self = .integer(intValue as NSNumber)
    case let intValue as UInt64:
      self = .integer(intValue as NSNumber)
    case let doubleValue as Float:
      self = .double(doubleValue as NSNumber)
    case let doubleValue as Double:
      self = .double(doubleValue as NSNumber)
    case let doubleValue as Decimal:
      self = .double(doubleValue as NSNumber)
    case let numberValue as NSNumber:
      self = .double(numberValue as NSNumber)
    case _ as NSNull:
      self = .null
    case nil:
      self = .null
    case let value as [Any]:
      self = .array(value.compactMap(AnyJSONType.init))
    case let value as [String: Any]:
      self = .dictionary(value.compactMapValues(AnyJSONType.init))
    case let value as Codable:
      self = .codable(value)
    default:
      self = .unknown(rawValue)
    }
  }

  public func rawValueAs<T>() -> T? {
    return rawValue as? T
  }
}

// MARK: - Hashable

extension AnyJSONType: Hashable {
  // swiftlint:disable:next cyclomatic_complexity
  public static func == (lhs: AnyJSONType, rhs: AnyJSONType) -> Bool {
    switch (lhs, rhs) {
    case let (.string(lhsString), .string(rhsString)):
      return lhsString == rhsString
    case let (.integer(lhsNumber), .integer(rhsNumber)):
      return lhsNumber == rhsNumber
    case let (.double(lhsNumber), .double(rhsNumber)):
      return lhsNumber.isUnderlyingTypeEqual(to: rhsNumber)
    case let (.boolean(lhsBool), .boolean(rhsBool)):
      return lhsBool == rhsBool
    case (.null, .null):
      return true
    case let (.array(lhsArray), .array(rhsArray)):
      if lhsArray.count == rhsArray.count {
        for (index, lhsValue) in lhsArray.enumerated() {
          if AnyJSONType(rawValue: lhsValue) != AnyJSONType(rawValue: rhsArray[index]) {
            return false
          }
        }
        return true
      }
      return false
    case let (.dictionary(lhsDict), .dictionary(rhsDict)):
      return lhsDict.allSatisfy {
        rhsDict[$0] == $1
      }
    case let (.codable(lhsCodable), .codable(rhsCodable)):
      return (try? lhsCodable.encodableJSONData.get() == rhsCodable.encodableJSONData.get()) ?? false
    case (.unknown, .unknown):
      return false
    default:
      return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch self {
    case let .string(value):
      value.hash(into: &hasher)
    case let .integer(value):
      value.hash(into: &hasher)
    case let .double(value):
      value.hash(into: &hasher)
    case let .boolean(value):
      value.hash(into: &hasher)
    case let .array(value):
      value.hash(into: &hasher)
    case let .dictionary(value):
      value.hash(into: &hasher)
    default:
      break
    }
  }
}

// MARK: - AnyJSONType Collections

extension AnyJSONType {
  var isScalar: Bool {
    switch self {
    case .string:
      return true
    case .integer:
      return true
    case .double:
      return true
    case .boolean:
      return true
    case .null:
      return true
    case .array:
      return false
    case .dictionary:
      return false
    case .codable:
      return false
    case .unknown:
      return true
    }
  }

  var rawArray: [AnyJSONType] {
    switch self {
    case let .array(arrayValue):
      return arrayValue.map { AnyJSONType(rawValue: $0) }
    default:
      return []
    }
  }

  var rawDictionary: [String: AnyJSONType] {
    switch self {
    case let .dictionary(dictionaryValue):
      var anyJSONDictionary = [String: AnyJSONType]()
      dictionaryValue.forEach { pair in
        anyJSONDictionary[pair.key] = AnyJSONType(rawValue: pair.value)
      }
      return anyJSONDictionary
    default:
      return [:]
    }
  }

  var stringify: Result<String, Error> {
    switch self {
    case let .string(value):
      return .success(value.jsonDescription)
    case let .integer(value):
      return .success(value.description)
    case let .double(value):
      return .success(value.description)
    case let .boolean(value):
      return .success(value.description)
    case .null:
      return .success(Constant.jsonNull)
    case let .array(value):
      return stringify(collection: value)
    case let .dictionary(value):
      return stringify(collection: value)
    case let .codable(value):
      return value.encodableJSONString
    case .unknown:
      return .failure(AnyJSONError.stringCreationFailure(nil))
    }
  }

  func stringify<T: Encodable>(collection value: T) -> Result<String, Error> {
    do {
      let data = try Constant.jsonEncoder.encode(value)

      if let string = String(data: data, encoding: .utf8) {
        return .success(string)
      }
      return .failure(AnyJSONError.stringCreationFailure(nil))
    } catch {
      return .failure(AnyJSONError.stringCreationFailure(error))
    }
  }

  var jsonEncodedData: Result<Data, Error> {
    switch self {
    case .string, .integer, .double, .boolean, .null:
      return self.stringify.flatMap { string -> Result<Data, Error> in
        if let data = string.data(using: .utf8) {
          return .success(data)
        }
        return .failure(AnyJSONError.dataCreationFailure(nil))
      }
    case let .array(arrayValue):
      return arrayValue.encodableJSONData
    case let .dictionary(dictionaryValue):
      return dictionaryValue.encodableJSONData
    case let .codable(codableValue):
      return codableValue.encodableJSONData
    case .unknown:
      return .failure(AnyJSONError.dataCreationFailure(nil))
    }
  }
}

// swiftlint:disable:this file_length
