//
//  XMLEncoder.swift
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

/// `XMLEncoder` facilitates the encoding of `Encodable` values into XML.
class XMLEncoder {

  /// Contextual user-provided information for use during encoding.
  var userInfo: [CodingUserInfoKey : Any] = [:]

  
  // MARK: Constructing a XML Encoder
  /// Initializes `self` with default strategies.
  public init() {}
  
  // MARK: - Encoding Values

  func encode<T : Encodable>(_ value: T, withRootKey rootKey: String) throws -> Data {
    let encoder = _XMLEncoder()
    
    guard let topLevel = try encoder.box_(value) as? Dictionary<String, Any> else {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
    }

    guard let xmlData = XMLSerialization.toXMLString(root: rootKey, from: topLevel).data(using: .utf8) else {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unable to encode the given top-level value to XML."))
    }
    
    return xmlData
  }
}

internal class _XMLEncoder: Encoder {
  
  /// The encoder's storage.
  internal var storage: _XMLEncodingStorage
  
  // This documentation comment was inherited from Encoder.
  public var codingPath: [CodingKey]
  
  // This documentation comment was inherited from Encoder.
  public var userInfo: [CodingUserInfoKey : Any] {
    return [:]
  }
  
  // MARK: - Initialization
  
  /// Initializes `self` with the given top-level encoder options.
  internal init(codingPath: [CodingKey] = []) {
    self.storage = _XMLEncodingStorage()
    self.codingPath = codingPath
  }
  
  /// Returns whether a new element can be encoded at this coding path.
  ///
  /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
  internal var canEncodeNewValue: Bool {
    // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
    // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
    // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
    //
    // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
    // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
    return self.storage.count == self.codingPath.count
  }
  
  // MARK: - Encoder Methods
  public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
    // If an existing keyed container was already requested, return that one.
    let topContainer: NSMutableDictionary
    if self.canEncodeNewValue {
      // We haven't yet pushed a container at this level; do so here.
      topContainer = self.storage.pushKeyedContainer()
    } else {
      guard let container = self.storage.containers.last as? NSMutableDictionary else {
        preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
      }
      
      topContainer = container
    }
    
    let container = XMLCodingKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    return KeyedEncodingContainer(container)
  }
  
  public func unkeyedContainer() -> UnkeyedEncodingContainer {
    // If an existing unkeyed container was already requested, return that one.
    let topContainer: NSMutableArray
    if self.canEncodeNewValue {
      // We haven't yet pushed a container at this level; do so here.
      topContainer = self.storage.pushUnkeyedContainer()
    } else {
      guard let container = self.storage.containers.last as? NSMutableArray else {
        preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
      }
      
      topContainer = container
    }
    
    return _XMLUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
  }
  
  public func singleValueContainer() -> SingleValueEncodingContainer {
    return self
  }
}

// MARK: - Encoding Containers
fileprivate struct XMLCodingKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
  typealias Key = K
  
  // MARK: Properties
  
  /// A reference to the encoder we're writing to.
  private let encoder: _XMLEncoder
  
  /// A reference to the container we're writing to.
  private let container: NSMutableDictionary
  
  /// The path of coding keys taken to get to this point in encoding.
  private(set) public var codingPath: [CodingKey]
  
  // MARK: - Initialization
  
  /// Initializes `self` with the given references.
  fileprivate init(referencing encoder: _XMLEncoder, codingPath: [CodingKey], wrapping container: NSMutableDictionary) {
    self.encoder = encoder
    self.codingPath = codingPath
    self.container = container
  }
  
  // MARK: - KeyedEncodingContainerProtocol Methods
  
  public mutating func encodeNil(forKey key: Key) throws {
    self.container[key.stringValue] = NSNull()
  }
  
  public mutating func encode(_ value: Bool, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: Int, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: Int8, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: Int16, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: Int32, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: Int64, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: UInt, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: UInt8, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: UInt16, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: UInt32, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: UInt64, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: String, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = self.encoder.box(value)
  }
  
  public mutating func encode(_ value: Float, forKey key: Key) throws {
    // Since the float may be invalid and throw, the coding path needs to contain this key.
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }
    
    self.container[key.stringValue] = try self.encoder.box(value)
  }
  
  public mutating func encode(_ value: Double, forKey key: Key) throws {
    // Since the double may be invalid and throw, the coding path needs to contain this key.
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }

    self.container[key.stringValue] = try self.encoder.box(value)
  }
  
  public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
    self.encoder.codingPath.append(key)
    defer { self.encoder.codingPath.removeLast() }
    
    self.container[key.stringValue] = try self.encoder.box(value)
  }
  
  public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
    let dictionary = NSMutableDictionary()
    self.container[key.stringValue] = dictionary
    
    self.codingPath.append(key)
    defer { self.codingPath.removeLast() }
    
    let container = XMLCodingKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
    return KeyedEncodingContainer(container)
  }
  
  public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
    let array = NSMutableArray()
    self.container[key.stringValue] = array
    
    self.codingPath.append(key)
    defer { self.codingPath.removeLast() }
    return _XMLUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
  }
  
  public mutating func superEncoder() -> Encoder {
    return _XMLReferencingEncoder(referencing: self.encoder, key: XMLCodingKey.super, convertedKey: XMLCodingKey.super, wrapping: self.container)
  }
  
  public mutating func superEncoder(forKey key: Key) -> Encoder {
    return _XMLReferencingEncoder(referencing: self.encoder, key: key, convertedKey: key, wrapping: self.container)
  }
}

fileprivate struct _XMLUnkeyedEncodingContainer : UnkeyedEncodingContainer {
  // MARK: Properties
  
  /// A reference to the encoder we're writing to.
  private let encoder: _XMLEncoder
  
  /// A reference to the container we're writing to.
  private let container: NSMutableArray
  
  /// The path of coding keys taken to get to this point in encoding.
  private(set) public var codingPath: [CodingKey]
  
  /// The number of elements encoded into the container.
  public var count: Int {
    return self.container.count
  }
  
  // MARK: - Initialization
  
  /// Initializes `self` with the given references.
  fileprivate init(referencing encoder: _XMLEncoder, codingPath: [CodingKey], wrapping container: NSMutableArray) {
    self.encoder = encoder
    self.codingPath = codingPath
    self.container = container
  }
  
  // MARK: - UnkeyedEncodingContainer Methods
  
  public mutating func encodeNil()             throws { self.container.add(NSNull()) }
  public mutating func encode(_ value: Bool)   throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: Int)    throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: Int8)   throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: Int16)  throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: Int32)  throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: Int64)  throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: UInt)   throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: UInt8)  throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: UInt16) throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: UInt32) throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: UInt64) throws { self.container.add(self.encoder.box(value)) }
  public mutating func encode(_ value: String) throws { self.container.add(self.encoder.box(value)) }
  
  public mutating func encode(_ value: Float)  throws {
    // Since the float may be invalid and throw, the coding path needs to contain this key.
    self.encoder.codingPath.append(XMLCodingKey(index: self.count))
    defer { self.encoder.codingPath.removeLast() }
    self.container.add(try self.encoder.box(value))
  }
  
  public mutating func encode(_ value: Double) throws {
    // Since the double may be invalid and throw, the coding path needs to contain this key.
    self.encoder.codingPath.append(XMLCodingKey(index: self.count))
    defer { self.encoder.codingPath.removeLast() }
    self.container.add(try self.encoder.box(value))
  }
  
  public mutating func encode<T : Encodable>(_ value: T) throws {
    self.encoder.codingPath.append(XMLCodingKey(index: self.count))
    defer { self.encoder.codingPath.removeLast() }
    self.container.add(try self.encoder.box(value))
  }
  
  public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
    self.codingPath.append(XMLCodingKey(index: self.count))
    defer { self.codingPath.removeLast() }
    
    let dictionary = NSMutableDictionary()
    self.container.add(dictionary)
    
    let container = XMLCodingKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
    return KeyedEncodingContainer(container)
  }
  
  public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
    self.codingPath.append(XMLCodingKey(index: self.count))
    defer { self.codingPath.removeLast() }
    
    let array = NSMutableArray()
    self.container.add(array)
    return _XMLUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
  }
  
  public mutating func superEncoder() -> Encoder {
    return _XMLReferencingEncoder(referencing: self.encoder, at: self.container.count, wrapping: self.container)
  }
}

extension _XMLEncoder: SingleValueEncodingContainer {
  // MARK: - SingleValueEncodingContainer Methods
  
  fileprivate func assertCanEncodeNewValue() {
    precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
  }
  
  public func encodeNil() throws {
    assertCanEncodeNewValue()
    self.storage.push(container: NSNull())
  }
  
  public func encode(_ value: Bool) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: Int) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: Int8) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: Int16) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: Int32) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: Int64) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: UInt) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: UInt8) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: UInt16) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: UInt32) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: UInt64) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: String) throws {
    assertCanEncodeNewValue()
    self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: Float) throws {
    assertCanEncodeNewValue()
    try self.storage.push(container: self.box(value))
  }
  
  public func encode(_ value: Double) throws {
    assertCanEncodeNewValue()
    try self.storage.push(container: self.box(value))
  }
  
  public func encode<T : Encodable>(_ value: T) throws {
    assertCanEncodeNewValue()
    try self.storage.push(container: self.box(value))
  }
}

extension _XMLEncoder {
  /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
  fileprivate func box(_ value: Bool)   -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int)    -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int8)   -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int16)  -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int32)  -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: Int64)  -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt)   -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt8)  -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt16) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt32) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: UInt64) -> NSObject { return NSNumber(value: value) }
  fileprivate func box(_ value: String) -> NSObject { return NSString(string: value) }
  
  internal func box(_ value: Float) throws -> NSObject {
    return NSNumber(value: value)
  }
  
  internal func box(_ value: Double) throws -> NSObject {
    return NSNumber(value: value)
  }
  
  internal func box(_ value: Date) throws -> NSObject {
    try value.encode(to: self)
    return self.storage.popContainer()
  }
  
  internal func box(_ value: Data) throws -> NSObject {
    try value.encode(to: self)
    return self.storage.popContainer()
  }
  
  fileprivate func box<T : Encodable>(_ value: T) throws -> NSObject {
    return try self.box_(value) ?? NSDictionary()
  }
  
  // This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
  fileprivate func box_<T : Encodable>(_ value: T) throws -> NSObject? {
    if T.self == Date.self || T.self == NSDate.self {
      return try self.box((value as! Date))
    } else if T.self == Data.self || T.self == NSData.self {
      return try self.box((value as! Data))
    } else if T.self == URL.self || T.self == NSURL.self {
      return self.box((value as! URL).absoluteString)
    } else if T.self == Decimal.self || T.self == NSDecimalNumber.self {
      return (value as! NSDecimalNumber)
    }
    
    let depth = self.storage.count
    try value.encode(to: self)
    
    // The top container should be a new container.
    guard self.storage.count > depth else {
      return nil
    }
    
    return self.storage.popContainer()
  }
}


// MARK:- Reference Container

/// _XMLReferencingEncoder is a special subclass of _XMLEncoder which has its own storage, but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
internal class _XMLReferencingEncoder : _XMLEncoder {
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
  internal let encoder: _XMLEncoder
  
  /// The container reference itself.
  private let reference: Reference
  
  // MARK: - Initialization
  
  /// Initializes `self` by referencing the given array container in the given encoder.
  internal init(referencing encoder: _XMLEncoder, at index: Int, wrapping array: NSMutableArray) {
    self.encoder = encoder
    self.reference = .array(array, index)
    super.init(codingPath: encoder.codingPath)
    
    self.codingPath.append(XMLCodingKey(index: index))
  }
  
  /// Initializes `self` by referencing the given dictionary container in the given encoder.
  internal init(referencing encoder: _XMLEncoder,
                key: CodingKey, convertedKey: CodingKey, wrapping dictionary: NSMutableDictionary) {
    self.encoder = encoder
    self.reference = .dictionary(dictionary, convertedKey.stringValue)
    super.init(codingPath: encoder.codingPath)
    
    self.codingPath.append(key)
  }
  
  // MARK: - Coding Path Operations
  
  internal override var canEncodeNewValue: Bool {
    // With a regular encoder, the storage and coding path grow together.
    // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
    // We have to take this into account.
    return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
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
    case .array(let array, let index):
      array.insert(value, at: index)
      
    case .dictionary(let dictionary, let key):
      dictionary[NSString(string: key)] = value
    }
  }
}

// MARK: - Encoding Storage

internal struct _XMLEncodingStorage {
  // MARK: Properties
  
  /// The container stack.
  /// Elements may be any one of the XML types (NSNull, NSNumber, NSString, NSArray, NSDictionary).
  private(set) internal var containers: [NSObject] = []
  
  // MARK: - Initialization
  
  /// Initializes `self` with no containers.
  internal init() {}
  
  // MARK: - Modifying the Stack
  
  internal var count: Int {
    return self.containers.count
  }
  
  internal mutating func pushKeyedContainer() -> NSMutableDictionary {
    let dictionary = NSMutableDictionary()
    self.containers.append(dictionary)
    return dictionary
  }
  
  internal mutating func pushUnkeyedContainer() -> NSMutableArray {
    let array = NSMutableArray()
    self.containers.append(array)
    return array
  }
  
  internal mutating func push(container: NSObject) {
    self.containers.append(container)
  }
  
  internal mutating func popContainer() -> NSObject {
    precondition(!self.containers.isEmpty, "Empty container stack.")
    return self.containers.popLast()!
  }
}
