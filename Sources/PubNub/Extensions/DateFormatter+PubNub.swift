//
//  DateFormatter+PubNub.swift
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
