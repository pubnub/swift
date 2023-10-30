//
//  OperationQueue+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class OperationQueuePubNubTests: XCTestCase {
  func testOperationQueue_CustomInit() {
    let queue = DispatchQueue(label: "testQueue")
    let name = "Test Operation Queue"
    let isSuspended = true
    let qos = QualityOfService.default
    let maxConcurrency = 1

    let operationQueue = OperationQueue(qualityOfService: qos,
                                        maxConcurrentOperationCount: maxConcurrency,
                                        underlyingQueue: queue,
                                        name: name,
                                        startSuspended: isSuspended)

    XCTAssertEqual(operationQueue.qualityOfService, .default)
    XCTAssertEqual(operationQueue.maxConcurrentOperationCount, maxConcurrency)
    XCTAssertEqual(operationQueue.underlyingQueue, queue)
    XCTAssertEqual(operationQueue.name, name)
    XCTAssertEqual(operationQueue.isSuspended, isSuspended)
  }
}
