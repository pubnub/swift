//
//  SubscribeRequestTests.swift
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

import Foundation
import XCTest

@testable import PubNub

class SubscribeRequestTests: XCTestCase {
  func test_SubscribeRequestWithoutRetryPolicy() {
    let config = PubNubConfiguration(
      publishKey: "pK",
      subscribeKey: "sK",
      userId: "UID"
    )
    let request = SubscribeRequest(
      configuration: config,
      channels: ["channel-1", "channel-2"],
      groups: [],
      session: HTTPSession(configuration: .subscription),
      sessionResponseQueue: .main
    )
    
    let urlResponse = HTTPURLResponse(statusCode: 500)
    let error = SubscribeError(underlying: PubNubError(.connectionFailure), urlResponse: urlResponse)
    
    XCTAssertNil(request.computeReconnectionDelay(dueTo: error, with: 0))
  }
  
  func test_SubscribeRequestWithRetryPolicy() {
    let config = PubNubConfiguration(
      publishKey: "pK",
      subscribeKey: "sK",
      userId: "UID",
      automaticRetry: AutomaticRetry(retryLimit: 2, policy: .linear(delay: 3.0))
    )
    let request = SubscribeRequest(
      configuration: config,
      channels: ["channel-1", "channel-2"],
      groups: [],
      session: HTTPSession(configuration: .subscription),
      sessionResponseQueue: .main
    )
    
    let urlError = URLError(.cannotFindHost)
    let subscribeError = SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
    
    XCTAssertEqual(request.computeReconnectionDelay(dueTo: subscribeError, with: 0), 3)
    XCTAssertEqual(request.computeReconnectionDelay(dueTo: subscribeError, with: 1), 3.0)
    XCTAssertEqual(request.computeReconnectionDelay(dueTo: subscribeError, with: 2), nil)
  }
  
  func test_SubscribeRequestDoesNotRetryForNonSupportedCode() {
    let automaticRetry = AutomaticRetry(
      retryLimit: 2,
      policy: .linear(delay: 3.0),
      retryableURLErrorCodes: [.badURL]
    )
    let config = PubNubConfiguration(
      publishKey: "pK",
      subscribeKey: "sK",
      userId: "UID",
      automaticRetry: automaticRetry
    )
    let request = SubscribeRequest(
      configuration: config,
      channels: ["channel-1", "channel-2"],
      groups: [],
      session: HTTPSession(configuration: .subscription),
      sessionResponseQueue: .main
    )
    
    let urlError = URLError(.cannotFindHost)
    let subscribeError = SubscribeError(underlying: PubNubError(urlError.pubnubReason!, underlying: urlError))
    
    XCTAssertNil(request.computeReconnectionDelay(dueTo: subscribeError, with: 0))
  }
}
