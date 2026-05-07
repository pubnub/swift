//
//  RequestIdOperatorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

class RequestIdOperatorTests: XCTestCase {
  func test_UseRequestIdEnabled_AppendsRequestIdToURL() throws {
    var expectations = [XCTestExpectation]()

    let sessionListener = SessionListener(queue: DispatchQueue(label: "Session Listener",
                                                               qos: .userInitiated,
                                                               attributes: .concurrent))

    let sessions = try MockURLSession.mockSession(for: ["time_success"],
                                                   with: sessionListener)

    let sessionExpector = SessionExpector(session: sessionListener)
    sessionExpector.expectDidMutateRequest { _, initialURLRequest, mutatedURLRequest in
      guard let mutatedURL = mutatedURLRequest.url, let initialURL = initialURLRequest.url else {
        return XCTFail("Could not create URL during request mutation")
      }

      XCTAssertFalse(initialURL.absoluteString.contains(RequestIdOperator.requestIDKey))
      XCTAssertTrue(mutatedURL.absoluteString.contains(RequestIdOperator.requestIDKey))
    }

    let totalExpectation = expectation(description: "Time Response Received")
    let config = PubNubConfiguration(
      publishKey: "FakeTestString", subscribeKey: "FakeTestString",
      userId: "testUserId", useRequestId: true
    )
    let pubnub = PubNub(configuration: config, session: sessions.session)

    XCTAssertTrue(pubnub.configuration.useRequestId)

    pubnub.time { _ in
      totalExpectation.fulfill()
    }
    expectations.append(totalExpectation)

    XCTAssertEqual(sessionExpector.expectations.count, 1)
    expectations.append(contentsOf: sessionExpector.expectations)

    wait(for: expectations, timeout: 1.0)
  }
}
