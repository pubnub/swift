//
//  PubNubFetchMessagesResultObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubFetchMessagesResultObjC: NSObject {
  @objc public let messages: [String: [PubNubMessageObjC]]
  @objc public let page: PubNubBoundedPageObjC?

  init(messages: [String: [PubNubMessageObjC]], page: PubNubBoundedPageObjC?) {
    self.messages = messages
    self.page = page
  }
}

@objc
public class PubNubBoundedPageObjC: NSObject {
  @objc public let start: NSNumber?
  @objc public let end: NSNumber?
  @objc public let limit: NSNumber?

  @objc public init(start: NSNumber?, end: NSNumber?, limit: NSNumber?) {
    self.start = start
    self.end = end
    self.limit = limit
  }

  init(page: PubNubBoundedPage?) {
    if let start = page?.start {
      self.start = NSNumber(value: start)
    } else {
      self.start = nil
    }
    if let end = page?.end {
      self.end = NSNumber(value: end)
    } else {
      self.end = nil
    }
    if let limit = page?.limit {
      self.limit = NSNumber(value: limit)
    } else {
      self.limit = nil
    }
  }
}
