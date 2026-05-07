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
  func test_ExcludedDeviceTokensAreUppercased() {
    let excludedDevices = ["fafb3456", "7654egh"]
    let message = testPushMessage(with: .init(topic: "com.pubnub", environment: .production, excludedDevices: excludedDevices))

    let encodedData = try? Constant.jsonEncoder.encode(message)
    let encodedStr = String(data: encodedData ?? Data(), encoding: .utf8) ?? ""
    let expectedExclDevices = excludedDevices.map { $0.uppercased() }.jsonStringify ?? ""

    XCTAssertEqual(try retrieveExcludedDevicesValue(from: encodedStr), expectedExclDevices)
  }

  func test_ExcludedDeviceTokensAreNotSentIfNotProvided() throws {
    let message = testPushMessage(with: .init(topic: "com.pubnub", environment: .production))
    let encodedData = try? Constant.jsonEncoder.encode(message)
    let encodedStr = String(data: encodedData ?? Data(), encoding: .utf8) ?? ""

    XCTAssertEqual(try retrieveExcludedDevicesValue(from: encodedStr), nil)
  }
}

private func testPushMessage(with target: PubNubPushTarget) -> PubNubAPNSPayload {
  PubNubAPNSPayload(
    aps: APSPayload(alert: .object(.init(title: "Apple Message")), badge: 1, sound: .string("default")),
    pubnub: [.init(targets: [target], collapseID: "SwiftSDK")],
    payload: "Push Message from PubNub Swift SDK"
  )
}

private func retrieveExcludedDevicesValue(from string: String) throws -> String? {
  let regex = try NSRegularExpression(pattern: "(?<=\"excluded_devices\":)(.*?)](=?)")
  let nsRange = NSRange(string.startIndex..., in: string)

  guard
    let regexMatch = regex.matches(in: string, range: nsRange).first,
    let range = Range(regexMatch.range, in: string)
  else {
    return nil
  }

  return String(string[range])
}
