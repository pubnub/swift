//
//  ConstantsTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
    let ver = Bundle(for: HTTPSession.self).infoDictionary?["CFBundleShortVersionString"]

    XCTAssertEqual(Constant.pubnubSwiftSDKVersion, "\(ver ?? "")")
  }

  func testAppBundleId() {
    XCTAssertEqual(Constant.appBundleId, "com.apple.dt.xctest.tool")
  }

  func testAppVersion() {
    XCTAssertNotEqual(Constant.appVersion, "?.?.?")
  }

  func testDefaultUserAgent() {
    var testUA = "\(Constant.appBundleId)/\(Constant.appVersion)"
    testUA = "\(testUA) (\(Constant.operatingSystemName) \(Constant.operatingSystemVersion))"
    testUA = "\(testUA) \(Constant.pubnubSwiftSDKName)/\(Constant.pubnubSwiftSDKVersion)"

    XCTAssertEqual(Constant.defaultUserAgentHeader, testUA)
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

  func testErrorDescription_AnyJSON_StringCreationFailure() {
    XCTAssertEqual(ErrorDescription.stringEncodingFailure,
                   "`String(data:encoding:)` returned nil when converting JSON Data to a `String`")
  }

  func testErrorDescription_DecodingError_RootLeve() {
    XCTAssertEqual(ErrorDescription.rootLevelDecoding,
                   "AnyJSON could not decode invalid root-level JSON object")
  }

  func testErrorDescription_DecodingError_KeyedContainer() {
    XCTAssertEqual(ErrorDescription.keyedContainerDecoding,
                   "AnyJSON could not decode value inside `KeyedDecodingContainer`")
  }

  func testErrorDescription_DecodingError_UnkeyedContainer() {
    XCTAssertEqual(ErrorDescription.unkeyedContainerDecoding,
                   "AnyJSON could not decode value inside `UnkeyedDecodingContainer`")
  }
}
