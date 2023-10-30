//
//  URLQueryItem+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
import Foundation

internal extension URLQueryItem {
  init(key: QueryKey, value: String?) {
    self.init(name: key.rawValue, value: value)
  }
}

public extension Array where Element == URLQueryItem {
  /// Returns new list of query items replaces any existing
  func merging(_ other: [URLQueryItem]) -> [URLQueryItem] {
    var queryItems = self

    queryItems.merge(other)

    return queryItems
  }

  /// Merges list of query items replaces any existing
  mutating func merge(_ other: [URLQueryItem]) {
    for query in other {
      if let index = firstIndex(of: query.name) {
        replaceSubrange(index ... index, with: [query])
      } else {
        append(query)
      }
    }
  }

  /// Returns the first index whose name matches the parameter
  func firstIndex(of name: String) -> Int? {
    return firstIndex { $0.name == name }
  }

  /// Creates a new query item and appends only if the value is not nil
  mutating func appendIfPresent(name: String, value: String?) {
    if let value = value {
      append(URLQueryItem(name: name, value: value))
    }
  }

  /// Creates a new query item and appends only if the value is not nil
  internal mutating func appendIfPresent(key: QueryKey, value: String?) {
    appendIfPresent(name: key.rawValue, value: value)
  }

  /// Creates a new query item with a csv string value and appends only if the value is not empty
  mutating func appendIfNotEmpty(name: String, value: [String]) {
    if !value.isEmpty {
      append(URLQueryItem(name: name, value: value.csvString.urlEncodeSlash))
    }
  }

  /// Creates a new query item with a csv string value and appends only if the value is not empty
  internal mutating func appendIfNotEmpty(key: QueryKey, value: [String]) {
    appendIfNotEmpty(name: key.rawValue, value: value)
  }
}
