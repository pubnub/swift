//
//  AnyJSON+CodableTests.swift
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

class AnyJSONCodableTests: XCTestCase {
  func testExample() {
    let json: AnyJSON = ["key1": 1.1,
                         "key2": ["sub", 1, ["subsub"]],
                         "key3": Date()]

    guard let data = try? json.jsonEncodedData() else {
      return XCTFail("Could not turn AnyJSON into Data")
    }

    guard let jason = try? json.decode(AnyJSON.self) else {
      return XCTFail("Yo Dawg...")
    }

    XCTAssertEqual(json, jason)

    guard let json2 = try? JSONDecoder().decode(AnyJSON.self, from: data) else {
      return XCTFail("Could not decode AnyJSON from Data")
    }

    XCTAssertEqual(json, json2)
  }

  func testEquals() {
    let testJSON: AnyJSON = ["x": 1, "y": []]
    let equalJSON: AnyJSON = ["x": 1, "y": []]

    XCTAssertEqual(testJSON, equalJSON)
  }

  func testSubscriptionBuilder() {
    let data = ImportJSON.file("subscription")

    guard let subResponse = try? JSONDecoder().decode(SubscriptionResponsePayload.self, from: data) else {
      return XCTFail("Decoder value of JSON Data unwrapped to nil")
    }

    XCTAssertEqual(subResponse.messages.first?.payload, ["message": "Hello"])
  }
}
