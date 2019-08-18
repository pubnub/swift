//
//  Collection+PubNub.swift
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
