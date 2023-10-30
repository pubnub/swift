//
//  Set+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension Set {
  /// An array containing the set’s members, or an empty array if the set has no members.
  ///
  /// The order of the objects in the array is undefined.
  var allObjects: [Element] {
    return Array(self)
  }
}
