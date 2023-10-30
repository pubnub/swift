//
//  DispatchQueue+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class DispatchQueuePubNubTests: XCTestCase {
  func testCurrentLabel() {
    let queue = DispatchQueue(label: "test label")

    queue.sync {
      XCTAssertEqual(DispatchQueue.currentLabel, "test label")
    }
  }
}
