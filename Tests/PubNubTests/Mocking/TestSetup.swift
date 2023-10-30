//
//  TestSetup.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import PubNub

/// Anything that needs to be executed once can be placed inside the init
class TestSetup: NSObject {
  override init() {
    PubNub.logLog.levels = [.none]
    PubNub.logLog.writers = []

    PubNub.log.levels = [.all]
    PubNub.log.writers = [TestSyncLogWriter(), TestAsyncLogWriter()]
  }
}
