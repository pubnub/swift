//
//  PubNubConfigurationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class PubNubConfigurationTests: XCTestCase {
  let publishDictionaryKey = "PubNubPubKey"
  let subscribeDictionaryKey = "PubNubSubKey"

  let plistPublishKeyValue = "demo"
  let plistSubscribeKeyValue = "demo"

  let publishKeyValue = "NotARealPublishKey"
  let subscribeKeyValue = "NotARealSubscribeKey"

  // Info.plist for the PubNubTests Target Bundle
  let testsBundle = Bundle(for: PubNubConfigurationTests.self)

  func testDefault() {
    let config = PubNubConfiguration(publishKey: nil, subscribeKey: plistSubscribeKeyValue, userId: UUID().uuidString)

    XCTAssertNil(config.publishKey)
    XCTAssertEqual(config.subscribeKey, plistSubscribeKeyValue)
    XCTAssertNil(config.cryptoModule)
    XCTAssertNil(config.authKey)
    XCTAssertNotNil(config.uuid)
    XCTAssertEqual(config.useSecureConnections, true)
    XCTAssertEqual(config.origin, "ps.pndsn.com")
    XCTAssertEqual(config.durationUntilTimeout, 300)
    XCTAssertEqual(config.heartbeatInterval, 0)
    XCTAssertEqual(config.supressLeaveEvents, false)
    XCTAssertEqual(config.requestMessageCountThreshold, 100)
  }

  func testDurationUntilTimeout_Floor() {
    var config = PubNubConfiguration(publishKey: nil, subscribeKey: "", userId: UUID().uuidString)
    config.durationUntilTimeout = 0

    XCTAssertEqual(config.durationUntilTimeout, 20)
  }

  func testInit_Bundle() {
    let config = PubNubConfiguration(from: testsBundle)

    XCTAssertEqual(config.publishKey, plistPublishKeyValue)
    XCTAssertEqual(config.subscribeKey, plistSubscribeKeyValue)
  }

  func testInit_RawValues() {
    let config = PubNubConfiguration(
      publishKey: publishKeyValue,
      subscribeKey: subscribeKeyValue,
      userId: UUID().uuidString
    )

    XCTAssertEqual(config.publishKey, publishKeyValue)
    XCTAssertEqual(config.subscribeKey, subscribeKeyValue)
  }

  func testConfigurations_DifferentCryptoModules() {
    let firstConfig = PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId,
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "someKey")
    )
    let secondConfig = PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: PubNubConfiguration(from: testsBundle).userId,
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "anotherKey")
    )

    XCTAssertNotEqual(firstConfig.hashValue, secondConfig.hashValue)
  }
}
