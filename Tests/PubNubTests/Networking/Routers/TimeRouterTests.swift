//
//  TimeRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class TimeRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)

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

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
