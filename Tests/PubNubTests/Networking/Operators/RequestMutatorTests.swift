//
//  RequestMutatorTests.swift
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

class RequestMutatorTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  func testMultiplexOperation_Init() {
    let mutator = DefaultOperator()

    let multiplex = MultiplexRequestOperator(requestOperator: mutator)
    XCTAssertEqual(multiplex.operators.count, 1)
    XCTAssertEqual(multiplex.operators.first as? DefaultOperator, mutator)

    let emptyMultiplex = MultiplexRequestOperator(requestOperator: nil)
    XCTAssertEqual(emptyMultiplex.operators.count, 0)
  }

  func testMutateRequest_Success() {
    var expectations = [XCTestExpectation]()

    let sessionListener = SessionListener(queue: DispatchQueue(label: "Session Listener",
                                                               qos: .userInitiated,
                                                               attributes: .concurrent))

    let newAuth = URLQueryItem(name: "auth", value: "newAuthKey")

    var mutator = MutatorExpector(all: &expectations)
    mutator.mutateRequest = { request in
      var newRequest = request
      newRequest.url = request.url?.appending(queryItems: [newAuth])
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

    guard let sessions = try? MockURLSession.mockSession(
      for: ["time_success"],
      with: sessionListener,
      request: MultiplexRequestOperator(operators: [DefaultOperator(), mutator])
    ) else {
      return XCTFail("Could not create mock url session")
    }

    let totalExpectation = expectation(description: "Time Response Received")
    pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testMutateRequest_Failure() {
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

    guard let sessions = try? MockURLSession.mockSession(
      for: ["cannotFindHost"],
      with: sessionListener,
      request: MultiplexRequestOperator(operators: [mutator, DefaultOperator()])
    ) else {
      return XCTFail("Could not create mock url session")
    }

    let totalExpectation = expectation(description: "Time Response Received")
    pubnub = PubNub(configuration: config, session: sessions.session)
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
