//
//  PubNub+Integration.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import PubNubSDK
import XCTest

// MARK: - PubNub

extension PubNub {
  func publishWithMessageAction(
    channel: String,
    message: JSONCodable,
    actionType: String,
    actionValue: String,
    shouldStore: Bool? = nil,
    storeTTL: Int? = nil,
    meta: JSONCodable? = nil,
    shouldCompress: Bool = false,
    completion: ((Result<PubNubMessageAction, Error>) -> Void)?
  ) {
    publish(
      channel: channel,
      message: message,
      shouldStore: shouldStore,
      storeTTL: storeTTL,
      meta: meta,
      shouldCompress: shouldCompress
    ) { result in
      switch result {
      case let .success(messageTimetoken):
        self.addMessageAction(
          channel: channel,
          type: actionType, value: actionValue,
          messageTimetoken: messageTimetoken,
          completion: completion
        )
      case let .failure(error):
        completion?(.failure(error))
      }
    }
  }

  func subscribeSynchronously(
    to channels: [String],
    and channelGroups: [String] = [],
    withPresence: Bool = false,
    timeout: TimeInterval = 10.0
  ) {
    let expectation = XCTestExpectation(description: "Subscribe synchronously")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 1
    
    onConnectionStateChange = { newStatus in 
      if newStatus == .connected {
        expectation.fulfill()
      }
    }
    subscribe(
      to: channels,
      and: channelGroups,
      withPresence: withPresence
    )
    
    let result = XCTWaiter.wait(
      for: [expectation],
      timeout: timeout
    )
    
    if result != .completed {
      XCTFail("Subscribe operation timed out")
    }
  }
}

// MARK: - Random string generator

func randomString(length: Int = 6) -> String {
  let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return "swift-" + String((0..<length).compactMap { _ in characters.randomElement() })
}
