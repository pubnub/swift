//
//  PubNubHashedPageObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

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
    self.start = page?.prev
    self.end = page?.end
    self.totalCount = if let totalCount = page?.totalCount {
      NSNumber(value: totalCount)
    } else {
      nil
    }
  }
}

@objc
public class PubNubSortPropertyObjC: NSObject {
  @objc public let key: String
  @objc public let direction: String
  
  @objc
  public init(key: String, direction: String) {
    self.key = key
    self.direction = direction
  }
}

@objc
public class PubNubGetChannelMetadataResultObjC : NSObject {
  @objc public let status: Int
  @objc public let data: [PubNubChannelMetadataObjC]
  @objc public let totalCount: NSNumber?
  @objc public let next: PubNubHashedPageObjC?
  
  init(
    status: Int,
    data: [PubNubChannelMetadataObjC],
    totalCount: NSNumber?,
    next: PubNubHashedPageObjC?
  ) {
    self.status = status
    self.data = data
    self.totalCount = totalCount
    self.next = next
  }
}

@objc
public class PubNubGetUUIDMetadaResultObjC: NSObject {
  @objc public var status: Int
  @objc public var data: [PubNubUUIDMetadataObjC]
  @objc public var totalCount: NSNumber?
  @objc public var next: PubNubHashedPageObjC?
  
  init(
    status: Int,
    data: [PubNubUUIDMetadataObjC],
    totalCount: NSNumber? = nil,
    next: PubNubHashedPageObjC? = nil
  ) {
    self.status = status
    self.data = data
    self.totalCount = totalCount
    self.next = next
  }
}
