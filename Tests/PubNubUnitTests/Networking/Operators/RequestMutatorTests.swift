//
//  RequestMutatorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

class RequestMutatorTests: XCTestCase {
  func test_MultiplexInitWithOperator_ContainsOneOperator() {
    let mutator = DefaultOperator()

    let multiplex = MultiplexRequestOperator(requestOperator: mutator)
    XCTAssertEqual(multiplex.operators.count, 1)
    XCTAssertEqual(multiplex.operators.first as? DefaultOperator, mutator)

    let emptyMultiplex = MultiplexRequestOperator(requestOperator: nil)
    XCTAssertEqual(emptyMultiplex.operators.count, 0)
  }

  func test_MutateRequestSucceeds_AppendsQueryItemToURL() throws {
    let streamQueue = DispatchQueue(label: "Session Listener", qos: .userInitiated, attributes: .concurrent)
    let newAuth = URLQueryItem(name: "auth", value: "newAuthKey")
    let mutator = StubRequestMutator(appending: [newAuth])
    let sessionListener = SessionListener(queue: streamQueue)
    let sessionExpector = SessionExpector(session: sessionListener)

    sessionExpector.expectDidMutateRequest { _, initialURLRequest, mutatedURLRequest in
      let initialItems = initialURLRequest.url
        .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: true) }?.queryItems
      let mutatedItems = mutatedURLRequest.url
        .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: true) }?.queryItems

      XCTAssertFalse(initialItems?.contains(newAuth) ?? true)
      XCTAssertTrue(mutatedItems?.contains(newAuth) ?? false)
    }

    let sessions = try MockURLSession.mockSession(
      for: ["time_success"],
      with: sessionListener,
      request: MultiplexRequestOperator(operators: [mutator])
    )

    let responseExpect = expectation(description: "Time response")
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.time { result in
      do {
        let value = try result.get()
        XCTAssertEqual(value, 15_643_405_135_132_358)
      } catch {
        XCTFail("Expected success but got error: \(error)")
      }
      responseExpect.fulfill()
    }

    wait(for: sessionExpector.expectations + [responseExpect], timeout: 1.0)
  }

  func test_MutateRequestFails_ReturnsRequestMutatorFailureError() throws {
    let streamQueue = DispatchQueue(label: "Session Listener", qos: .userInitiated, attributes: .concurrent)
    let mutator = StubRequestMutator(failing: PubNubError(.requestMutatorFailure))
    let sessionListener = SessionListener(queue: streamQueue)
    let sessionExpector = SessionExpector(session: sessionListener)

    sessionExpector.expectDidFailToMutateRequest { request, initialURLRequest, error in
      XCTAssertEqual(request.urlRequest, initialURLRequest)
      XCTAssertEqual(error.pubNubError, PubNubError(.requestMutatorFailure))
    }

    let sessions = try MockURLSession.mockSession(
      for: ["cannotFindHost"],
      with: sessionListener,
      request: MultiplexRequestOperator(operators: [mutator])
    )

    let responseExpect = expectation(description: "Time response")
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.time { result in
      if case let .failure(error) = result {
        XCTAssertEqual(error.pubNubError, PubNubError(.requestMutatorFailure))
      } else {
        XCTFail("Expected failure")
      }
      responseExpect.fulfill()
    }

    wait(for: sessionExpector.expectations + [responseExpect], timeout: 1.0)
  }
}
