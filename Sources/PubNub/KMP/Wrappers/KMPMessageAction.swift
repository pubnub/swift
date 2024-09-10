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

/// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
///
/// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
/// While these symbols are public, they are intended strictly for internal usage.
///
/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc
public class KMPMessageAction: NSObject {
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
      self.init(event: "added", action: action)
    case .removed(let action):
      self.init(event: "removed", action: action)
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
    self.published = if let tt = action.published { NSNumber(value: tt) } else { nil }
  }
}
