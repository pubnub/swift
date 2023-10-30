//
//  Error+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension Error {
  /// Instance cast as a `PubNubError`
  var pubNubError: PubNubError? {
    return self as? PubNubError
  }

  /// Returns the `PubNubError.Reason` if one exists for the `Error`
  internal var genericPubNubReason: PubNubError.Reason? {
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
  var urlError: URLError? {
    return self as? URLError
  }

  /// Instance cast as a `AnyJSONError`
  internal var anyJSON: AnyJSONError? {
    return self as? AnyJSONError
  }

  /// If a cancellation was the cause of this error
  var isCancellationError: Bool {
    return urlError?.code == .cancelled ||
      pubNubError?.subdomain == .cancellation
  }

  /// Instance cast as a `EncodingError`
  var encodingError: EncodingError? {
    return self as? EncodingError
  }

  /// Instance cast as a `DecodingError`
  var decodingError: DecodingError? {
    return self as? DecodingError
  }

  /// Partial download data that can be used to resume a previous download
  internal var resumeData: Data? {
    if let data = (self as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
      return data
    }

    return nil
  }
}
