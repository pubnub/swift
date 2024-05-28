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
  @objc public var channels: [String: UInt64]

  init(channels: [String: UInt64]) {
    self.channels = channels
  }
}
