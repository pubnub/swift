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
  private var elements: Atomic<Set<WeakBox<Element>>> = Atomic([])

  init(_ elements: [Element]) {
    self.elements.lockedWrite { [elements] currentValue in
      elements.forEach { element in
        currentValue.update(with: WeakBox(element))
      }
    }
  }

  // NSSet Operations
  var allObjects: [Element] {
    return elements.lockedRead { $0.compactMap { $0.underlying } }
  }

  var count: Int {
    elements.lockedRead { $0.count }
  }

  mutating func update(_ element: Element) {
    elements.lockedWrite { [element] in
      $0.update(with: WeakBox(element))
    }
  }

  mutating func remove(_ element: Element) {
    elements.lockedWrite { [element] in
      $0.remove(WeakBox(element))
    }
  }

  mutating func removeAll() {
    elements.lockedWrite { $0 = Set<WeakBox<Element>>() }
  }
}

extension WeakSet: Collection {
  var startIndex: Set<WeakBox<Element>>.Index { return elements.lockedRead { $0.startIndex } }
  var endIndex: Set<WeakBox<Element>>.Index { return elements.lockedRead { $0.endIndex } }

  subscript(position: Set<WeakBox<Element>>.Index) -> Element? {
    elements.lockedRead { $0[position].underlying }
  }

  func index(after index: Set<WeakBox<Element>>.Index) -> Set<WeakBox<Element>>.Index {
    elements.lockedRead { $0.index(after: index) }
  }
}

extension WeakSet where Element == BaseSubscriptionListener {
  func forEach(_ body: (BaseSubscriptionListener) throws -> Void) rethrows {
    try elements.lockedTry {
      try $0.compactMap {
        $0.underlying
      }.forEach {
        try body($0)
      }
    }
  }
}
