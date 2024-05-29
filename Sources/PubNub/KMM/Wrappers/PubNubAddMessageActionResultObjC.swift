//
//  PubNubAddMessageActionResultObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubAddMessageActionResultObjC : NSObject {
  @objc public let type: String
  @objc public let value: String
  @objc public let messageTimetoken: Timetoken
  
  init(type: String, value: String, messageTimetoken: Timetoken) {
    self.type = type
    self.value = value
    self.messageTimetoken = messageTimetoken
  }
}
