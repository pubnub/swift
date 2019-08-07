//
//  WhereNowTests.swift
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

final class WhereNowTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  let channelName = "TestChannel"

  func testHereNow_Endpoint() {
    let endpoint = Endpoint.hereNow(channels: [channelName], groups: [], includeUUIDs: true, includeState: true)

    XCTAssertEqual(endpoint.description, "Here Now")
    XCTAssertEqual(endpoint.rawValue, .hereNow)
  }

  func testSuccess_EmptyClasses() {
    let expectation = self.expectation(description: "WhereNow Response Recieved")

    guard let sessions = try? MockURLSession.mockSession(for: ["wherenow_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .whereNow(for: "testUser") { result in
        switch result {
        case let .success(payload):
          XCTAssertTrue(payload.channels.isEmpty)
        case let .failure(error):
          XCTFail("Where Now request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testSuccess() {
    let expectation = self.expectation(description: "WhereNow Response Recieved")

    guard let sessions = try? MockURLSession.mockSession(for: ["wherenow_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .whereNow(for: "testUser") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.channels.count, 1)
        case let .failure(error):
          XCTFail("Where Now request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}
