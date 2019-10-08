//
//  String+PubNub.swift
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

extension String {
  /// A channel name conforming to PubNub presence channel naming conventions
  var presenceChannelName: String {
    return "\(self)\(Constant.presenceChannelSuffix)"
  }

  /// If the `String` conforms to PubNub presence channel naming conventions
  var isPresenceChannelName: Bool {
    return hasSuffix(Constant.presenceChannelSuffix)
  }

  /// If the `String` conforms to PubNub presence channel naming conventions
  var trimmingPresenceChannelSuffix: String {
    if isPresenceChannelName {
      return String(dropLast(Constant.presenceChannelSuffix.count))
    }
    return self
  }

  /// Sanitizes attempts to include `/` characters inside path components
  var urlEncodeSlash: String {
    return replacingOccurrences(of: "/", with: "%2F")
  }

  /// URLDecodes double encoded slasshes `%252F` -> `%2F` (-> `/`)
  var decodeDoubleEncodedSlash: String {
    return replacingOccurrences(of: "%252F", with: "%2F")
  }

  /// Sanitizes attempts to include `+` and `?` inside query componetns
  var additionalQueryEncoding: String {
    return replacingOccurrences(of: "+", with: "%2B")
      .replacingOccurrences(of: "?", with: "%3F")
  }

  /// Strips path and extension and returns filename
  var absolutePathFilename: String {
    var pathComponents = components(separatedBy: "/")
    let filename = pathComponents.removeLast().components(separatedBy: ".")
    if !filename.isEmpty {
      return filename[0]
    }
    return self
  }

  /// The value of this `String` formatted for use inside a JSON payload
  public var jsonDescription: String {
    return "\"\(description)\""
  }

  /// Trims the JSON string quotes at the ends of this `String`
  var reverseJSONDescription: String {
    return trimmingCharacters(in: CharacterSet(charactersIn: "\""))
  }
}
