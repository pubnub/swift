//
//  DispatchQueue+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DispatchQueuePubNubTests: XCTestCase {
  private let testQueueLabel = "Test label"

  func test_CurrentLabel_WhenExecutingOnNamedQueue_ReturnsQueueLabel() {
    let queue = DispatchQueue(label: testQueueLabel)

    queue.sync {
      XCTAssertEqual(DispatchQueue.currentLabel, testQueueLabel)
    }
  }
}
