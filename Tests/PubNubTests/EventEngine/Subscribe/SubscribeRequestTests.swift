//
//  SubscribeRequestTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest

@testable import PubNub

class SubscribeRequestTests: XCTestCase {
  func test_SubscribeRequestWithoutRetryPolicy() {
    let config = PubNubConfiguration(
      publishKey: "publishKey",
      subscribeKey: "subscribeKey",
      userId: "userId"
    )
    let request = SubscribeRequest(
      configuration: config,
      channels: ["channel1", "channel1-pnpres", "channel2"],
      groups: ["g1", "g2", "g2-pnpres"],
      channelStates: [:],
      session: HTTPSession(configuration: .subscription),
      sessionResponseQueue: .main
    )
    
    let urlResponse = HTTPURLResponse(statusCode: 500)!
    let error = PubNubError(.connectionFailure, affected: [.response(urlResponse)])
    
    XCTAssertNil(request.reconnectionDelay(dueTo: error, retryAttempt: 0))
  }
  
  func test_SubscribeRequestDoesNotRetryForNonSupportedCode() {
    let automaticRetry = AutomaticRetry(
      retryLimit: 2,
      policy: .linear(delay: 3.0),
      retryableURLErrorCodes: [.badURL]
    )
    let config = PubNubConfiguration(
      publishKey: "publishKey",
      subscribeKey: "subscribeKey",
      userId: "userId",
      automaticRetry: automaticRetry
    )
    let request = SubscribeRequest(
      configuration: config,
      channels: ["channel1", "channel1-pnpres", "channel2"],
      groups: ["g1", "g2", "g2-pnpres"],
      channelStates: [:],
      session: HTTPSession(configuration: .subscription),
      sessionResponseQueue: .main
    )
    
    let urlError = URLError(.cannotFindHost)
    let pubNubError = PubNubError(urlError.pubnubReason!, underlying: urlError)
    
    XCTAssertNil(request.reconnectionDelay(dueTo: pubNubError, retryAttempt: 0))
  }
}
