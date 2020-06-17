//
//  WeakBox.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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
