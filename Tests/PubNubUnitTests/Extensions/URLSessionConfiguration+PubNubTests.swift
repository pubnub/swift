//
//  URLSessionConfiguration+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class URLSessionConfigurationPubNubTests: XCTestCase {
  func test_PubNubConfiguration_WhenAccessed_ReturnsDefaultHeaders() {
    let config = URLSessionConfiguration.pubnub

    let defaultHeaders = [
      Constant.acceptEncodingHeaderKey: Constant.defaultAcceptEncodingHeader,
      Constant.userAgentHeaderKey: Constant.defaultUserAgentHeader
    ]

    XCTAssertEqual(config.headers, defaultHeaders)
  }

  func test_SubscriptionConfiguration_WhenAccessed_ReturnsCorrectHeadersAndTimeout() {
    let config = URLSessionConfiguration.subscription

    let defaultHeaders = [
      Constant.acceptEncodingHeaderKey: Constant.defaultAcceptEncodingHeader,
      Constant.userAgentHeaderKey: Constant.defaultUserAgentHeader
    ]

    var defaultTimeout = Constant.minimumSubscribeRequestTimeout

    defaultTimeout += URLSessionConfiguration
      .default.timeoutIntervalForRequest

    XCTAssertEqual(config.headers, defaultHeaders)
    XCTAssertEqual(config.timeoutIntervalForRequest, defaultTimeout)
    XCTAssertEqual(config.httpMaximumConnectionsPerHost, 1)
  }

  func test_Headers_WhenSetWithValues_ReturnsSameValues() {
    let config = URLSessionConfiguration.default
    let additionalHeaders = [
      Constant.acceptEncodingHeaderKey: Constant.defaultAcceptEncodingHeader
    ]

    config.headers = additionalHeaders

    XCTAssertEqual(config.headers, additionalHeaders)
  }

  func test_Headers_WhenNoHeadersSet_ReturnsEmptyDictionary() {
    let config = URLSessionConfiguration.default

    XCTAssertEqual(config.headers, [:])
  }
}
