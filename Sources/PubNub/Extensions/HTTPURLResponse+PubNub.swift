//
//  HTTPURLResponse+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension HTTPURLResponse {
  /// If the `HTTPURLResponse` can be considered successful based on its status code
  var isSuccessful: Bool {
    return HTTPURLResponse.successfulStatusCodes.contains(statusCode)
  }

  internal var statusCodeReason: PubNubError.Reason? {
    if !isSuccessful {
      let reason = PubNubError.Reason(
        rawValue: statusCode
      ) ?? .unknown

      return reason
    }

    return nil
  }

  /// Range of successful status codes from 200 to 299
  static let successfulStatusCodes: Range<Int> = 200 ..< 300
}
