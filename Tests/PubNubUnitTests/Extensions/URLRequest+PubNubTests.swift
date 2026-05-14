//
//  URLRequest+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class URLRequestPubNubTests: XCTestCase {
  func test_Method_WithValidHTTPMethod_ReturnsMatchingEnum() throws {
    let url = try XCTUnwrap(URL(string: "https://example.com"))

    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    XCTAssertEqual(request.method, .post)
  }

  func test_Method_WithUnknownHTTPMethod_ReturnsNil() throws {
    let url = try XCTUnwrap(URL(string: "https://example.com"))

    var request = URLRequest(url: url)
    request.httpMethod = "Something"

    XCTAssertNil(request.method)
  }

  func test_Method_WithNilHTTPMethod_ReturnsGet() throws {
    let url = try XCTUnwrap(URL(string: "https://example.com"))

    var request = URLRequest(url: url)
    request.httpMethod = nil

    XCTAssertEqual(request.method, .get)
  }

  func test_Method_WhenSetViaProperty_UpdatesCorrectly() throws {
    let url = try XCTUnwrap(URL(string: "https://example.com"))

    var request = URLRequest(url: url)
    request.method = .post

    XCTAssertEqual(request.method, .post)
  }
}
