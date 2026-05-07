//
//  ConstantsTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
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
  func test_Constant_OperatingSystemName_MatchesPlatform() {
    XCTAssertEqual(Constant.operatingSystemName, osName)
  }

  func test_Constant_OperatingSystemVersion_MatchesProcessInfo() {
    let osVer = ProcessInfo.processInfo.operatingSystemVersion
    let verString = "\(osVer.majorVersion).\(osVer.minorVersion).\(osVer.patchVersion)"

    XCTAssertEqual(Constant.operatingSystemVersion, verString)
  }

  func test_Constant_PubnubSwiftSDKName_ReturnsPubNubSwift() {
    XCTAssertEqual(Constant.pubnubSwiftSDKName, "PubNubSwift")
  }

  func test_Constant_PubnubSwiftSDKVersion_MatchesBundleVersion() {
    let ver = Bundle(for: HTTPSession.self).infoDictionary?["CFBundleShortVersionString"]

    XCTAssertEqual(Constant.pubnubSwiftSDKVersion, "\(ver ?? "")")
  }

  func test_Constant_AppBundleId_ReturnsXCTestBundleId() {
    XCTAssertEqual(Constant.appBundleId, "com.apple.dt.xctest.tool")
  }

  func test_Constant_AppVersion_IsNotPlaceholder() {
    XCTAssertNotEqual(Constant.appVersion, "?.?.?")
  }

  func test_Constant_DefaultUserAgentHeader_MatchesExpectedFormat() {
    var testUA = "\(Constant.appBundleId)/\(Constant.appVersion)"
    testUA = "\(testUA) (\(Constant.operatingSystemName) \(Constant.operatingSystemVersion))"
    testUA = "\(testUA) \(Constant.pubnubSwiftSDKName)/\(Constant.pubnubSwiftSDKVersion)"

    XCTAssertEqual(Constant.defaultUserAgentHeader, testUA)
  }

  func test_Constant_PNSDKQueryParameterValue_MatchesExpectedFormat() {
    var pnsdk = "\(Constant.pubnubSwiftSDKName)"
    pnsdk = "\(pnsdk)-\(Constant.operatingSystemName)"
    pnsdk = "\(pnsdk)/\(Constant.pubnubSwiftSDKVersion)"

    XCTAssertEqual(Constant.pnSDKQueryParameterValue, pnsdk)
  }

  func test_Constant_MinimumSubscribeRequestTimeout_Returns280() {
    XCTAssertEqual(Constant.minimumSubscribeRequestTimeout, 280)
  }

  func test_ErrorDescription_StringEncodingFailure_ReturnsExpectedMessage() {
    XCTAssertEqual(
      ErrorDescription.stringEncodingFailure,
      "`String(data:encoding:)` returned nil when converting JSON Data to a `String`"
    )
  }

  func test_ErrorDescription_RootLevelDecoding_ReturnsExpectedMessage() {
    XCTAssertEqual(
      ErrorDescription.rootLevelDecoding,
      "AnyJSON could not decode invalid root-level JSON object"
    )
  }

  func test_ErrorDescription_KeyedContainerDecoding_ReturnsExpectedMessage() {
    XCTAssertEqual(
      ErrorDescription.keyedContainerDecoding,
      "AnyJSON could not decode value inside `KeyedDecodingContainer`"
    )
  }

  func test_ErrorDescription_UnkeyedContainerDecoding_ReturnsExpectedMessage() {
    XCTAssertEqual(
      ErrorDescription.unkeyedContainerDecoding,
      "AnyJSON could not decode value inside `UnkeyedDecodingContainer`"
    )
  }
}
