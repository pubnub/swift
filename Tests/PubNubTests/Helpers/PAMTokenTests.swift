//
//  PAMTokenTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

// swiftlint:disable line_length

class PAMTokenTests: XCTestCase {
  let config = PubNubConfiguration(
    publishKey: "",
    subscribeKey: "",
    userId: "tester"
  )
  let eeEnabledConfig = PubNubConfiguration(
    publishKey: "",
    subscribeKey: "",
    userId: "tester",
    enableEventEngine: true
  )
  static let allPermissionsToken = "qEF2AkF0GmEI03xDdHRsGDxDcmVzpURjaGFuoWljaGFubmVsLTEY70NncnChb2NoYW5uZWxfZ3JvdXAtMQVDdXNyoENzcGOgRHV1aWShZnV1aWQtMRhoQ3BhdKVEY2hhbqFtXmNoYW5uZWwtXFMqJBjvQ2dycKF0XjpjaGFubmVsX2dyb3VwLVxTKiQFQ3VzcqBDc3BjoER1dWlkoWpedXVpZC1cUyokGGhEbWV0YaBEdXVpZHR0ZXN0LWF1dGhvcml6ZWQtdXVpZENzaWdYIPpU-vCe9rkpYs87YUrFNWkyNq8CVvmKwEjVinnDrJJc"
}

// MARK: Scanner

extension PAMTokenTests {
  func testParseToken() {
    let pubnub = PubNub(configuration: config)
    let token = pubnub.parse(token: PAMTokenTests.allPermissionsToken)
    
    guard let resources = token?.resources else {
      return XCTAssert(false, "'resources' is missing")
    }
    guard let patterns = token?.patterns else {
      return XCTAssert(false, "'patterns' is missing")
    }

    XCTAssertEqual(token?.authorizedUUID, "test-authorized-uuid")
    XCTAssertEqual(resources.channels.count, 1)
    XCTAssertEqual(resources.groups.count, 1)
    XCTAssertEqual(resources.uuids.count, 1)
    XCTAssertEqual(patterns.channels.count, 1)
    XCTAssertEqual(patterns.groups.count, 1)
    XCTAssertEqual(patterns.uuids.count, 1)

    XCTAssertEqual(resources.channels["channel-1"], PAMPermission.all)
    XCTAssertEqual(resources.groups["channel_group-1"], [PAMPermission.read, PAMPermission.manage])
    XCTAssertEqual(resources.uuids["uuid-1"], [PAMPermission.delete, PAMPermission.get, PAMPermission.update])
    XCTAssertEqual(patterns.channels["^channel-\\S*$"], PAMPermission.all)
    XCTAssertEqual(patterns.groups["^:channel_group-\\S*$"], [PAMPermission.read, PAMPermission.manage])
    XCTAssertEqual(patterns.uuids["^uuid-\\S*$"], [PAMPermission.delete, PAMPermission.get, PAMPermission.update])
  }

  func testSetToken() {
    for config in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(config.enableEventEngine)") { _ in
        let pubnub = PubNub(configuration: config)
        pubnub.set(token: "access-token")

        XCTAssertEqual(pubnub.configuration.authToken, "access-token")
        XCTAssertEqual(pubnub.subscription.configuration.authToken, "access-token")
      }
    }
  }

  func testChangeToken() {
    for config in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(config.enableEventEngine)") { _ in
        let pubnub = PubNub(configuration: config)
        pubnub.set(token: "access-token")
        pubnub.set(token: "access-token-updated")

        XCTAssertEqual(pubnub.configuration.authToken, "access-token-updated")
        XCTAssertEqual(pubnub.subscription.configuration.authToken, "access-token-updated")
      }
    }
  }

  // swiftlint:enable line_length
}
