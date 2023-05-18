//
//  PubNubPushTargetTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
