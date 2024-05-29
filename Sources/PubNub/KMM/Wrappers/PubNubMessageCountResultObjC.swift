//
//  PubNubMessageCountResultObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubMessageCountResultObjC: NSObject {
  @objc public let channels: [String: Timetoken]

  init(channels: [String: Timetoken]) {
    self.channels = channels
  }
}
