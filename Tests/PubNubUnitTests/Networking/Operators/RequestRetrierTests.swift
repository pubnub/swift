//
//  RequestRetrierTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

class RequestRetrierTests: XCTestCase {
  let streamQueue = DispatchQueue(label: "Session Listener", qos: .userInitiated, attributes: .concurrent)

  func test_AfterTwoFailures_SucceedsOnThirdAttempt() throws {
    var expectations = [XCTestExpectation]()
    let sessionListener = SessionListener(queue: streamQueue)
    let sessionExpector = SessionExpector(session: sessionListener)

    let retrier = RetryExpector(all: &expectations)

    retrier.shouldRetry = { _, _, error, retryCount in
      switch retryCount {
      case 0: return .success(0.0)
      case 1: return .success(0.001)
      default: return .failure(error)
      }
    }

    let sessions = try MockURLSession.mockSession(
      for: ["networkConnectionLost", "timedOut", "time_success"],
      with: sessionListener,
      request: MultiplexRequestOperator(requestOperator: retrier)
    )

    sessionExpector.expectDidRetryRequest(fullfil: 2) { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.originalRequest)
    }

    let responseExpect = expectation(description: "Time response")
    let pubnub = TestPubNubFactory.make(publishKey: "FakePubKey", subscribeKey: "FakeSubKey", session: sessions.session)

    pubnub.time { result in
      do {
        let value = try result.get()
        XCTAssertEqual(value, 15_643_405_135_132_358)
      } catch {
        XCTFail("Expected success but got error: \(error)")
      }
      responseExpect.fulfill()
    }

    wait(for: expectations + sessionExpector.expectations + [responseExpect], timeout: 1.0)
  }

  func test_AllRetriesFail_ReturnsLastError() throws {
    var expectations = [XCTestExpectation]()
    let sessionListener = SessionListener(queue: streamQueue)
    let sessionExpector = SessionExpector(session: sessionListener)

    let retrier = RetryExpector(expectedRetry: 3, all: &expectations)
    retrier.shouldRetry = { _, _, error, retryCount in
      switch retryCount {
      case 0: return .success(0)
      case 1: return .success(0.001)
      default: return .failure(error)
      }
    }

    let sessions = try MockURLSession.mockSession(
      for: ["networkConnectionLost", "timedOut", "cannotFindHost"],
      with: sessionListener,
      request: retrier
    )

    sessionExpector.expectDidRetryRequest(fullfil: 2) { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.originalRequest)
    }

    let responseExpect = expectation(description: "Time response")
    let pubnub = TestPubNubFactory.make(publishKey: "FakePubKey", subscribeKey: "FakeSubKey", session: sessions.session)

    pubnub.time { result in
      if case let .failure(error) = result {
        XCTAssertEqual(error.pubNubError, PubNubError(.nameResolutionFailure))
      } else {
        XCTFail("Expected failure")
      }
      responseExpect.fulfill()
    }

    wait(for: expectations + sessionExpector.expectations + [responseExpect], timeout: 1.0)
  }

  func test_MultiplexWithRetrier_SucceedsAfterRetries() throws {
    var expectations = [XCTestExpectation]()
    let sessionListener = SessionListener(queue: streamQueue)
    let sessionExpector = SessionExpector(session: sessionListener)

    let retrier = RetryExpector(all: &expectations)
    retrier.shouldRetry = { _, _, error, retryCount in
      switch retryCount {
      case 0: return .success(0.0)
      case 1: return .success(0.001)
      default: return .failure(error)
      }
    }

    let sessions = try MockURLSession.mockSession(
      for: ["networkConnectionLost", "timedOut", "time_success"],
      with: sessionListener,
      request: MultiplexRequestOperator(operators: [retrier])
    )

    sessionExpector.expectDidRetryRequest(fullfil: 2) { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.originalRequest)
    }

    let responseExpect = expectation(description: "Time response")
    let pubnub = TestPubNubFactory.make(publishKey: "FakePubKey", subscribeKey: "FakeSubKey", session: sessions.session)

    pubnub.time { result in
      do {
        let value = try result.get()
        XCTAssertEqual(try result.get(), 15_643_405_135_132_358)
      } catch {
        XCTFail("Expected success but got error: \(error)")
      }
      responseExpect.fulfill()
    }

    wait(for: expectations + sessionExpector.expectations + [responseExpect], timeout: 1.0)
  }
}
