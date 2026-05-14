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
  func test_CurrentLabel_WhenExecutingOnNamedQueue_ReturnsQueueLabel() {
    let queue = DispatchQueue(label: "Test label")

    queue.sync {
      XCTAssertEqual(DispatchQueue.currentLabel, "Test label")
    }
  }
}
