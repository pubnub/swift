//
//  RequestIdOperatorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class RequestIdOperatorTests: XCTestCase {
  var pubnub: PubNub!
  var config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)

  func testUseRequestID_Success() {
    var expectations = [XCTestExpectation]()

    let sessionListener = SessionListener(queue: DispatchQueue(label: "Session Listener",
                                                               qos: .userInitiated,
                                                               attributes: .concurrent))

    guard let sessions = try? MockURLSession.mockSession(for: ["time_success"],
                                                         with: sessionListener)
    else {
      return XCTFail("Could not create mock url session")
    }

    let sessionExpector = SessionExpector(session: sessionListener)
    sessionExpector.expectDidMutateRequest { _, initialURLRequest, mutatedURLRequest in
      guard let mutatedURL = mutatedURLRequest.url, let initialURL = initialURLRequest.url else {
        return XCTFail("Could not create URL during request mutation")
      }

      XCTAssertFalse(initialURL.absoluteString.contains(RequestIdOperator.requestIDKey))
      XCTAssertTrue(mutatedURL.absoluteString.contains(RequestIdOperator.requestIDKey))
    }

    let totalExpectation = expectation(description: "Time Response Received")
    config.useRequestId = true
    pubnub = PubNub(configuration: config, session: sessions.session)

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
