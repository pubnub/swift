//
//  Collection+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension Collection where Element == String {
  /// A comma-separated list of `String` elements
  var csvString: String {
    return joined(separator: ",")
  }

  /// A comma ',' if the this Collection is empty or comma-separated list of `String` elements
  var commaOrCSVString: String {
    return isEmpty ? "," : csvString
  }

  /// Decreases the q-factor weighting of each header value by 0.1 in sequence order
  /// - NOTE: If there 10 or more values in the collection then no weight will be assigned
  var headerQualityEncoded: String {
    if count >= 10 {
      return joined(separator: ", ")
    }

    return enumerated().map { index, encoding in
      let quality = 1.0 - (Double(index) * 0.1)
      return "\(encoding);q=\(quality)"
    }.joined(separator: ", ")
  }
}
