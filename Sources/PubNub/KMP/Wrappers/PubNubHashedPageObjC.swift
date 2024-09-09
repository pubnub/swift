//
//  PubNubPageObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
///
/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.

/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc
public class PubNubHashedPageObjC: NSObject {
  @objc public let start: String?
  @objc public let end: String?
  @objc public let totalCount: NSNumber?

  @objc
  public init(start: String?, end: String?, totalCount: NSNumber?) {
    self.start = start
    self.end = end
    self.totalCount = totalCount
  }

  init(page: PubNubHashedPage?) {
    self.start = page?.start
    self.end = page?.end
    self.totalCount = if let count = page?.totalCount { NSNumber(value: count) } else { nil }
  }
}

@objc
public class PubNubObjectSortPropertyObjC: NSObject {
  @objc public let key: String
  @objc public let direction: String

  @objc
  public init(key: String, direction: String) {
    self.key = key
    self.direction = direction
  }
}
