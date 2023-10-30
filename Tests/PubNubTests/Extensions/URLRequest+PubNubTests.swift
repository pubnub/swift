//
//  URLRequest+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class URLRequestPubNubTests: XCTestCase {
  func testmethod() {
    guard let url = URL(string: "https://example.com") else {
      return XCTFail("Failed to unwrap url string")
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    XCTAssertEqual(request.method, .post)
  }

  func testMethod_UnknownMethod() {
    guard let url = URL(string: "https://example.com") else {
      return XCTFail("Failed to unwrap url string")
    }
    var request = URLRequest(url: url)
    request.httpMethod = "Something"

    XCTAssertNil(request.method)
  }

  func testMethod_DefaultMethod() {
    guard let url = URL(string: "https://example.com") else {
      return XCTFail("Failed to unwrap url string")
    }
    var request = URLRequest(url: url)
    request.httpMethod = nil

    XCTAssertEqual(request.method, .get)
  }

  func testMethod_Set() {
    guard let url = URL(string: "https://example.com") else {
      return XCTFail("Failed to unwrap url string")
    }
    var request = URLRequest(url: url)
    request.method = .post

    XCTAssertEqual(request.method, .post)
  }
}
