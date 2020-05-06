//
//  CBORDecoder.swift
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

internal class CBORDecoder {
  init() {}

  internal func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    let topLevel: Any
    do {
      topLevel = try CBORSerialization.cborObject(from: data)
    } catch {
      // throw Decoding Error
      throw DecodingError
        .dataCorrupted(DecodingError.Context(codingPath: [],
                                             debugDescription: "The provided data was not valid CBOR.",
                                             underlyingError: error))
    }

    let decoder = _CBORDecoder(referencing: topLevel)
    guard let value = try decoder.unbox(topLevel, as: type) else {
      throw DecodingError
        .valueNotFound(type,
                       DecodingError.Context(codingPath: [],
                                             debugDescription: "The given data did not contain a top-level value."))
    }

    return value
  }
}

// MARK: - Decoder Protocol

private class _CBORDecoder: Decoder {
  var storage: CBORDecodingStorage
  var codingPath: [CodingKey]
  var userInfo: [CodingUserInfoKey: Any] = [:]

  init(referencing container: Any, at codingPath: [CodingKey] = []) {
    storage = CBORDecodingStorage()
    storage.push(container: container)
    self.codingPath = codingPath
  }

  func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
    guard !(storage.topContainer is NSNull) else {
      throw DecodingError.valueNotFound(
        KeyedDecodingContainer<Key>.self,
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Cannot get keyed decoding container -- found null value instead.")
      )
    }

    guard let topContainer = storage.topContainer as? [String: Any] else {
      throw DecodingError._typeMismatch(at: codingPath,
                                        expectation: [String: Any].self,
                                        reality: storage.topContainer)
    }

    let container = _CBORKeyedDecodingContainer<Key>(referencing: self, wrapping: topContainer)
    return KeyedDecodingContainer(container)
  }

  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    guard !(storage.topContainer is NSNull) else {
      throw DecodingError.valueNotFound(
        UnkeyedDecodingContainer.self,
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Cannot get unkeyed decoding container -- found null value instead.")
      )
    }

    guard let topContainer = storage.topContainer as? [Any] else {
      throw DecodingError._typeMismatch(at: codingPath,
                                        expectation: [Any].self,
                                        reality: storage.topContainer)
    }

    return _CBORUnkeyedDecodingContainer(referencing: self, wrapping: topContainer)
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    return self
  }
}

// MARK: - Concrete Value Representations

extension _CBORDecoder {
  /// Returns the given value unboxed from a container.
  fileprivate func unbox(_ value: Any?, as type: Bool.Type) throws -> Bool? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let bool = value as? Bool else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    return bool
  }

  fileprivate func unbox(_ value: Any?, as type: Int.Type) throws -> Int? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let int = number.intValue
    guard NSNumber(value: int) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return int
  }

  fileprivate func unbox(_ value: Any?, as type: Int8.Type) throws -> Int8? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let int8 = number.int8Value
    guard NSNumber(value: int8) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return int8
  }

  fileprivate func unbox(_ value: Any?, as type: Int16.Type) throws -> Int16? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let int16 = number.int16Value
    guard NSNumber(value: int16) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return int16
  }

  fileprivate func unbox(_ value: Any?, as type: Int32.Type) throws -> Int32? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let int32 = number.int32Value
    guard NSNumber(value: int32) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return int32
  }

  fileprivate func unbox(_ value: Any?, as type: Int64.Type) throws -> Int64? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let int64 = number.int64Value
    guard NSNumber(value: int64) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return int64
  }

  fileprivate func unbox(_ value: Any?, as type: UInt.Type) throws -> UInt? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let uint = number.uintValue
    guard NSNumber(value: uint) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return uint
  }

  fileprivate func unbox(_ value: Any?, as type: UInt8.Type) throws -> UInt8? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let uint8 = number.uint8Value
    guard NSNumber(value: uint8) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return uint8
  }

  fileprivate func unbox(_ value: Any?, as type: UInt16.Type) throws -> UInt16? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let uint16 = number.uint16Value
    guard NSNumber(value: uint16) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return uint16
  }

  fileprivate func unbox(_ value: Any?, as type: UInt32.Type) throws -> UInt32? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let uint32 = number.uint32Value
    guard NSNumber(value: uint32) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return uint32
  }

  fileprivate func unbox(_ value: Any?, as type: UInt64.Type) throws -> UInt64? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    let uint64 = number.uint64Value
    guard NSNumber(value: uint64) == number else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Parsed CBOR number <\(number)> does not fit in \(type)."))
    }

    return uint64
  }

  fileprivate func unbox(_ value: Any?, as type: Float.Type) throws -> Float? {
    guard value != nil, !(value is NSNull) else { return nil }

    if let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse {
      let double = number.doubleValue
      guard abs(double) <= Double(Float.greatestFiniteMagnitude) else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(codingPath: codingPath,
                                debugDescription: "Parsed CBOR number \(number) does not fit in \(type)."))
      }

      return Float(double)
    }

    throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
  }

  fileprivate func unbox(_ value: Any?, as type: Double.Type) throws -> Double? {
    guard value != nil, !(value is NSNull) else { return nil }

    if let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse {
      return number.doubleValue
    }

    throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
  }

  fileprivate func unbox(_ value: Any?, as type: String.Type) throws -> String? {
    guard value != nil, !(value is NSNull) else { return nil }

    guard let string = value as? String else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    return string
  }

  fileprivate func unbox(_ value: Any?, as _: Data.Type) throws -> Data? {
    guard value != nil, !(value is NSNull) else { return nil }

    storage.push(container: value)
    defer { self.storage.popContainer() }
    return try Data(from: self)
  }

  fileprivate func unbox<T: Decodable>(_ value: Any?, as type: T.Type) throws -> T? {
    return try unbox_(value, as: type) as? T
  }

  fileprivate func unbox_(_ value: Any?, as type: Decodable.Type) throws -> Any? {
    // There is no protocol container for Data objects, so unbox here
    if type == Data.self {
      guard let data = try unbox(value, as: Data.self) else { return nil }
      return data
    } else {
      storage.push(container: value)
      defer { self.storage.popContainer() }
      // Use the types default decoable init
      return try type.init(from: self)
    }
  }
}

// MARK: - KeyedDecodingContainerProtocol

private struct _CBORKeyedDecodingContainer<Key: CodingKey> {
  /// A reference to the decoder we're reading from.
  private let decoder: _CBORDecoder

  /// A reference to the container we're reading from.
  private let container: [String: Any]

  /// The path of coding keys taken to get to this point in decoding.
  public private(set) var codingPath: [CodingKey]

  /// Initializes `self` by referencing the given decoder and container.
  fileprivate init(referencing decoder: _CBORDecoder, wrapping container: [String: Any]) {
    self.decoder = decoder
    self.container = container
    codingPath = decoder.codingPath
  }

  private func _errorDescription(of key: CodingKey) -> String {
    return "\(key) (\"\(key.stringValue)\")"
  }

  private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    let value: Any = container[key.stringValue] ?? NSNull()
    return _CBORDecoder(referencing: value, at: decoder.codingPath)
  }
}

extension _CBORKeyedDecodingContainer: KeyedDecodingContainerProtocol {
  var allKeys: [Key] {
    return container.keys.compactMap { Key(stringValue: $0) }
  }

  func contains(_ key: Key) -> Bool {
    return container[key.stringValue] != nil
  }

  func decodeNil(forKey key: Key) throws -> Bool {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    return entry is NSNull
  }

  func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: Bool.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: String.Type, forKey key: Key) throws -> String {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: String.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: Double.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: Float.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: Int.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: Int8.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: Int16.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: Int32.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: Int64.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: UInt.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: UInt8.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: UInt16.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: UInt32.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: UInt64.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
    guard let entry = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "No value associated with key \(_errorDescription(of: key)).")
      )
    }

    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = try decoder.unbox(entry, as: type) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath,
                              debugDescription: "Expected \(type) value but found null instead.")
      )
    }

    return value
  }

  func nestedContainer<NestedKey>(
    keyedBy _: NestedKey.Type,
    forKey key: Key
  ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = self.container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(
          codingPath: codingPath,
          debugDescription:
          "Cannot get \(KeyedDecodingContainer<NestedKey>.self); no value found for key \(_errorDescription(of: key))"
        )
      )
    }

    guard let dictionary = value as? [String: Any] else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: [String: Any].self, reality: value)
    }

    let container = _CBORKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: dictionary)
    return KeyedDecodingContainer(container)
  }

  func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
    decoder.codingPath.append(key)
    defer { self.decoder.codingPath.removeLast() }

    guard let value = container[key.stringValue] else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(
          codingPath: codingPath,
          debugDescription: "Cannot get UnkeyedDecodingContainer; no value found for key \(_errorDescription(of: key))"
        )
      )
    }

    guard let array = value as? [Any] else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: [Any].self, reality: value)
    }

    return _CBORUnkeyedDecodingContainer(referencing: decoder, wrapping: array)
  }

  func superDecoder() throws -> Decoder {
    return try _superDecoder(forKey: CBORKey.super)
  }

  func superDecoder(forKey key: Key) throws -> Decoder {
    return try _superDecoder(forKey: key)
  }
}

// MARK: - Unkeyed Containerdddddddd

private struct _CBORUnkeyedDecodingContainer {
  /// A reference to the decoder we're reading from.
  private let decoder: _CBORDecoder

  /// A reference to the container we're reading from.
  private let container: [Any]

  /// The path of coding keys taken to get to this point in decoding.
  public private(set) var codingPath: [CodingKey]

  /// The index of the element we're about to decode.
  public private(set) var currentIndex: Int

  // MARK: - Initialization

  /// Initializes `self` by referencing the given decoder and container.
  fileprivate init(referencing decoder: _CBORDecoder, wrapping container: [Any]) {
    self.decoder = decoder
    self.container = container
    codingPath = decoder.codingPath
    currentIndex = 0
  }
}

extension _CBORUnkeyedDecodingContainer: UnkeyedDecodingContainer {
  var count: Int? {
    return container.count
  }

  var isAtEnd: Bool {
    return self.currentIndex >= (self.count ?? -1)
  }

  mutating func decodeNil() throws -> Bool {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        Any?.self,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    if container[currentIndex] is NSNull {
      currentIndex += 1
      return true
    } else {
      return false
    }
  }

  mutating func decode(_ type: Bool.Type) throws -> Bool {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Bool.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: String.Type) throws -> String {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: String.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: Double.Type) throws -> Double {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Double.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: Float.Type) throws -> Float {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Float.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: Int.Type) throws -> Int {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type, DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                                    debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: Int8.Type) throws -> Int8 {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int8.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: Int16.Type) throws -> Int16 {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int16.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: Int32.Type) throws -> Int32 {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int32.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: Int64.Type) throws -> Int64 {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int64.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: UInt.Type) throws -> UInt {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt8.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt16.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt32.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt64.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: type) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [CBORKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func nestedContainer<NestedKey>(
    keyedBy _: NestedKey.Type
  ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        KeyedDecodingContainer<NestedKey>.self,
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Cannot get nested keyed container -- unkeyed container is at end.")
      )
    }

    let value = self.container[currentIndex]
    guard !(value is NSNull) else {
      throw DecodingError.valueNotFound(
        KeyedDecodingContainer<NestedKey>.self,
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Cannot get keyed decoding container -- found null value instead.")
      )
    }

    guard let dictionary = value as? [String: Any] else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: [String: Any].self, reality: value)
    }

    currentIndex += 1
    let container = _CBORKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: dictionary)
    return KeyedDecodingContainer(container)
  }

  mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        UnkeyedDecodingContainer.self,
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Cannot get nested keyed container -- unkeyed container is at end.")
      )
    }

    let value = container[currentIndex]
    guard !(value is NSNull) else {
      throw DecodingError.valueNotFound(
        UnkeyedDecodingContainer.self,
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Cannot get keyed decoding container -- found null value instead.")
      )
    }

    guard let array = value as? [Any] else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: [Any].self, reality: value)
    }

    currentIndex += 1
    return _CBORUnkeyedDecodingContainer(referencing: decoder, wrapping: array)
  }

  mutating func superDecoder() throws -> Decoder {
    decoder.codingPath.append(CBORKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        Decoder.self,
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Cannot get superDecoder() -- unkeyed container is at end.")
      )
    }

    let value = container[currentIndex]
    currentIndex += 1
    return _CBORDecoder(referencing: value, at: decoder.codingPath)
  }
}

// MARK: - SingleValueDecodingContainer

extension _CBORDecoder: SingleValueDecodingContainer {
  private func expectNonNull<T>(_ type: T.Type) throws {
    guard !decodeNil() else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Expected \(type) but found null value instead.")
      )
    }
  }

  func decodeNil() -> Bool {
    return storage.topContainer is NSNull
  }

  func decode(_ type: Bool.Type) throws -> Bool {
    try expectNonNull(Bool.self)
    guard let value = try unbox(storage.topContainer, as: Bool.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: String.Type) throws -> String {
    try expectNonNull(String.self)
    guard let value = try unbox(storage.topContainer, as: String.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Double.Type) throws -> Double {
    try expectNonNull(Double.self)
    guard let value = try unbox(storage.topContainer, as: Double.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Float.Type) throws -> Float {
    try expectNonNull(Float.self)
    guard let value = try unbox(storage.topContainer, as: Float.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int.Type) throws -> Int {
    try expectNonNull(Int.self)
    guard let value = try unbox(storage.topContainer, as: Int.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int8.Type) throws -> Int8 {
    try expectNonNull(Int8.self)
    guard let value = try unbox(storage.topContainer, as: Int8.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int16.Type) throws -> Int16 {
    try expectNonNull(Int16.self)
    guard let value = try unbox(storage.topContainer, as: Int16.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int32.Type) throws -> Int32 {
    try expectNonNull(Int32.self)
    guard let value = try unbox(storage.topContainer, as: Int32.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int64.Type) throws -> Int64 {
    try expectNonNull(Int64.self)
    guard let value = try unbox(storage.topContainer, as: Int64.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt.Type) throws -> UInt {
    try expectNonNull(UInt.self)
    guard let value = try unbox(storage.topContainer, as: UInt.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt8.Type) throws -> UInt8 {
    try expectNonNull(UInt8.self)
    guard let value = try unbox(storage.topContainer, as: UInt8.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt16.Type) throws -> UInt16 {
    try expectNonNull(UInt16.self)
    guard let value = try unbox(storage.topContainer, as: UInt16.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt32.Type) throws -> UInt32 {
    try expectNonNull(UInt32.self)
    guard let value = try unbox(storage.topContainer, as: UInt32.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt64.Type) throws -> UInt64 {
    try expectNonNull(UInt64.self)
    guard let value = try unbox(storage.topContainer, as: UInt64.self) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    try expectNonNull(type)
    guard let value = try unbox(storage.topContainer, as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }
}

// MARK: - Decoding Storage

internal struct CBORDecodingStorage {
  /// The container stack.
  /// Elements may be any one of the CBOR types (NSNull, NSNumber, String, Array, [String : Any]).
  var containers: [Any] = []

  /// Initializes `self` with no containers.
  init() {}

  var count: Int {
    return containers.count
  }

  var topContainer: Any? {
    return self.containers.last
  }

  mutating func push(container value: Any?) {
    // Ensure that we properly encode nil as an object
    if value == nil {
      containers.append(NSNull())
    } else {
      containers.append(value as Any)
    }
  }

  mutating func popContainer() {
    precondition(!containers.isEmpty, "Empty container stack.")
    containers.removeLast()
  }
}

// MARK: - CBOR Key Type

private struct CBORKey: CodingKey {
  public var stringValue: String
  public var intValue: Int?

  public init?(stringValue: String) {
    self.stringValue = stringValue
    intValue = nil
  }

  public init?(intValue: Int) {
    stringValue = "\(intValue)"
    self.intValue = intValue
  }

  public init(stringValue: String, intValue: Int?) {
    self.stringValue = stringValue
    self.intValue = intValue
  }

  fileprivate init(index: Int) {
    stringValue = "Index \(index)"
    intValue = index
  }

  fileprivate static let `super` = CBORKey(stringValue: "super", intValue: nil)
  // swiftlint:disable:next file_length
}
