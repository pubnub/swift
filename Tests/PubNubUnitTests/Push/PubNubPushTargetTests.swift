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
    let target = PubNubPushTarget(topic: "com.pubnub", environment: .production, excludedDevices: ["fafb3456", "7654egh"])
    let data = try Constant.jsonEncoder.encode(target)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    let excludedDevices = try XCTUnwrap(json["excluded_devices"] as? [String])
    XCTAssertEqual(excludedDevices, ["FAFB3456", "7654EGH"])
  }

  func test_ExcludedDeviceTokensAreNotSentIfNotProvided() throws {
    let target = PubNubPushTarget(topic: "com.pubnub", environment: .production)
    let data = try Constant.jsonEncoder.encode(target)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertNil(json["excluded_devices"])
  }
}
