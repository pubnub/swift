//
//  PubNumbHTTPHeaders.swift
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

/// A Collection whose elements are HTTPHeader values objects
public struct PubNubHTTPHeaders: Hashable {
  var headers: [HTTPHeader] = []

  private init() { /* no-op */ }

  public init(_ dictionary: [String: String]) {
    self.init()

    dictionary.forEach { update(HTTPHeader(name: $0.key, value: $0.value)) }
  }

  public init(_ headers: [HTTPHeader]) {
    self.init()

    headers.forEach { update($0) }
  }

  /// Updates the value stored for the given HTTPHeader name,
  /// or adds a new HTTPHeader if the a matching one does not exist.
  public mutating func update(_ header: HTTPHeader) {
    guard let index = headers.firstIndex(of: header.name) else {
      headers.append(header)
      return
    }

    headers.replaceSubrange(index ... index, with: [header])
  }

  /// Updates the value stored for the given HTTPHeader name,
  /// or adds a new HTTPHeader if the a matching one does not exist.
  public mutating func update(name: String, value: String) {
    update(HTTPHeader(name: name, value: value))
  }

  /// The list of HTTPHeader values represented as a Dictionary
  public var allHTTPHeaderFields: [String: String] {
    var dict = [String: String](minimumCapacity: count)
    headers.forEach { dict.updateValue($0.value, forKey: $0.name) }
    return dict
  }
}

extension PubNubHTTPHeaders: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral: (String, String)...) {
    self.init()

    dictionaryLiteral.forEach { update(name: $0.0, value: $0.1) }
  }
}

extension PubNubHTTPHeaders: ExpressibleByArrayLiteral {
  public init(arrayLiteral: HTTPHeader...) {
    self.init(arrayLiteral)
  }
}

extension PubNubHTTPHeaders: Sequence {
  public func makeIterator() -> IndexingIterator<[HTTPHeader]> {
    return headers.makeIterator()
  }
}

extension PubNubHTTPHeaders: Collection {
  public var startIndex: Int {
    return headers.startIndex
  }

  public var endIndex: Int {
    return headers.endIndex
  }

  public subscript(position: Int) -> HTTPHeader {
    return headers[position]
  }

  public func index(after index: Int) -> Int {
    return headers.index(after: index)
  }
}

// MARK: - HTTPHeader

/// A single name-value pair, for use with URL Loding System
public struct HTTPHeader: Hashable {
  /// The name of the key for the header
  public let name: String
  /// The value of the header
  public let value: String
}

extension HTTPHeader: CustomStringConvertible {
  public var description: String {
    return "\(name): \(value)"
  }
}

// Common Headers
extension HTTPHeader {
  /// Produces a `Accept-Encoding` header according to
  /// [RFC7231 section 5.3.4](https://tools.ietf.org/html/rfc7231#section-5.3.4)
  public static func acceptEncoding(_ value: String) -> HTTPHeader {
    return HTTPHeader(name: "Accept-Encoding", value: value)
  }

  /// Produces a `Content-Type` header according to
  /// [RFC7231 section 3.1.1.5](https://tools.ietf.org/html/rfc7231#section-3.1.1.5)
  public static func contentType(_ value: String) -> HTTPHeader {
    return HTTPHeader(name: "Content-Type", value: value)
  }

  /// Produces a `User-Agent` header according to
  /// [RFC7231 section 5.5.3](https://tools.ietf.org/html/rfc7231#section-5.5.3)
  public static func userAgent(_ value: String) -> HTTPHeader {
    return HTTPHeader(name: "User-Agent", value: value)
  }
}

// Defaults
extension HTTPHeader {
  /// The default `Content-Type` used for PubNub requests
  public static let defaultContentType: HTTPHeader = {
    .contentType("application/json; charset=UTF-8")
  }()

  /// The default `Accept-Encoding` used for PubNub requests
  public static let defaultAcceptEncoding: HTTPHeader = {
    let encodings: [String]
    // Brotli (br) support added in iOS 11 https://9to5mac.com/2017/06/21/apple-ios-11-beta-2/
    if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
      encodings = ["br", "gzip", "deflate"]
    } else {
      encodings = ["gzip", "deflate"]
    }
    return .acceptEncoding(encodings.headerQualityEncoded)
  }()

  /// The default `User-Agent` used for PubNub requests
  public static let defaultUserAgent: HTTPHeader = {
    .userAgent(Constant.defaultUserAgent)
  }()
}

extension Array where Element == HTTPHeader {
  /// The index of the first case-insensitive Header name match
  func firstIndex(of name: String) -> Int? {
    let lowercasedName = name.lowercased()
    return firstIndex { $0.name.lowercased() == lowercasedName }
  }
}
