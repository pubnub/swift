//
//  PubNubMessageActionObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubMessageActionObjC: NSObject {
  @objc public let event: String
  @objc public let actionType: String
  @objc public let actionValue: String
  @objc public let actionTimetoken: Timetoken
  @objc public let messageTimetoken: Timetoken
  @objc public let publisher: String
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let published: NSNumber?

  convenience init(action: PubNubMessageActionEvent) {
    switch action {
    case .added(let action):
      self.init(event: "", action: action)
    case .removed(let action):
      self.init(event: "", action: action)
    }
  }

  convenience init(action: PubNubMessageAction) {
    self.init(event: "", action: action)
  }

  private init(event: String, action: PubNubMessageAction) {
    self.event = event
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
