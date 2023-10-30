//
//  PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class PubNubTests: XCTestCase {
  let testBundle = Bundle(for: PubNubTests.self)
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)

  func testInit_CustomConfig() {
    let pubnub = PubNub(configuration: config)

    XCTAssertEqual(pubnub.configuration, config)
  }
}
