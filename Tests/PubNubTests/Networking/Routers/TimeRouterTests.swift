//
//  TimeRouterTests.swift
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

class TimeRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  func testTime_Endpoint() {
    let router = TimeRouter(.time, configuration: config)

    XCTAssertEqual(router.endpoint.description, "Time")
    XCTAssertEqual(router.category, "Time")
    XCTAssertEqual(try? router.path.get(), "/time/0")
    XCTAssertEqual(try? router.queryItems.get(), router.defaultQueryItems)
    XCTAssertEqual(router.pamVersion, .none)
    XCTAssertEqual(router.keysRequired, .none)
    XCTAssertEqual(router.service, .time)
  }

  func testTime_Endpoint_ValidationError() {
    let router = TimeRouter(.time, configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError, nil)
  }

  func testTime_Success() {
    let expectation = self.expectation(description: "Time Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["time_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session).time { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.timetoken, 15_643_405_135_132_358)
      case let .failure(error):
        XCTFail("Time request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
