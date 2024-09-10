//
//  PubNubFetchMessagesResultObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
//
// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
// While these symbols are public, they are intended strictly for internal usage.
//
// External developers should refrain from directly using these symbols in their code, as their implementation details
// may change in future versions of the framework, potentially leading to breaking changes.

import Foundation

@objc
public class KMPFetchMessagesResult: NSObject {
  @objc public let messages: [String: [KMPMessage]]
  @objc public let page: KMPBoundedPage?

  init(messages: [String: [KMPMessage]], page: KMPBoundedPage?) {
    self.messages = messages
    self.page = page
  }
}

@objc
public class KMPBoundedPage: NSObject {
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
