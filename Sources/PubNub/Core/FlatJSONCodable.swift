//
//  FlatJSONCodable.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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
