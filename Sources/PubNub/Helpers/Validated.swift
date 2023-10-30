//
//  Validated.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public protocol Validated {
  /// The error resulting from an invlid object
  ///
  /// Required
  var validationError: Error? { get }

  /// `String` describing why the error occurred
  var validationErrorDetail: String? { get }
}

public extension Validated {
  /// If this is a valid instance of the object
  var isValid: Bool {
    return validationError == nil
  }

  /// A `Result` that is either the concrete value or an `Error`
  var validResult: Result<Self, Error> {
    if let error = validationError {
      return .failure(error)
    }
    return .success(self)
  }

  var validationErrorDetail: String? {
    return nil
  }

  internal func isInvalidForReason(_ values: (Bool, String)...) -> String? {
    for (invalidValue, message) in values where invalidValue {
      return message
    }
    return nil
  }
}
