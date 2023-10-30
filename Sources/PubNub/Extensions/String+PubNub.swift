//
//  String+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
