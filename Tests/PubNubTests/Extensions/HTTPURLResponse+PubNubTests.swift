//
//  HTTPURLResponse+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class HTTPURLResponsePubNubTests: XCTestCase {
  let url: URL! = URL(string: "https://example.com")

  func testIsSuccessful_True() {
    guard let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: "1.2",
      headerFields: nil
    ) else {
      XCTFail("HTTPURLResponse was nil ")
      return
    }

    XCTAssertTrue(response.isSuccessful)
  }

  func testIsSuccessful_False() {
    guard let response = HTTPURLResponse(
      url: url,
      statusCode: 300,
      httpVersion: "1.2",
      headerFields: nil
    ) else {
      XCTFail("HTTPURLResponse was nil ")
      return
    }

    XCTAssertFalse(response.isSuccessful)
  }

  func testSuccessfulStatusCodes() {
    XCTAssertEqual(HTTPURLResponse.successfulStatusCodes, 200 ..< 300)
  }
}
