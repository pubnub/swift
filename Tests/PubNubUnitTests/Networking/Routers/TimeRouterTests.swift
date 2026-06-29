//
//  TimeRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class TimeRouterTests: XCTestCase {
  let config = TestPubNubFactory.makeConfig()

  func test_TimeRouter_WithValidConfig_SetsExpectedEndpoint() throws {
    let router = TimeRouter(.time, configuration: config)

    XCTAssertEqual(router.endpoint.description, "Time")
    XCTAssertEqual(router.category, "Time")
    XCTAssertEqual(try router.path.get(), "/time/0")
    XCTAssertEqual(try router.queryItems.get(), router.defaultQueryItems)
    XCTAssertEqual(router.pamVersion, .none)
    XCTAssertEqual(router.keysRequired, .none)
    XCTAssertEqual(router.service, .time)
  }

  func test_TimeRouter_WithValidConfig_ReturnsNoValidationError() {
    let router = TimeRouter(.time, configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError, nil)
  }

  func test_Time_WithValidRequest_ReturnsTimetoken() throws {
    let expectation = self.expectation(description: "Time Response Received")
    let sessions = try MockURLSession.mockSession(for: ["time_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.time { result in
      switch result {
      case let .success(timetoken):
        XCTAssertEqual(timetoken, 15_643_405_135_132_358)
      case let .failure(error):
        XCTFail("Time request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
