//
//  PubNubDataSyncPage.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// The pagination state returned alongside a DataSync list response.
public struct PubNubDataSyncPage: Hashable {
  /// The opaque cursor identifying the next page, or `nil` when there is no next page
  public let cursor: String?
  /// Whether a next page is available
  public let hasNext: Bool
  /// The number of items per page the service applied
  public let limit: Int

  /// Default init for all fields
  ///
  /// - Parameters:
  ///   - cursor: The opaque cursor identifying the next page
  ///   - hasNext: Whether a next page is available
  ///   - limit: The number of items per page the service applied
  public init(cursor: String?, hasNext: Bool, limit: Int) {
    self.cursor = cursor
    self.hasNext = hasNext
    self.limit = limit
  }

  /// Creates a page from the `meta` object of a list response, or `nil` when the response carried no pagination metadata.
  ///
  /// - Parameters:
  ///   - meta: The pagination metadata decoded from the response
  ///   - requestedLimit: The `limit` the caller asked for, used when the service echoes none back
  init?(from meta: DataSyncPageMeta?, requestedLimit: Int?) {
    guard let meta = meta else {
      return nil
    }
    // Both fields are documented as always present, but fall back rather than fail the response
    guard let limit = meta.limit ?? requestedLimit else {
      return nil
    }

    self.init(
      cursor: meta.nextCursor,
      hasNext: meta.hasNext ?? false,
      limit: limit
    )
  }
}
