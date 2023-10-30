//
//  XMLEncoder.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@testable import PubNub

/// `XMLEncoder` facilitates the encoding of `Encodable` values into XML.
class XMLEncoder {
  /// Contextual user-provided information for use during encoding.
  var userInfo: [CodingUserInfoKey: Any] = [:]

  // MARK: Constructing a XML Encoder

  /// Initializes `self` with default strategies.
  init() {}

  // MARK: - Encoding Values

  func encode<T: Encodable>(_ value: T, withRootKey rootKey: String) throws -> Data {
    let encoder = _XMLEncoder()

    guard let topLevel = try encoder.box_(value) as? [String: Any] else {
      throw EncodingError.invalidValue(
        value,
        EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values.")
      )
    }

    guard let xmlData = XMLSerialization.toXMLString(root: rootKey, from: topLevel).data(using: .utf8) else {
      throw EncodingError.invalidValue(
        value, EncodingError.Context(
          codingPath: [], debugDescription: "Unable to encode the given top-level value to XML."
        )
      )
    }

    return xmlData
  }
}

class _XMLEncoder: Encoder {
  /// The encoder's storage.
  var storage: _XMLEncodingStorage

  // This documentation comment was inherited from Encoder.
  var codingPath: [CodingKey]

  // This documentation comment was inherited from Encoder.
  var userInfo: [CodingUserInfoKey: Any] {
    return [:]
  }

  // MARK: - Initialization

  /// Initializes `self` with the given top-level encoder options.
  init(codingPath: [CodingKey] = []) {
    storage = _XMLEncodingStorage()
    self.codingPath = codingPath
  }

  /// Returns whether a new element can be encoded at this coding path.
  ///
  /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
  var canEncodeNewValue: Bool {
    // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
    // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
    // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
    //
    // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
    // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
    return storage.count == codingPath.count
  }

  // MARK: - Encoder Methods

  func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
    // If an existing keyed container was already requested, return that one.
    let topContainer: NSMutableDictionary
    if canEncodeNewValue {
      // We haven't yet pushed a container at this level; do so here.
      topContainer = storage.pushKeyedContainer()
    } else {
      guard let container = storage.containers.last as? NSMutableDictionary else {
        preconditionFailure(
          "Attempt to push new keyed encoding container when already previously encoded at this path."
        )
      }

      topContainer = container
    }

    let container = XMLCodingKeyedEncodingContainer<Key>(
      referencing: self, codingPath: codingPath, wrapping: topContainer
    )
    return KeyedEncodingContainer(container)
  }

  func unkeyedContainer() -> UnkeyedEncodingContainer {
    // If an existing unkeyed container was already requested, return that one.
    let topContainer: NSMutableArray
    if canEncodeNewValue {
      // We haven't yet pushed a container at this level; do so here.
      topContainer = storage.pushUnkeyedContainer()
    } else {
      guard let container = storage.containers.last as? NSMutableArray else {
        preconditionFailure(
          "Attempt to push new unkeyed encoding container when already previously encoded at this path."
        )
      }

      topContainer = container
    }

    return _XMLUnkeyedEncodingContainer(referencing: self, codingPath: codingPath, wrapping: topContainer)
  }

  func singleValueContainer() -> SingleValueEncodingContainer {
    return self
  }
}

// MARK: - Encoding Containers

private struct XMLCodingKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
  typealias Key = K

  // MARK: Properties

  /// A reference to the encoder we're writing to.
  private let encoder: _XMLEncoder

  /// A reference to the container we're writing to.
  private let container: NSMutableDictionary

  /// The path of coding keys taken to get to this point in encoding.
  private(set) var codingPath: [CodingKey]

  // MARK: - Initialization

  /// Initializes `self` with the given references.
  fileprivate init(referencing encoder: _XMLEncoder, codingPath: [CodingKey], wrapping container: NSMutableDictionary) {
    self.encoder = encoder
    self.codingPath = codingPath
    self.container = container
  }

  // MARK: - KeyedEncodingContainerProtocol Methods

  mutating func encodeNil(forKey key: Key) throws {
    container[key.stringValue] = NSNull()
  }

  mutating func encode(_ value: Bool, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: Int, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: Int8, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: Int16, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: Int32, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: Int64, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: UInt, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: UInt8, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: UInt16, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: UInt32, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: UInt64, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: String, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = encoder.box(value)
  }

  mutating func encode(_ value: Float, forKey key: Key) throws {
    // Since the float may be invalid and throw, the coding path needs to contain this key.
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = try encoder.box(value)
  }

  mutating func encode(_ value: Double, forKey key: Key) throws {
    // Since the double may be invalid and throw, the coding path needs to contain this key.
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = try encoder.box(value)
  }

  mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
    encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    container[key.stringValue] = try encoder.box(value)
  }

  mutating func nestedContainer<NestedKey>(
    keyedBy _: NestedKey.Type, forKey key: Key
  ) -> KeyedEncodingContainer<NestedKey> {
    let dictionary = NSMutableDictionary()
    self.container[key.stringValue] = dictionary

    codingPath.append(key)
    defer { self.codingPath.removeLast() }

    let container = XMLCodingKeyedEncodingContainer<NestedKey>(
      referencing: encoder, codingPath: codingPath, wrapping: dictionary
    )
    return KeyedEncodingContainer(container)
  }

  mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
    let array = NSMutableArray()
    container[key.stringValue] = array

    codingPath.append(key)
    defer { self.codingPath.removeLast() }
    return _XMLUnkeyedEncodingContainer(referencing: encoder, codingPath: codingPath, wrapping: array)
  }

  mutating func superEncoder() -> Encoder {
    return _XMLReferencingEncoder(
      referencing: encoder, key: XMLCodingKey.super, convertedKey: XMLCodingKey.super, wrapping: container
    )
  }

  mutating func superEncoder(forKey key: Key) -> Encoder {
    return _XMLReferencingEncoder(referencing: encoder, key: key, convertedKey: key, wrapping: container)
  }
}

private struct _XMLUnkeyedEncodingContainer: UnkeyedEncodingContainer {
  // MARK: Properties

  /// A reference to the encoder we're writing to.
  private let encoder: _XMLEncoder

  /// A reference to the container we're writing to.
  private let container: NSMutableArray

  /// The path of coding keys taken to get to this point in encoding.
  private(set) var codingPath: [CodingKey]

  /// The number of elements encoded into the container.
  var count: Int {
    return container.count
  }

  // MARK: - Initialization

  /// Initializes `self` with the given references.
  fileprivate init(referencing encoder: _XMLEncoder, codingPath: [CodingKey], wrapping container: NSMutableArray) {
    self.encoder = encoder
    self.codingPath = codingPath
    self.container = container
  }

  // MARK: - UnkeyedEncodingContainer Methods

  mutating func encodeNil() throws { container.add(NSNull()) }
  mutating func encode(_ value: Bool) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: Int) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: Int8) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: Int16) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: Int32) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: Int64) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: UInt) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: UInt8) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: UInt16) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: UInt32) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: UInt64) throws { container.add(encoder.box(value)) }
  mutating func encode(_ value: String) throws { container.add(encoder.box(value)) }

  mutating func encode(_ value: Float) throws {
    // Since the float may be invalid and throw, the coding path needs to contain this key.
    encoder.codingPath.append(XMLCodingKey(index: count))
    defer { self.encoder.codingPath.removeLast() }
    container.add(try encoder.box(value))
  }

  mutating func encode(_ value: Double) throws {
    // Since the double may be invalid and throw, the coding path needs to contain this key.
    encoder.codingPath.append(XMLCodingKey(index: count))
    defer { self.encoder.codingPath.removeLast() }
    container.add(try encoder.box(value))
  }

  mutating func encode<T: Encodable>(_ value: T) throws {
    encoder.codingPath.append(XMLCodingKey(index: count))
    defer { self.encoder.codingPath.removeLast() }
    container.add(try encoder.box(value))
  }

  mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
    codingPath.append(XMLCodingKey(index: count))
    defer { self.codingPath.removeLast() }

    let dictionary = NSMutableDictionary()
    self.container.add(dictionary)

    let container = XMLCodingKeyedEncodingContainer<NestedKey>(
      referencing: encoder, codingPath: codingPath, wrapping: dictionary
    )
    return KeyedEncodingContainer(container)
  }

  mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
    codingPath.append(XMLCodingKey(index: count))
    defer { self.codingPath.removeLast() }

    let array = NSMutableArray()
    container.add(array)
    return _XMLUnkeyedEncodingContainer(referencing: encoder, codingPath: codingPath, wrapping: array)
  }

  mutating func superEncoder() -> Encoder {
    return _XMLReferencingEncoder(referencing: encoder, at: container.count, wrapping: container)
  }
}

extension _XMLEncoder: SingleValueEncodingContainer {
  // MARK: - SingleValueEncodingContainer Methods

  fileprivate func assertCanEncodeNewValue() {
    precondition(
      canEncodeNewValue,
      "Attempt to encode value through single value container when previously value already encoded."
    )
  }

  func encodeNil() throws {
    assertCanEncodeNewValue()
    storage.push(container: NSNull())
  }

  func encode(_ value: Bool) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: Int) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: Int8) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: Int16) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: Int32) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: Int64) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: UInt) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: UInt8) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: UInt16) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: UInt32) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: UInt64) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: String) throws {
    assertCanEncodeNewValue()
    storage.push(container: box(value))
  }

  func encode(_ value: Float) throws {
    assertCanEncodeNewValue()
    try storage.push(container: box(value))
  }

  func encode(_ value: Double) throws {
    assertCanEncodeNewValue()
    try storage.push(container: box(value))
  }

  func encode<T: Encodable>(_ value: T) throws {
    assertCanEncodeNewValue()
    try storage.push(container: box(value))
  }
}

extension _XMLEncoder {
  /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
  fileprivate func box(_ value: Bool) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int8) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int16) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int32) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int64) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt8) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt16) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt32) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt64) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: String) -> NSObject { return NSString(string: value) }

  func box(_ value: Float) throws -> NSObject {
    return NSNumber(value: value)
  }

  func box(_ value: Double) throws -> NSObject {
    return NSNumber(value: value)
  }

  func box(_ value: Date) throws -> NSObject {
    try value.encode(to: self)
    return storage.popContainer()
  }

  func box(_ value: Data) throws -> NSObject {
    try value.encode(to: self)
    return storage.popContainer()
  }

  fileprivate func box<T: Encodable>(_ value: T) throws -> NSObject {
    return try box_(value) ?? NSDictionary()
  }

  // This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
  fileprivate func box_<T: Encodable>(_ value: T) throws -> NSObject? {
    if T.self == Date.self || T.self == NSDate.self, let dateValue = value as? Date {
      return try box(dateValue)
    } else if T.self == Data.self || T.self == NSData.self, let dataValue = value as? Data {
      return try box(dataValue)
    } else if T.self == URL.self || T.self == NSURL.self, let urlValue = value as? URL {
      return box(urlValue.absoluteString)
    } else if T.self == Decimal.self || T.self == NSDecimalNumber.self, let numberValue = value as? NSDecimalNumber {
      return numberValue
    }

    let depth = storage.count
    try value.encode(to: self)

    // The top container should be a new container.
    guard storage.count > depth else {
      return nil
    }

    return storage.popContainer()
  }
}

// MARK: - Reference Container

/// _XMLReferencingEncoder is a special subclass of _XMLEncoder which has its own storage, but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
class _XMLReferencingEncoder: _XMLEncoder {
  // MARK: Reference types.

  /// The type of container we're referencing.
  private enum Reference {
    /// Referencing a specific index in an array container.
    case array(NSMutableArray, Int)

    /// Referencing a specific key in a dictionary container.
    case dictionary(NSMutableDictionary, String)
  }

  // MARK: - Properties

  /// The encoder we're referencing.
  let encoder: _XMLEncoder

  /// The container reference itself.
  private let reference: Reference

  // MARK: - Initialization

  /// Initializes `self` by referencing the given array container in the given encoder.
  init(referencing encoder: _XMLEncoder, at index: Int, wrapping array: NSMutableArray) {
    self.encoder = encoder
    reference = .array(array, index)
    super.init(codingPath: encoder.codingPath)

    codingPath.append(XMLCodingKey(index: index))
  }

  /// Initializes `self` by referencing the given dictionary container in the given encoder.
  init(
    referencing encoder: _XMLEncoder,
    key: CodingKey,
    convertedKey: CodingKey,
    wrapping dictionary: NSMutableDictionary
  ) {
    self.encoder = encoder
    reference = .dictionary(dictionary, convertedKey.stringValue)
    super.init(codingPath: encoder.codingPath)

    codingPath.append(key)
  }

  // MARK: - Coding Path Operations

  override var canEncodeNewValue: Bool {
    // With a regular encoder, the storage and coding path grow together.
    // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
    // We have to take this into account.
    return storage.count == codingPath.count - encoder.codingPath.count - 1
  }

  // MARK: - Deinitialization

  // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
  deinit {
    let value: Any
    switch self.storage.count {
    case 0: value = NSDictionary()
    case 1: value = self.storage.popContainer()
    default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
    }

    switch self.reference {
    case let .array(array, index):
      array.insert(value, at: index)

    case let .dictionary(dictionary, key):
      dictionary[NSString(string: key)] = value
    }
  }
}

// MARK: - Encoding Storage

struct _XMLEncodingStorage {
  // MARK: Properties

  /// The container stack.
  /// Elements may be any one of the XML types (NSNull, NSNumber, NSString, NSArray, NSDictionary).
  private(set) var containers: [NSObject] = []

  // MARK: - Initialization

  /// Initializes `self` with no containers.
  init() {}

  // MARK: - Modifying the Stack

  var count: Int {
    return containers.count
  }

  mutating func pushKeyedContainer() -> NSMutableDictionary {
    let dictionary = NSMutableDictionary()
    containers.append(dictionary)
    return dictionary
  }

  mutating func pushUnkeyedContainer() -> NSMutableArray {
    let array = NSMutableArray()
    containers.append(array)
    return array
  }

  mutating func push(container: NSObject) {
    containers.append(container)
  }

  mutating func popContainer() -> NSObject {
    precondition(!containers.isEmpty, "Empty container stack.")
    return containers.popLast() ?? NSNull()
  }

  // swiftlint:disable:next file_length
}
