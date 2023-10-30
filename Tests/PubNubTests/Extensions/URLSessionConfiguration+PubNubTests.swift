//
//  URLSessionConfiguration+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class URLSessionConfigurationPubNubTests: XCTestCase {
  func testPubNubConfiguration() {
    let config = URLSessionConfiguration.pubnub

    let defaultHeaders = [
      Constant.acceptEncodingHeaderKey: Constant.defaultAcceptEncodingHeader,
      Constant.userAgentHeaderKey: Constant.defaultUserAgentHeader
    ]

    XCTAssertEqual(config.headers, defaultHeaders)
  }

  func testSubscriptionConfiguration() {
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

  func testHeaders_GetSetHeaders() {
    let config = URLSessionConfiguration.default
    let additionalHeaders = [
      Constant.acceptEncodingHeaderKey: Constant.defaultAcceptEncodingHeader
    ]

    config.headers = additionalHeaders

    XCTAssertEqual(config.headers, additionalHeaders)
  }

  func testHeaders_GetNil() {
    let config = URLSessionConfiguration.default

    XCTAssertEqual(config.headers, [:])
  }
}
