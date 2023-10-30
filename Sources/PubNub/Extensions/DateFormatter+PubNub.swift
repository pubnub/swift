//
//  DateFormatter+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension DateFormatter {
  /// Returns a string representation of the current `date` formatted using the receiver’s current settings.
  var currentDateString: String {
    return string(from: Date())
  }

  /// DateFormatter class that generates and parses string representations of dates following the ISO 8601 standard
  static let iso8601: DateFormatter = {
    let iso8601DateFormatter = DateFormatter()

    iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    iso8601DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return iso8601DateFormatter
  }()

  internal static let iso8601_noMilliseconds: DateFormatter = {
    let iso8601DateFormatter = DateFormatter()

    iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    iso8601DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return iso8601DateFormatter
  }()
}
