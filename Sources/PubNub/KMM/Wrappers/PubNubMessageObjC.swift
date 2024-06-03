//
//  PubNubMessageObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubMessageObjC: NSObject {
  init(message: PubNubMessage) {
      self.payload = AnyJSONObjC(message.payload.codableValue)
    self.actions = message.actions.map { PubNubMessageActionObjC(action: $0) }
    self.publisher = message.publisher
    self.channel = message.channel
    self.subscription = message.subscription
    self.published = message.published
    self.metadata = if let metadata = message.metadata {
        AnyJSONObjC(metadata.codableValue)
    } else {
        nil
    }
    self.messageType = message.messageType.rawValue
    self.error = message.error
  }

  @objc public let payload: AnyJSONObjC
  @objc public let actions: [PubNubMessageActionObjC]
  @objc public let publisher: String?
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let published: Timetoken
  @objc public let metadata: AnyJSONObjC?
  @objc public let messageType: Int
  @objc public let error: Error?
}
