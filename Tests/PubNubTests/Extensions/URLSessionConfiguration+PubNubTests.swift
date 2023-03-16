//
//  URLSessionConfiguration+PubNubTests.swift
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
