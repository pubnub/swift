//
//  XMLDecoder.swift
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

class XMLDecoder {
  // MARK: - Constructing a XML Decoder

  /// Initializes `self` with default strategies.
  public init() {}

  // MARK: - Decoding Values

  /// Decodes a top-level value of the given type from the given XML representation.
  open func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    let topLevel: [String: Any]
    do {
      topLevel = try XMLSerialization.parse(from: data)
    } catch {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [], debugDescription: "The given data was not valid XML.", underlyingError: error
        )
      )
    }

    let decoder = _XMLDecoder(referencing: topLevel)

    guard let value = try decoder.unbox(topLevel, as: type) else {
      throw DecodingError.valueNotFound(
        type, DecodingError.Context(
          codingPath: [], debugDescription: "The given data did not contain a top-level value."
        )
      )
    }

    return value
  }
}

class _XMLDecoder: Decoder {
  var codingPath: [CodingKey]
  var userInfo: [CodingUserInfoKey: Any] = [:]
  /// The decoder's storage.
  internal var storage: XMLDecodingContainer

  init(referencing container: Any, at codingPath: [CodingKey] = []) {
    storage = XMLDecodingContainer()
    storage.push(container)
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

    let container = _XMLKeyedDecodingContainer<Key>(referencing: self, wrapping: topContainer)
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

    return _XMLUnkeyedDecodingContainer(referencing: self, wrapping: topContainer)
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    return self
  }
}

// MARK: Keyed Value Container

private struct _XMLKeyedDecodingContainer<Key: CodingKey> {
  /// A reference to the decoder we're reading from.
  private let decoder: _XMLDecoder

  /// A reference to the container we're reading from.
  private let container: [String: Any]

  // This documentation comment was inherited from `KeyedDecodingContainerProtocol`
  public private(set) var codingPath: [CodingKey]

  /// Initializes `self` by referencing the given decoder and container.
  fileprivate init(referencing decoder: _XMLDecoder, wrapping container: [String: Any]) {
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
    return _XMLDecoder(referencing: value, at: decoder.codingPath)
  }
}

extension _XMLKeyedDecodingContainer: KeyedDecodingContainerProtocol {
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

    guard let value = container[key.stringValue] else {
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

    let container = _XMLKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: dictionary)
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

    return _XMLUnkeyedDecodingContainer(referencing: decoder, wrapping: array)
  }

  func superDecoder() throws -> Decoder {
    return try _superDecoder(forKey: XMLCodingKey.super)
  }

  func superDecoder(forKey key: Key) throws -> Decoder {
    return try _superDecoder(forKey: key)
  }
}

// MARK: Unkeyed Value Container

private struct _XMLUnkeyedDecodingContainer {
  /// A reference to the decoder we're reading from.
  private let decoder: _XMLDecoder

  /// A reference to the container we're reading from.
  private let container: [Any]

  // This documentation comment was inherited from `UnkeyedDecodingContainer`.
  public private(set) var codingPath: [CodingKey]

  // This documentation comment was inherited from `UnkeyedDecodingContainer`.
  public private(set) var currentIndex: Int

  // MARK: - Initialization

  /// Initializes `self` by referencing the given decoder and container.
  fileprivate init(referencing decoder: _XMLDecoder, wrapping container: [Any]) {
    self.decoder = decoder
    self.container = container
    codingPath = decoder.codingPath
    currentIndex = 0
  }
}

extension _XMLUnkeyedDecodingContainer: UnkeyedDecodingContainer {
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Bool.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: String.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Double.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Float.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func decode(_ type: Int.Type) throws -> Int {
    guard !isAtEnd else {
      throw DecodingError.valueNotFound(
        type, DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                                    debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int8.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int16.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int32.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: Int64.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt8.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt16.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt32.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: UInt64.self) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
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
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Unkeyed container is at end.")
      )
    }

    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
    defer { self.decoder.codingPath.removeLast() }

    guard let decoded = try decoder.unbox(container[currentIndex], as: type) else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: decoder.codingPath + [XMLCodingKey(index: currentIndex)],
                              debugDescription: "Expected \(type) but found null instead.")
      )
    }

    currentIndex += 1
    return decoded
  }

  mutating func nestedContainer<NestedKey>(
    keyedBy _: NestedKey.Type
  ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
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
    let container = _XMLKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: dictionary)
    return KeyedDecodingContainer(container)
  }

  mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
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
    return _XMLUnkeyedDecodingContainer(referencing: decoder, wrapping: array)
  }

  mutating func superDecoder() throws -> Decoder {
    decoder.codingPath.append(XMLCodingKey(index: currentIndex))
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
    return _XMLDecoder(referencing: value, at: decoder.codingPath)
  }
}

// MARK: Single Value Container

extension _XMLDecoder: SingleValueDecodingContainer {
  func expectNonNull<T>(_ type: T.Type) throws -> Any {
    guard !decodeNil(), let value = storage.topContainer else {
      throw DecodingError.valueNotFound(
        type,
        DecodingError.Context(codingPath: codingPath,
                              debugDescription: "Expected \(type) but found null value instead.")
      )
    }
    return value
  }

  func decodeNil() -> Bool {
    return storage.topContainer == nil || storage.topContainer is NSNull
  }

  func decode(_ type: Bool.Type) throws -> Bool {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: String.Type) throws -> String {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Double.Type) throws -> Double {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Float.Type) throws -> Float {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int.Type) throws -> Int {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int8.Type) throws -> Int8 {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int16.Type) throws -> Int16 {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int32.Type) throws -> Int32 {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: Int64.Type) throws -> Int64 {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt.Type) throws -> UInt {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt8.Type) throws -> UInt8 {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt16.Type) throws -> UInt16 {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt32.Type) throws -> UInt32 {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode(_ type: UInt64.Type) throws -> UInt64 {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }

  func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    guard let value = try unbox(expectNonNull(type), as: type) else {
      throw DecodingError._typeMismatch(at: [], expectation: type, reality: storage.topContainer)
    }
    return value
  }
}

// MARK: Concrete Value Unboxing

extension _XMLDecoder {
  /// Returns the erased value as a `Boolean` if it matches that type
  func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
    guard let bool = value as? Bool else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    return bool
  }

  /// Returns the erased value as a `Int` if it matches that type
  func unbox(_ value: Any, as type: Int.Type) throws -> Int? {
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

  /// Returns the erased value as a `UInt` if it matches that type
  func unbox(_ value: Any, as type: UInt.Type) throws -> UInt? {
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

  /// Returns the erased value as a `Double` if it matches that type
  func unbox(_ value: Any, as type: Double.Type) throws -> Double? {
    if let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse {
      return number.doubleValue
    }

    throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
  }

  /// Returns the erased value as a `String` if it matches that type
  func unbox(_ value: Any, as type: String.Type) throws -> String? {
    guard let string = value as? String else {
      throw DecodingError._typeMismatch(at: codingPath, expectation: type, reality: value)
    }

    return string
  }

  /// Returns the `Decodable` value as a `T` if it matches that type
  func unbox<T: Decodable>(_ value: Any, as type: T.Type) throws -> T? {
    storage.push(value)
    defer { self.storage.popContainer() }
    // Use the types default decoable init
    return try type.init(from: self)
  }
}

// MARK: - Storage

internal struct XMLDecodingContainer {
  /// The container stack.
  /// Elements may be any one of the XML types (String, [String : Any]).
  var containers: [Any] = []

  /// Initializes `self` with no containers.
  init() {}

  var count: Int {
    return containers.count
  }

  var topContainer: Any? {
    return self.containers.last
  }

  mutating func push(_ value: Any) {
    // Ensure that we properly encode nil as an object
    containers.append(value)
  }

  @discardableResult
  mutating func popContainer() -> Any? {
    guard !containers.isEmpty else {
      return nil
    }
    return containers.removeLast()
  }
}

// MARK: - CodingKey

struct XMLCodingKey: CodingKey {
  var stringValue: String
  var intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    intValue = nil
  }

  init?(intValue: Int) {
    stringValue = "\(intValue)"
    self.intValue = intValue
  }

  init(stringValue: String, intValue: Int?) {
    self.stringValue = stringValue
    self.intValue = intValue
  }

  init(index: Int) {
    stringValue = "Index \(index)"
    intValue = index
  }

  static let `super` = XMLCodingKey(stringValue: "super", intValue: nil)
  // swiftlint:disable:next file_length
}
