//
//  WeakBox.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A container that stores a `weak` reference to its `Element`
final class WeakBox<Element>: Hashable where Element: AnyObject, Element: Hashable {
  /// The stored element
  weak var underlying: Element?

  init(_ value: Element?) {
    underlying = value
  }

  static func == (lhs: WeakBox<Element>, rhs: WeakBox<Element>) -> Bool {
    return lhs.underlying == rhs.underlying
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(underlying)
  }
}

struct WeakSet<Element> where Element: AnyObject, Element: Hashable {
  private var elements: Set<WeakBox<Element>> = []

  init(_ elements: [Element]) {
    elements.forEach { self.elements.update(with: WeakBox($0)) }
  }

  // NSSet Operations
  var allObjects: [Element] {
    return elements.compactMap { $0.underlying }
  }

  var count: Int {
    return self.elements.count
  }

  mutating func update(_ element: Element) {
    elements.update(with: WeakBox(element))
  }

  mutating func remove(_ element: Element) {
    elements.remove(WeakBox(element))
  }

  mutating func removeAll() {
    elements.removeAll()
  }
}

extension WeakSet: Collection {
  var startIndex: Set<WeakBox<Element>>.Index { return elements.startIndex }
  var endIndex: Set<WeakBox<Element>>.Index { return elements.endIndex }

  subscript(position: Set<WeakBox<Element>>.Index) -> Element? {
    return elements[position].underlying
  }

  func index(after index: Set<WeakBox<Element>>.Index) -> Set<WeakBox<Element>>.Index {
    return elements.index(after: index)
  }
}
