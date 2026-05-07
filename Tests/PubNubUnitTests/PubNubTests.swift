//
//  PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class PubNubTests: XCTestCase {
  let testBundle = Bundle(for: PubNubTests.self)

  func testInit_CustomConfig() {
    let config = TestPubNubFactory.makeConfig()
    let pubnub = PubNub(configuration: config)

    XCTAssertEqual(pubnub.configuration, config)
  }
}
