//
//  PubNubPage.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2020 PubNub Inc.
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

// MARK: - Bounded Page

/// A response page that is bounded by one or more Timetokens
public protocol PubNubBoundedPage {
  /// The start value for the next set of remote data
  var start: Timetoken? { get }
  /// The bounded end value that will be eventually fetched to
  var end: Timetoken? { get }
  /// The previous limiting value (if any)
  var limit: Int? { get }

  /// Allows for converting  between different PubNubBoundedPage types
  init(from other: PubNubBoundedPage) throws
}

extension PubNubBoundedPage {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubBoundedPage>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubBoundedPage>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: Concrete Base Class

/// The default implementation of the `PubNubBoundedPage` protocol
public struct PubNubBoundedPageBase: PubNubBoundedPage, Codable, Hashable {
  public let start: Timetoken?
  public let end: Timetoken?
  public let limit: Int?

  public init?(start: Timetoken? = nil, end: Timetoken? = nil, limit: Int? = nil) {
    if start == nil, end == nil, limit == nil {
      return nil
    }

    self.start = start
    self.end = end
    self.limit = limit
  }

  public init(from other: PubNubBoundedPage) throws {
    start = other.start
    end = other.end
    limit = other.limit
  }
}

// MARK: - Hashed Page

/// A cursor for the next page of a remote data
public protocol PubNubHashedPage {
  /// The hash value representing the netxt set of data
  var start: String? { get }
  /// The hash value representing the previous set of data
  var end: String? { get }
  /// The total count of all objects withing range
  var totalCount: Int? { get }

  /// Allows for converting  between different PubNubHashedPage types
  init(from other: PubNubHashedPage) throws
}

extension PubNubHashedPage {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubHashedPage>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubHashedPage>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: Concrete Base Class

/// The default implementation of the `PubNubHashedPage` protocol
public struct PubNubHashedPageBase: PubNubHashedPage, Codable, Hashable {
  public var start: String?
  public var end: String?
  public var totalCount: Int?

  public init(
    start: String? = nil,
    end: String? = nil,
    totalCount: Int? = nil
  ) {
    self.start = start
    self.end = end
    self.totalCount = totalCount
  }

  public init(from other: PubNubHashedPage) throws {
    self.init(
      start: other.start,
      end: other.end,
      totalCount: other.totalCount
    )
  }
}

// MARK: Other Internal Extensions

extension PubNubChannelsMetadataResponsePayload: PubNubHashedPage {
  var start: String? {
    return next
  }

  var end: String? {
    return prev
  }

  init(from other: PubNubHashedPage) throws {
    self.init(
      status: 200, data: [],
      totalCount: other.totalCount, next: other.start, prev: other.end
    )
  }
}

extension PubNubUUIDsMetadataResponsePayload: PubNubHashedPage {
  var start: String? {
    return next
  }

  var end: String? {
    return prev
  }

  init(from other: PubNubHashedPage) throws {
    self.init(
      status: 200, data: [],
      totalCount: other.totalCount, next: other.start, prev: other.end
    )
  }
}

extension PubNubMembershipsResponsePayload: PubNubHashedPage {
  var start: String? {
    return next
  }

  var end: String? {
    return prev
  }

  init(from other: PubNubHashedPage) throws {
    self.init(
      status: 200, data: [],
      totalCount: other.totalCount, next: other.start, prev: other.end
    )
  }
}
