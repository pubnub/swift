//
//  PubNubPushTargetTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

class PubNubPushTargetTests: XCTestCase {
  func test_ExcludedDeviceTokensAreUppercased() throws {
    let excludedDevices = ["fafb3456", "7654egh"]
    let message = testPushMessage(with: .init(topic: "com.pubnub", environment: .production, excludedDevices: excludedDevices))

    let encodedData = try Constant.jsonEncoder.encode(message)
    let encodedStr = try XCTUnwrap(String(bytes: encodedData, encoding: .utf8))
    let expectedExclDevices = try XCTUnwrap(excludedDevices.map { $0.uppercased() }.jsonStringify)

    XCTAssertEqual(try retrieveExcludedDevicesValue(from: encodedStr), expectedExclDevices)
  }

  func test_ExcludedDeviceTokensAreNotSentIfNotProvided() throws {
    let message = testPushMessage(with: .init(topic: "com.pubnub", environment: .production))
    let encodedData = try Constant.jsonEncoder.encode(message)
    let encodedStr = try XCTUnwrap(String(bytes: encodedData, encoding: .utf8))

    XCTAssertEqual(try retrieveExcludedDevicesValue(from: encodedStr), nil)
  }
}

private extension PubNubPushTargetTests {
  func testPushMessage(with target: PubNubPushTarget) -> PubNubAPNSPayload {
    PubNubAPNSPayload(
      aps: APSPayload(alert: .object(.init(title: "Apple Message")), badge: 1, sound: .string("default")),
      pubnub: [.init(targets: [target], collapseID: "SwiftSDK")],
      payload: "Push Message from PubNub Swift SDK"
    )
  }

  func retrieveExcludedDevicesValue(from string: String) throws -> String? {
    guard let data = string.data(using: .utf8) else { return nil }
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let pnPush = json?["pn_push"] as? [[String: Any]],
          let firstConfig = pnPush.first,
          let targets = firstConfig["targets"] as? [[String: Any]],
          let firstTarget = targets.first else {
      return nil
    }
    guard let excludedDevices = firstTarget["excluded_devices"] else { return nil }
    let encodedData = try JSONSerialization.data(withJSONObject: excludedDevices)
    return String(data: encodedData, encoding: .utf8)
  }
}
