//
//  ConstantsTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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
#if os(iOS)
  let osName = "iOS"
#elseif os(watchOS)
  let osName = "watchOS"
#elseif os(tvOS)
  let osName = "tvOS"
#elseif os(macOS)
  let osName = "macOS"
#elseif os(Linux)
  let osName = "Linux"
#else
  let osName = "Unknown"
#endif

class ConstantsTests: XCTestCase {
  func testOperatingSystem() {
    XCTAssertEqual(Constant.operatingSystemName, osName)
  }

  func testOperatingSystemVersion() {
    let osVer = ProcessInfo.processInfo.operatingSystemVersion
    let verString = "\(osVer.majorVersion).\(osVer.minorVersion).\(osVer.patchVersion)"

    XCTAssertEqual(Constant.operatingSystemVersion, verString)
  }

  func testPubnubSwiftSDKName() {
    XCTAssertEqual(Constant.pubnubSwiftSDKName, "PubNubSwift")
  }

  func testPubnubSwiftSDKVersion() {
    let ver = Bundle(for: Session.self).infoDictionary?["CFBundleShortVersionString"]

    XCTAssertEqual(Constant.pubnubSwiftSDKVersion, "\(ver ?? "")")
  }

  func testAppBundleId() {
    XCTAssertEqual(Constant.appBundleId, "com.apple.dt.xctest.tool")
  }

  func testAppVersion() {
    XCTAssertEqual(Constant.appVersion, "?.?.?")
  }

  func testDefaultUserAgent() {
    var testUA = "\(Constant.appBundleId)/\(Constant.appVersion)"
    testUA = "\(testUA) (\(Constant.operatingSystemName) \(Constant.operatingSystemVersion))"
    testUA = "\(testUA) \(Constant.pubnubSwiftSDKName)/\(Constant.pubnubSwiftSDKVersion)"

    XCTAssertEqual(Constant.defaultUserAgent, testUA)
  }

  func testPNSDKQueryParameterValue() {
    var pnsdk = "\(Constant.pubnubSwiftSDKName)"
    pnsdk = "\(pnsdk)-\(Constant.operatingSystemName)"
    pnsdk = "\(pnsdk)/\(Constant.pubnubSwiftSDKVersion)"

    XCTAssertEqual(Constant.pnSDKQueryParameterValue, pnsdk)
  }

  func testMinimumSubscribeRequestTimeout() {
    XCTAssertEqual(Constant.minimumSubscribeRequestTimeout, 280)
  }
}
