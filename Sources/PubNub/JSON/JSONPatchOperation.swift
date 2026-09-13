//
//  JSONPatchOperation.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A single [RFC 6902](https://datatracker.ietf.org/doc/html/rfc6902) JSON Patch operation.
///
/// Paths are [RFC 6901](https://datatracker.ietf.org/doc/html/rfc6901) JSON Pointers.
enum JSONPatchOperation: Hashable {
  /// Adds `value` at `path`
  case add(path: String, value: AnyJSON)
  /// Removes the value at `path`
  case remove(path: String)
  /// Replaces the value at `path` with `value`
  case replace(path: String, value: AnyJSON)
  /// Moves the value at `from` to `path`
  case move(from: String, path: String)
  /// Copies the value at `from` to `path`
  case copy(from: String, path: String)
  /// Asserts that the value at `path` equals `value`, failing the whole patch when it doesn't
  case test(path: String, value: AnyJSON)

  /// The RFC 6902 `op` member of the operation
  var op: Op {
    switch self {
    case .add: return .add
    case .remove: return .remove
    case .replace: return .replace
    case .move: return .move
    case .copy: return .copy
    case .test: return .test
    }
  }

  /// The JSON Pointer the operation is applied to
  var path: String {
    switch self {
    case let .add(path, _): return path
    case let .remove(path): return path
    case let .replace(path, _): return path
    case let .move(_, path): return path
    case let .copy(_, path): return path
    case let .test(path, _): return path
    }
  }

  /// The JSON Pointer the value is taken from, for the operations that have one
  var from: String? {
    switch self {
    case let .move(from, _): return from
    case let .copy(from, _): return from
    case .add, .remove, .replace, .test: return nil
    }
  }

  /// The operand, for the operations that carry one
  var value: AnyJSON? {
    switch self {
    case let .add(_, value): return value
    case let .replace(_, value): return value
    case let .test(_, value): return value
    case .remove, .move, .copy: return nil
    }
  }
}

// MARK: - Op

extension JSONPatchOperation {
  enum Op: String, Codable, CaseIterable {
    case add
    case remove
    case replace
    case move
    case copy
    case test
  }
}

// MARK: - Codable

extension JSONPatchOperation: Codable {
  private enum CodingKeys: String, CodingKey {
    case op
    case path
    case value
    case from
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let op = try container.decode(Op.self, forKey: .op)
    let path = try container.decode(String.self, forKey: .path)

    switch op {
    case .add:
      self = .add(path: path, value: try container.decode(AnyJSON.self, forKey: .value))
    case .remove:
      self = .remove(path: path)
    case .replace:
      self = .replace(path: path, value: try container.decode(AnyJSON.self, forKey: .value))
    case .move:
      self = .move(from: try container.decode(String.self, forKey: .from), path: path)
    case .copy:
      self = .copy(from: try container.decode(String.self, forKey: .from), path: path)
    case .test:
      self = .test(path: path, value: try container.decode(AnyJSON.self, forKey: .value))
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(op, forKey: .op)
    try container.encode(path, forKey: .path)
    try container.encodeIfPresent(from, forKey: .from)
    try container.encodeIfPresent(value, forKey: .value)
  }
}

// MARK: - CustomStringConvertible

extension JSONPatchOperation: CustomStringConvertible {
  var description: String {
    switch self {
    case let .add(path, value):
      return "add(path: \(path), value: \(value))"
    case let .remove(path):
      return "remove(path: \(path))"
    case let .replace(path, value):
      return "replace(path: \(path), value: \(value))"
    case let .move(from, path):
      return "move(from: \(from), path: \(path))"
    case let .copy(from, path):
      return "copy(from: \(from), path: \(path))"
    case let .test(path, value):
      return "test(path: \(path), value: \(value))"
    }
  }
}
