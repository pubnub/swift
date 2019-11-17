//
//  Validated.swift
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

public protocol Validated {
  /// The error resulting from an invlid object
  ///
  /// Required
  var validationError: Error? { get }

  /// `String` describing why the error occurred
  var validationErrorDetail: String? { get }
}

extension Validated {
  /// If this is a valid instance of the object
  public var isValid: Bool {
    return validationError == nil
  }

  /// A `Result` that is either the concrete value or an `Error`
  public var validResult: Result<Self, Error> {
    if let error = validationError {
      return .failure(error)
    }
    return .success(self)
  }

  public var validationErrorDetail: String? {
    return nil
  }

  func isInvalidForReason(_ values: (Bool, String)...) -> String? {
    for (invalidValue, message) in values where invalidValue {
      return message
    }
    return nil
  }
}
