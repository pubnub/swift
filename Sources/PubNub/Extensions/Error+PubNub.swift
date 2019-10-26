//
//  Error+PubNub.swift
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

extension Error {
  /// Instance cast as a `PubNubError`
  public var pubNubError: PubNubError? {
    return self as? PubNubError
  }

  /// Returns the `PubNubError.Reason` if one exists for the `Error`
  var genericPubNubReason: PubNubError.Reason? {
    if let reason = urlError?.pubnubReason {
      return reason
    } else if let reason = anyJSON?.pubnubReason {
      return reason
    } else if let reason = pubNubError?.reason {
      return reason
    }

    return nil
  }

  /// Instance cast as a `URLError`
  public var urlError: URLError? {
    return self as? URLError
  }

  /// Instance cast as a `AnyJSONError`
  var anyJSON: AnyJSONError? {
    return self as? AnyJSONError
  }

  /// If a cancellation was the cause of this error
  public var isCancellationError: Bool {
    return urlError?.code == .cancelled ||
      pubNubError?.subdomain == .cancellation
  }

  /// Instance cast as a `EncodingError`
  public var encodingError: EncodingError? {
    return self as? EncodingError
  }

  /// Instance cast as a `DecodingError`
  public var decodingError: DecodingError? {
    return self as? DecodingError
  }
}
