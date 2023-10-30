//
//  PubNubPushTargetTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class PubNubPushTargetTests: XCTestCase {
  func test_ExcludedDeviceTokensAreUppercased() {
    let excludedDevices = ["fafb3456", "7654egh"]
    let message = testPushMessage(with: .init(topic: "com.pubnub", environment: .production, excludedDevices: excludedDevices))
    
    let encodedData = try? Constant.jsonEncoder.encode(message)
    let encodedStr = String(data: encodedData ?? Data(), encoding: .utf8) ?? ""
    let expectedExclDevices = excludedDevices.map { $0.uppercased() }.jsonStringify ?? ""
    
    XCTAssertEqual(retrieveExcludedDevicesValue(from: encodedStr), expectedExclDevices)
  }
  
  func test_ExcludedDeviceTokensAreNotSentIfNotProvided() {
    let message = testPushMessage(with: .init(topic: "com.pubnub", environment: .production))
    let encodedData = try? Constant.jsonEncoder.encode(message)
    let encodedStr = String(data: encodedData ?? Data(), encoding: .utf8) ?? ""
    
    XCTAssertEqual(retrieveExcludedDevicesValue(from: encodedStr), nil)
  }
}

fileprivate func testPushMessage(with target: PubNubPushTarget) -> PubNubAPNSPayload {
  PubNubAPNSPayload(
    aps: APSPayload(alert: .object(.init(title: "Apple Message")), badge: 1, sound: .string("default")),
    pubnub: [.init(targets: [target], collapseID: "SwiftSDK")],
    payload: "Push Message from PubNub Swift SDK"
  )
}

fileprivate func retrieveExcludedDevicesValue(from string: String) -> String? {
  let regex = try! NSRegularExpression(pattern: "(?<=\"excluded_devices\":)(.*?)](=?)")
  let regexMatch = regex.matches(in: string, range: NSRange(location: 0, length: string.count)).first
  
  if let regexMatch = regexMatch {
    let startIdx = string.index(string.startIndex, offsetBy: regexMatch.range.location)
    let endIdx = string.index(startIdx, offsetBy: regexMatch.range.length - 1)
    return String(string[startIdx...endIdx])
  } else {
    return nil
  }
}
