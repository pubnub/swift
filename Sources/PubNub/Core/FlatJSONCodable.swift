//
//  FlatJSONCodable.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// JSON structure that cannot have nested values
public protocol FlatJSONCodable: JSONCodable {
  /// Convience init that allows protocol conversion between diffferent FlatJSONCodable types
  init(flatJSON: [String: JSONCodableScalar])
  /// Dictionary representation of the JSON structure
  ///
  ///  This allows for the Object to contain nested properties, but for the resulting codable value to remain flat
  var flatJSON: [String: JSONCodableScalar] { get }
}

public extension FlatJSONCodable {
  /// Convience init that allows protocol conversion between diffferent FlatJSONCodable types
  init(flatJSON: [String: JSONCodableScalar]?) {
    if let flatJSON = flatJSON {
      self.init(flatJSON: flatJSON)
    } else {
      self.init(flatJSON: [:])
    }
  }

  var flatJSON: [String: JSONCodableScalar] {
    var payload = [String: JSONCodableScalar]()

    for child in Mirror(reflecting: self).children {
      if let label = child.label, let value = child.value as? JSONCodableScalar {
        payload.updateValue(value, forKey: label)
      }
    }

    return payload
  }
}

// MARK: Concrete Impl.

/// Internal object that allows conversion between Objectv2 [String: JSONScalar] and JSONCodable
public struct FlatJSON: FlatJSONCodable, Hashable {
  public var json: [String: JSONCodableScalarType]

  public init(flatJSON: [String: JSONCodableScalar]) {
    json = flatJSON.mapValues { $0.scalarValue }
  }

  public var flatJSON: [String: JSONCodableScalar] {
    return json
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    json = try container.decode([String: JSONCodableScalarType].self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    try container.encode(json)
  }
}
