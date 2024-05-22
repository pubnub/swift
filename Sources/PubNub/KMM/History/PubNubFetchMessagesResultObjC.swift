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

@objc
public class PubNubMessageObjC: NSObject {
  init(message: PubNubMessage) {
    self.payload = message.payload
    self.actions = message.actions.map { PubNubMessageActionObjC(action: $0) }
    self.publisher = message.publisher
    self.channel = message.channel
    self.subscription = message.subscription
    self.published = message.published
    self.metadata = message.metadata
    self.messageType = message.messageType.rawValue
    self.error = message.error
  }
  
  @objc public let payload: Any
  @objc public let actions: [PubNubMessageActionObjC]
  @objc public let publisher: String?
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let published: Timetoken
  @objc public let metadata: Any?
  @objc public let messageType: Int
  @objc public let error: Error?
}

@objc
public class PubNubMessageActionObjC: NSObject {
  @objc public let actionType: String
  @objc public let actionValue: String
  @objc public let actionTimetoken: Timetoken
  @objc public let messageTimetoken: Timetoken
  @objc public let publisher: String
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let published: NSNumber?
  
  init(action: PubNubMessageAction) {
    self.actionType = action.actionType
    self.actionValue = action.actionValue
    self.actionTimetoken = action.actionTimetoken
    self.messageTimetoken = action.messageTimetoken
    self.publisher = action.publisher
    self.channel = action.channel
    self.subscription = action.subscription
    self.published = action.published != nil ? NSNumber(value: action.published!) : nil
  }
}
