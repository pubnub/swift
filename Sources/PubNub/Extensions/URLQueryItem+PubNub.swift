//
//  URLQueryItem+PubNub.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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

public extension Array where Element == URLQueryItem {
  /// Returns new list of query items replaces any existing
  func merging(_ other: [URLQueryItem]) -> [URLQueryItem] {
    var queryItems = self

    queryItems.merge(other)

    return queryItems
  }

  /// Merges list of query items replaces any existing
  mutating func merge(_ other: [URLQueryItem]) {
    for query in other {
      print(query)
      if let index = self.firstIndex(of: query.name) {
        replaceSubrange(index ... index, with: [query])
      } else {
        append(query)
      }
    }
  }

  /// Returns the first index whose name matches the parameter
  func firstIndex(of name: String) -> Int? {
    return firstIndex { $0.name == name }
  }
}
