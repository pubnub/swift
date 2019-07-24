//
//  AnyJSON+Codable.swift
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

extension AnyJSON {
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

extension AnyJSON: Codable {
  // MARK:- Decodable

  public init(from decoder: Decoder) throws {
    if let keyed = try? decoder.container(keyedBy: AnyJSONCodingKey.self) {
      self.init(try AnyJSON.decode(from: keyed))
    } else if let unkeyed = try? decoder.unkeyedContainer() {
      self.init(try AnyJSON.decode(from: unkeyed))
      // SingleValueDecodingContainer
    } else if let val = try? decoder.singleValueContainer().decode(String.self) {
      self.init(val)
    } else if let val = try? decoder.singleValueContainer().decode(Bool.self) {
      self.init(val)
    } else if let val = try? decoder.singleValueContainer().decode(Int.self) {
      self.init(val)
    } else if let val = try? decoder.singleValueContainer().decode(Double.self) {
      self.init(val)
    } else if let val = try? decoder.singleValueContainer().decode(Date.self) {
      self.init(val)
    } else {
      let message = "AnyJSON could not decode value inside `SingleValueDecodingContainer`"
      let context = DecodingError.Context(codingPath: decoder.codingPath,
                                          debugDescription: message)
      throw DecodingError.dataCorrupted(context)
    }
  }

  // KeyedDecodingContainer
  private static func decode(from container: KeyedDecodingContainer<AnyJSONCodingKey>) throws -> [String: Any] {
    var json = [String: Any]()
    for key in container.allKeys {
      if let keyed = try? container.nestedContainer(keyedBy: AnyJSONCodingKey.self, forKey: key) {
        json[key.stringValue] = try AnyJSON.decode(from: keyed)
      } else if let unkeyed = try? container.nestedUnkeyedContainer(forKey: key) {
        json[key.stringValue] = try AnyJSON.decode(from: unkeyed)
      } else if let val = try? container.decode(String.self, forKey: key) {
        json[key.stringValue] = val
      } else if let val = try? container.decode(Bool.self, forKey: key) {
        json[key.stringValue] = val
      } else if let val = try? container.decode(Int.self, forKey: key) {
        json[key.stringValue] = val
      } else if let val = try? container.decode(Double.self, forKey: key) {
        json[key.stringValue] = val
      } else if let val = try? container.decode(Date.self, forKey: key) {
        json[key.stringValue] = val
      } else {
        let context = DecodingError
          .Context(codingPath: container.codingPath,
                   debugDescription: "AnyJSON could not decode value inside `KeyedDecodingContainer`")
        throw DecodingError.dataCorrupted(context)
      }
    }
    return json
  }

  // UnkeyedDecodingContainer
  private static func decode(from container: UnkeyedDecodingContainer) throws -> [Any] {
    var container = container
    var jsonArray = [Any]()
    while !container.isAtEnd {
      if let keyed = try? container.nestedContainer(keyedBy: AnyJSONCodingKey.self) {
        jsonArray.append(try AnyJSON.decode(from: keyed))
      } else if let unkeyed = try? container.nestedUnkeyedContainer() {
        jsonArray.append(try AnyJSON.decode(from: unkeyed))
      } else if let val = try? container.decode(String.self) {
        jsonArray.append(val)
      } else if let val = try? container.decode(Bool.self) {
        jsonArray.append(val)
      } else if let val = try? container.decode(Int.self) {
        jsonArray.append(val)
      } else if let val = try? container.decode(Double.self) {
        jsonArray.append(val)
      } else if let val = try? container.decode(Date.self) {
        jsonArray.append(val)
      } else {
        let context = DecodingError
          .Context(codingPath: container.codingPath,
                   debugDescription: "AnyJSON could not decode value inside `UnkeyedDecodingContainer`")
        throw DecodingError.dataCorrupted(context)
      }
    }
    return jsonArray
  }

  // MARK:- Encodable

  public func encode(to encoder: Encoder) throws {
    if try AnyJSON.encode(single: value, from: encoder.singleValueContainer()) {
      return
    }

    switch value {
    case let val as [String: Any]:
      try AnyJSON.encode(keyedEncoding: val, from: encoder.container(keyedBy: AnyJSONCodingKey.self))
    case let val as [Any]:
      try AnyJSON.encode(unkeyedEncoding: val, from: encoder.unkeyedContainer())
    default:
      let context = EncodingError.Context(codingPath: encoder.codingPath,
                                          debugDescription: "AnyJSON could not encoude non JSON object")
      throw EncodingError.invalidValue(value, context)
    }
  }

  // KeyedDecodingContainer
  // swiftlint:disable:next cyclomatic_complexity function_body_length
  private static func encode(keyedEncoding dictionary: [String: Any],
                             from container: KeyedEncodingContainer<AnyJSONCodingKey>) throws {
    var container = container
    for (key, value) in dictionary {
      // Turn `key` into a CodingKey
      let key = AnyJSONCodingKey(stringValue: key, intValue: nil)

      switch value {
      case let val as [String: Any]:
        try AnyJSON.encode(keyedEncoding: val,
                           from: container.nestedContainer(keyedBy: AnyJSONCodingKey.self,
                                                           forKey: key))
      case let val as [Any]:
        try AnyJSON.encode(unkeyedEncoding: val, from: container.nestedUnkeyedContainer(forKey: key))
      case let val as String:
        try container.encode(val, forKey: key)
      case let val as Int:
        try container.encode(val, forKey: key)
      case let val as Bool:
        try container.encode(val, forKey: key)
      case let val as Date:
        try container.encode(val, forKey: key)
      case let val as Data:
        try container.encode(val, forKey: key)
      case let val as Float:
        try container.encode(val, forKey: key)
      case let val as Double:
        try container.encode(val, forKey: key)
      case let val as Decimal:
        try container.encode(val, forKey: key)
      case let val as Int8:
        try container.encode(val, forKey: key)
      case let val as Int16:
        try container.encode(val, forKey: key)
      case let val as Int32:
        try container.encode(val, forKey: key)
      case let val as Int64:
        try container.encode(val, forKey: key)
      case let val as UInt8:
        try container.encode(val, forKey: key)
      case let val as UInt16:
        try container.encode(val, forKey: key)
      case let val as UInt32:
        try container.encode(val, forKey: key)
      case let val as UInt64:
        try container.encode(val, forKey: key)
      default:
        let context = EncodingError
          .Context(codingPath: container.codingPath,
                   debugDescription: "AnyJSON could not encode value inside `KeyedEncodingContainer`")
        throw EncodingError.invalidValue(value, context)
      }
    }
  }

  // UnkeyedDecodingContainer
  // swiftlint:disable:next cyclomatic_complexity function_body_length
  private static func encode(unkeyedEncoding array: [Any], from container: UnkeyedEncodingContainer) throws {
    var container = container
    for value in array {
      switch value {
      case let value as [String: Any]:
        try AnyJSON.encode(keyedEncoding: value, from: container.nestedContainer(keyedBy: AnyJSONCodingKey.self))
      case let value as [Any]:
        try AnyJSON.encode(unkeyedEncoding: value, from: container.nestedUnkeyedContainer())
      case let value as String:
        try container.encode(value)
      case let value as Int:
        try container.encode(value)
      case let value as Bool:
        try container.encode(value)
      case let value as Date:
        try container.encode(value)
      case let value as Data:
        try container.encode(value)
      case let value as Float:
        try container.encode(value)
      case let value as Double:
        try container.encode(value)
      case let value as Decimal:
        try container.encode(value)
      case let value as Int8:
        try container.encode(value)
      case let value as Int16:
        try container.encode(value)
      case let value as Int32:
        try container.encode(value)
      case let value as Int64:
        try container.encode(value)
      case let value as UInt8:
        try container.encode(value)
      case let value as UInt16:
        try container.encode(value)
      case let value as UInt32:
        try container.encode(value)
      case let value as UInt64:
        try container.encode(value)
      default:
        let context = EncodingError
          .Context(codingPath: container.codingPath,
                   debugDescription: "AnyJSON could not encode value inside `UnkeyedEncodingContainer`")
        throw EncodingError.invalidValue(value, context)
      }
    }
  }

  // SingleValueDecodingContainer
  // swiftlint:disable:next cyclomatic_complexity
  private static func encode(single value: Any, from container: SingleValueEncodingContainer) throws -> Bool {
    var container = container
    switch value {
    case let value as String:
      try container.encode(value)
    case let value as Int:
      try container.encode(value)
    case let value as Bool:
      try container.encode(value)
    case let value as Date:
      try container.encode(value)
    case let value as Data:
      try container.encode(value)
    case let value as Float:
      try container.encode(value)
    case let value as Double:
      try container.encode(value)
    case let value as Decimal:
      try container.encode(value)
    case let value as Int8:
      try container.encode(value)
    case let value as Int16:
      try container.encode(value)
    case let value as Int32:
      try container.encode(value)
    case let value as Int64:
      try container.encode(value)
    case let value as UInt8:
      try container.encode(value)
    case let value as UInt16:
      try container.encode(value)
    case let value as UInt32:
      try container.encode(value)
    case let value as UInt64:
      try container.encode(value)
    default:
      return false
    }
    return true
  }
}

// MARK: - CodingKey for AnyJSON

struct AnyJSONCodingKey: CodingKey {
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
