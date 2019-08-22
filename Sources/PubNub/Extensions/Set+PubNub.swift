//
//  Set+PubNub.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

extension Set {
  var allObjects: [Element] {
    return Array(self)
  }

  /// Updates the `Set` with the contents of another `Collection`
  /// - parameters:
  ///   - with: The `Collection` that will be added to this `Set`
  /// - returns: For ordinary sets, an element equal to newMember if the set
  ///   already contained such a member; otherwise, nil. In some cases, the returned
  ///   element may be distinguishable from newMember by identity comparison or some other means.
  @discardableResult
  @inlinable mutating func update<C>(with contentsOf: C) -> [Element] where C: Collection, Element == C.Element {
    return contentsOf.compactMap { self.update(with: $0) }
  }

  /// Remove elements from the `Set` matching conents of supplied `Collection`
  /// - parameters:
  ///   - with: The `Collection` of items that will be removed from this `Set`
  /// - returns: For ordinary sets, an element equal to member if member is contained
  ///   in the set; otherwise, nil. In some cases, a returned element may be
  ///   distinguishable from newMember by identity comparison or some other means.
  @discardableResult
  @inlinable mutating func remove<C>(contentsOf: C) -> [Element] where C: Collection, Element == C.Element {
    return contentsOf.compactMap { self.remove($0) }
  }
}
