//
//  EndpointTests.swift
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

class EndpointTests: XCTestCase {
  // MARK: - CustomStringConvertible

  func testCustomStringConvertible_Time() {
    let time = Endpoint.time
    XCTAssertEqual(time.description, "Time")
  }

  func testCustomStringConvertible_Publish() {
    let publish = Endpoint.publish(message: AnyJSON([1]), channel: "Test", shouldStore: nil, ttl: nil, meta: nil)
    XCTAssertEqual(publish.description, "Publish")
  }

  func testCustomStringConvertible_CompressedPublish() {
    let publish = Endpoint.publish(message: AnyJSON([1]), channel: "Test", shouldStore: nil, ttl: nil, meta: nil)
    XCTAssertEqual(publish.description, "Publish")
  }

  func testCustomStringConvertible_Fire() {
    let fire = Endpoint.fire(message: AnyJSON([1]), channel: "Test", meta: nil)
    XCTAssertEqual(fire.description, "Fire")
  }

  func testCustomStringConvertible_Subscribe() {
    let subscribe = Endpoint.subscribe(channels: ["Test"], groups: [], timetoken: 0, region: nil, state: nil)
    XCTAssertEqual(subscribe.description, "Subscribe")
  }
}
