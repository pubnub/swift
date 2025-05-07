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
}

// MARK: - Random string generator

func randomString(length: Int = 6, withPrefix: Bool = true) -> String {
  let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let prefix = withPrefix ? "swift-" : ""
  
  return prefix + String((0..<length).compactMap { _ in characters.randomElement() })
}

// MARK: - Helper functions

extension XCTestCase {
  func waitForCompletion<T: Any>(
    suppressErrorIfAny: Bool = false,
    timeout: TimeInterval = 10.0,
    file: StaticString = #file,
    line: UInt = #line,
    _ operation: (@escaping (Result<T, Error>) -> Void) -> Void
  ) {
    let expect = XCTestExpectation(description: "Wait for completion (\(file) \(line)")
    expect.assertForOverFulfill = true
    expect.expectedFulfillmentCount = 1
    
    operation { result in
      if case .failure(let failure) = result {
        preconditionFailure("Operation failed with error: \(failure)", file: file, line: line)
      } else {
        expect.fulfill()
      }
    }
    
    wait(
      for: [expect],
      timeout: timeout
    )
  }
}
