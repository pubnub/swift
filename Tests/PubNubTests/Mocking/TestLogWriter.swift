//
//  TestLogWriter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
@testable import PubNub

class TestSyncLogWriter: LogWriter {
  var executor: LogExecutable = LogExecutionType.sync(lock: NSRecursiveLock())
  var prefix: LogPrefix = [.all]

  var logClosure: ((String) -> Void)?

  func send(message _: String) {}
}

class TestAsyncLogWriter: LogWriter {
  var executor: LogExecutable = LogExecutionType.async(queue: DispatchQueue.global())
  var prefix: LogPrefix = [.all]

  var logClosure: ((String) -> Void)?

  func send(message _: String) {}
}
