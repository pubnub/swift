//
//  HTTPURLResponse+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class HTTPURLResponsePubNubTests: XCTestCase {

  func test_IsSuccessful_WithStatus200_ReturnsTrue() throws {
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: try XCTUnwrap(URL(string: "https://example.com")),
        statusCode: 200,
        httpVersion: "1.2",
        headerFields: nil
      )
    )

    XCTAssertTrue(response.isSuccessful)
  }

  func test_IsSuccessful_WithStatus300_ReturnsFalse() throws {
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: try XCTUnwrap(URL(string: "https://example.com")),
        statusCode: 300,
        httpVersion: "1.2",
        headerFields: nil
      )
    )

    XCTAssertFalse(response.isSuccessful)
  }

  func test_SuccessfulStatusCodes_ReturnsRange200To299() {
    XCTAssertEqual(HTTPURLResponse.successfulStatusCodes, 200 ..< 300)
  }
}
