//
//  PubNubMessageObjC.swift
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
public class KMPMessage: NSObject {
  init(message: PubNubMessage) {
    self.payload = KMPAnyJSON(message.payload.codableValue)
    self.actions = message.actions.map { KMPMessageAction(action: $0) }
    self.publisher = message.publisher
    self.channel = message.channel
    self.subscription = message.subscription
    self.published = message.published
    self.metadata = if let value = message.metadata { KMPAnyJSON(value.codableValue) } else { nil }
    self.messageType = message.messageType.rawValue
    self.error = message.error
  }

  @objc public let payload: KMPAnyJSON
  @objc public let actions: [KMPMessageAction]
  @objc public let publisher: String?
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let published: Timetoken
  @objc public let metadata: KMPAnyJSON?
  @objc public let messageType: Int
  @objc public let error: Error?
}
