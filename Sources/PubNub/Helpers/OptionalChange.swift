//
//  OptionalChange.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Object that represents a possible change on an Optional object
public enum OptionalChange<Wrapped> {
  /// Target value should not be changed
  case noChange
  /// Target value should be updated to be `nil`
  case none
  /// Target value should be updated to be the `Wrapped` value
  case some(Wrapped)

  /// Whether this `OptionalChange` should mutate a target value
  public var hasChange: Bool {
    switch self {
    case .noChange:
      return false
    case .none:
      return true
    case .some:
      return true
    }
  }

  /// The associated value of the enum, if one exists
  public var underlying: Wrapped? {
    switch self {
    case .noChange:
      return nil
    case .none:
      return nil
    case let .some(value):
      return value
    }
  }

  /// Update a value based on the state of the `OptionalChange`
  ///
  ///  - parameter applying: The target `Wrapped` value to be updated
  ///  - returns: The updated value, or the same value if there was no change
  public func applying(_ value: Wrapped?) -> Wrapped? {
    switch self {
    case .noChange:
      return value
    case .none:
      return nil
    case let .some(newValue):
      return newValue
    }
  }

  /// Update a value based on the state of the `OptionalChange`
  ///
  ///  - parameter applying: A reference to the target `Wrapped` value to be updated
  public func apply(_ value: inout Wrapped?) {
    switch self {
    case .noChange:
      break
    case .none:
      value = nil
    case let .some(newValue):
      value = newValue
    }
  }

  /// Returns a new `OptionalChange` containing the wrapped valued transformed by the given closure.
  ///
  /// If the `OptionalChange` was either `noChange` or `none` then the value returned will be a new OptionalChange matching the type of the given closure.
  /// - Parameter transform: A closure that transforms a value.
  /// - Returns: An `OptionalChange` containing the transformed value.
  public func mapValue<T>(_ transform: (Wrapped) throws -> T) rethrows -> OptionalChange<T> {
    switch self {
    case .noChange:
      return OptionalChange<T>.noChange
    case .none:
      return OptionalChange<T>.none
    case let .some(wrapped):
      return OptionalChange<T>.some(try transform(wrapped))
    }
  }
}

public extension KeyedEncodingContainer {
  /// Encodes the wrapped value given `OptionalChange` for the given key.
  ///  - Parameter value: The value to encode.
  ///  - Parameter key: The key to associate the value with.
  mutating func encode<T: Encodable>(_ value: OptionalChange<T>, forKey key: Key) throws {
    switch value {
    case .noChange:
      // no-op
      break
    case .none:
      try encodeNil(forKey: key)
    case let .some(value):
      try encode(value, forKey: key)
    }
  }
}

public extension KeyedDecodingContainer {
  /// Decodes a wrapped value of the given `OptionalChange` for the given key.
  /// - Parameter type:The type of value to decode.
  /// - Parameter key: The key that the decoded value is associated with.
  /// - Returns: An `OptionalChange` of the requested type, if present for the given key and convertible to the requested type.
  func decode<T: Decodable>(
    _: OptionalChange<T>.Type,
    forKey key: KeyedDecodingContainer<K>.Key
  ) throws -> OptionalChange<T> {
    if contains(key) {
      if let value = try decodeIfPresent(T.self, forKey: key) {
        return .some(value)
      } else {
        return .none
      }
    } else {
      return .noChange
    }
  }
}

extension OptionalChange: Equatable where Wrapped: Equatable {}
extension OptionalChange: Hashable where Wrapped: Hashable {}
