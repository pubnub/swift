//
//  URLRequest+PubNubTests.swift
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

  func testHeaders_Get() {
    guard let url = URL(string: "https://example.com") else {
      return XCTFail("Failed to unwrap url string")
    }
    var request = URLRequest(url: url)

    let dictionary = [
      "key": "value",
      "otherKey": "otherValue"
    ]

    request.allHTTPHeaderFields = dictionary
    let headers = HTTPHeaders(dictionary)

    XCTAssertEqual(request.headers.allHTTPHeaderFields,
                   headers.allHTTPHeaderFields)
  }

  func testHeaders_GetNil() {
    guard let url = URL(string: "https://example.com") else {
      return XCTFail("Failed to unwrap url string")
    }
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = nil

    XCTAssertEqual(request.headers, [])
  }

  func testHeaders_Set() {
    guard let url = URL(string: "https://example.com") else {
      return XCTFail("Failed to unwrap url string")
    }
    var request = URLRequest(url: url)

    let dictionary = [
      "key": "value",
      "otherKey": "otherValue"
    ]
    let headers = HTTPHeaders(dictionary)

    request.headers = headers

    XCTAssertEqual(request.allHTTPHeaderFields, dictionary)
  }
}
