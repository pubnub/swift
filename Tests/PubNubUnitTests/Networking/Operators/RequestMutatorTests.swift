//
//  RequestMutatorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

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
    var expectations = [XCTestExpectation]()

    let sessionListener = SessionListener(queue: DispatchQueue(label: "Session Listener",
                                                               qos: .userInitiated,
                                                               attributes: .concurrent))

    let newAuth = URLQueryItem(name: "auth", value: "newAuthKey")

    var mutator = MutatorExpector(all: &expectations)
    mutator.mutateRequest = { request in
      var newRequest = request
      newRequest.url = request.url?.appendingQueryItems([newAuth])
      return .success(newRequest)
    }

    let sessionExpector = SessionExpector(session: sessionListener)
    sessionExpector.expectDidMutateRequest { request, initialURLRequest, mutatedURLRequest in
      guard let mutatedURL = mutatedURLRequest.url, let initialURL = initialURLRequest.url else {
        return XCTFail("Could not create URL during request mutation")
      }

      XCTAssertEqual(request.urlRequest, mutatedURLRequest)

      let initialURLComp = URLComponents(url: initialURL, resolvingAgainstBaseURL: true)
      XCTAssertFalse(initialURLComp?.queryItems?.contains(newAuth) ?? true)

      let mutatedURLComp = URLComponents(url: mutatedURL, resolvingAgainstBaseURL: true)
      XCTAssertTrue(mutatedURLComp?.queryItems?.contains(newAuth) ?? false)
    }

    let sessions = try MockURLSession.mockSession(
      for: ["time_success"],
      with: sessionListener,
      request: MultiplexRequestOperator(operators: [DefaultOperator(), mutator])
    )

    let totalExpectation = expectation(description: "Time Response Received")
    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.time { result in
      switch result {
      case let .success(timetoken):
        XCTAssertEqual(timetoken, 15_643_405_135_132_358)
      case let .failure(error):
        XCTFail("Time request failed with error: \(error.localizedDescription)")
      }
      totalExpectation.fulfill()
    }
    expectations.append(totalExpectation)

    XCTAssertEqual(sessionExpector.expectations.count, 1)
    expectations.append(contentsOf: sessionExpector.expectations)

    wait(for: expectations, timeout: 1.0)
  }

  func test_MutateRequestFails_ReturnsRequestMutatorFailureError() throws {
    var expectations = [XCTestExpectation]()

    let sessionListener = SessionListener(queue: DispatchQueue(label: "Session Listener",
                                                               qos: .userInitiated,
                                                               attributes: .concurrent))
    var mutator = MutatorExpector(all: &expectations)
    mutator.mutateRequest = { _ in
      .failure(PubNubError(.requestMutatorFailure))
    }

    let sessionExpector = SessionExpector(session: sessionListener)
    sessionExpector.expectDidFailToMutateRequest { request, initialURLRequest, error in

      XCTAssertEqual(request.urlRequest, initialURLRequest)
      XCTAssertEqual(error.pubNubError, PubNubError(.requestMutatorFailure))
    }

    let sessions = try MockURLSession.mockSession(
      for: ["cannotFindHost"],
      with: sessionListener,
      request: MultiplexRequestOperator(operators: [mutator, DefaultOperator()])
    )

    let totalExpectation = expectation(description: "Time Response Received")
    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.time { result in
      switch result {
      case .success:
        XCTFail("Time request should fail")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.requestMutatorFailure))
      }
      totalExpectation.fulfill()
    }
    expectations.append(totalExpectation)

    XCTAssertEqual(sessionExpector.expectations.count, 1)
    expectations.append(contentsOf: sessionExpector.expectations)

    wait(for: expectations, timeout: 1.0)
  }
}
