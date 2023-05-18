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
    let excludedDevices = [
      "fafb34563ce",
      "7654eghjkl"
    ]
    let pushMessage = PubNubPushMessage(
      apns: PubNubAPNSPayload(
        aps: APSPayload(
          alert: .object(.init(title: "Message")),
          badge: 2,
          sound: .string("default")
        ),
        pubnub: [.init(
          targets: [.init(topic: "com.pubnub.swift", environment: .production, excludedDevices: excludedDevices)],
          collapseID: "SwiftSDK"
        )],
        payload: "Push Message from PubNub Swift SDK"
      )
    )
    
    let encodedData = try? Constant.jsonEncoder.encode(pushMessage)
    let encodedStr = String(data: encodedData ?? Data(), encoding: .utf8) ?? ""
    
    // Retrieves a value for the "excluded_devices" key:
    let regex = try! NSRegularExpression(pattern: "(?<=\"excluded_devices\":)(.*?)](=?)")
    let regexMatch = regex.matches(in: encodedStr, range: NSRange(location: 0, length: encodedStr.count))[0]
    let startIdx = encodedStr.index(encodedStr.startIndex, offsetBy: regexMatch.range.location)
    let endIdx = encodedStr.index(startIdx, offsetBy: regexMatch.range.length - 1)
      
    XCTAssertEqual(
      String(encodedStr[startIdx...endIdx]),
      excludedDevices.map { $0.uppercased() }.jsonStringify ?? ""
    )
  }
}
