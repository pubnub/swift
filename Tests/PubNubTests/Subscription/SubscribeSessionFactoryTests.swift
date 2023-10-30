//
//  SubscribeSessionFactoryTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class SubscribeSessionFactoryTests: XCTestCase {
  func testLoggingSameInstance() {
    let config = PubNubConfiguration(publishKey: nil, subscribeKey: "FakeKey", userId: UUID().uuidString)
    let first = SubscribeSessionFactory.shared.getSession(from: config)
    let second = SubscribeSessionFactory.shared.getSession(from: config)

    XCTAssertEqual(first.uuid, second.uuid)
  }

  func testMutlipleInstances() {
    let config = PubNubConfiguration(publishKey: nil, subscribeKey: "FakeKey", userId: UUID().uuidString)
    var newConfig = PubNubConfiguration(publishKey: nil, subscribeKey: "OtherKey", userId: UUID().uuidString)
    newConfig.authKey = "SomeNewKey"

    let first = SubscribeSessionFactory.shared.getSession(from: config)
    let third = SubscribeSessionFactory.shared.getSession(from: newConfig)

    XCTAssertNotEqual(first.uuid, third.uuid)
  }
}
