//
//  Error+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class ErrorPubNubTests: XCTestCase {
  func test_PubNubError_WhenCastingPubNubError_ReturnsNonNil() {
    let error: Error = PubNubError(.unknown)

    XCTAssertNotNil(error.pubNubError)
    XCTAssertNil(error.urlError)
  }

  func test_URLError_WhenCastingURLError_ReturnsNonNil() {
    let error: Error = URLError(.unknown)

    XCTAssertNotNil(error.urlError)
    XCTAssertNil(error.pubNubError)
  }
}
