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
    let dependencyContainer = DependencyContainer(configuration: config)
    let first = dependencyContainer.subscriptionSession
    let second = dependencyContainer.subscriptionSession

    XCTAssertEqual(first.uuid, second.uuid)
  }

  func testMutlipleInstances() {
    let config = PubNubConfiguration(
      publishKey: nil,
      subscribeKey: "FakeKey",
      userId: UUID().uuidString
    )
    let newConfig = PubNubConfiguration(
      publishKey: nil,
      subscribeKey: "OtherKey",
      userId: UUID().uuidString,
      authKey: "SomeNewKey"
    )
    
    let dependencyContainer = DependencyContainer(configuration: config)
    let nextDependencyContainer = DependencyContainer(configuration: config)
    let first = dependencyContainer.subscriptionSession
    let third = nextDependencyContainer.subscriptionSession

    XCTAssertNotEqual(first.uuid, third.uuid)
  }
}
