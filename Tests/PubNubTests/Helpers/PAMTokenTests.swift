//
//  PAMTokenTests.swift
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

// swiftlint:disable line_length

class PAMTokenTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "", subscribeKey: "", userId: "tester")
  static let allPermissionsToken = "qEF2AkF0GmEI03xDdHRsGDxDcmVzpURjaGFuoWljaGFubmVsLTEY70NncnChb2NoYW5uZWxfZ3JvdXAtMQVDdXNyoENzcGOgRHV1aWShZnV1aWQtMRhoQ3BhdKVEY2hhbqFtXmNoYW5uZWwtXFMqJBjvQ2dycKF0XjpjaGFubmVsX2dyb3VwLVxTKiQFQ3VzcqBDc3BjoER1dWlkoWpedXVpZC1cUyokGGhEbWV0YaBEdXVpZHR0ZXN0LWF1dGhvcml6ZWQtdXVpZENzaWdYIPpU-vCe9rkpYs87YUrFNWkyNq8CVvmKwEjVinnDrJJc"
}

// MARK: Scanner

extension PAMTokenTests {
  func testParseToken() {
    let pubnub = PubNub(configuration: config)
    let token = pubnub.parse(token: PAMTokenTests.allPermissionsToken)
    guard let resources = token?.resources else {
      return XCTAssert(false, "'resources' is missing")
    }
    guard let patterns = token?.patterns else {
      return XCTAssert(false, "'patterns' is missing")
    }

    XCTAssertEqual(token?.authorizedUUID, "test-authorized-uuid")
    XCTAssertEqual(resources.channels.count, 1)
    XCTAssertEqual(resources.groups.count, 1)
    XCTAssertEqual(resources.uuids.count, 1)
    XCTAssertEqual(patterns.channels.count, 1)
    XCTAssertEqual(patterns.groups.count, 1)
    XCTAssertEqual(patterns.uuids.count, 1)

    XCTAssertEqual(resources.channels["channel-1"], PAMPermission.all)
    XCTAssertEqual(resources.groups["channel_group-1"], [PAMPermission.read, PAMPermission.manage])
    XCTAssertEqual(resources.uuids["uuid-1"], [PAMPermission.delete, PAMPermission.get, PAMPermission.update])
    XCTAssertEqual(patterns.channels["^channel-\\S*$"], PAMPermission.all)
    XCTAssertEqual(patterns.groups["^:channel_group-\\S*$"], [PAMPermission.read, PAMPermission.manage])
    XCTAssertEqual(patterns.uuids["^uuid-\\S*$"], [PAMPermission.delete, PAMPermission.get, PAMPermission.update])
  }

  func testSetToken() {
    let pubnub = PubNub(configuration: config)
    pubnub.set(token: "access-token")

    XCTAssertEqual(pubnub.configuration.authToken, "access-token")
    XCTAssertEqual(pubnub.subscription.configuration.authToken, "access-token")
  }

  func testChangeToken() {
    let pubnub = PubNub(configuration: config)
    pubnub.set(token: "access-token")
    pubnub.set(token: "access-token-updated")

    XCTAssertEqual(pubnub.configuration.authToken, "access-token-updated")
    XCTAssertEqual(pubnub.subscription.configuration.authToken, "access-token-updated")
  }

  // swiftlint:enable line_length
}
