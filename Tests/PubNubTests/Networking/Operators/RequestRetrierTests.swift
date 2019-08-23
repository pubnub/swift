//
//  RequestRetrierTests.swift
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

class RequestRetrierTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")
  let streamQueue = DispatchQueue(label: "Session Listener", qos: .userInitiated, attributes: .concurrent)
  var retryCount = 0

  var expectations = [XCTestExpectation]()

  override func setUp() {
    super.setUp()

    retryCount = 0
    expectations.removeAll()
  }

  func testRetryRequest_Success() {
    let sessionListener = SessionListener(queue: streamQueue)
    let sessionExpector = SessionExpector(session: sessionListener)

    let taskResources = ["networkConnectionLost", "timedOut", "time_success"]
    guard let sessions = try? MockURLSession.mockSession(for: taskResources, with: sessionListener) else {
      return XCTFail("Could not create mock url session")
    }

    let retrier = RetryExpector(all: &expectations)
    retrier.shouldRetry = { _, _, _, retryCount in
      switch retryCount {
      case 0:
        return .retry
      case 1:
        return .retryWithDelay(0.001)
      default:
        XCTFail("We should only retry twice")
        return .doNotRetry
      }
    }

    sessionExpector.expectDidRetryRequest(fullfil: 2) { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.mockRequest)
      self.retryCount += 1
      switch self.retryCount {
      case 1:
        XCTAssertEqual(request.retryCount, 1)
      case 2:
        XCTAssertEqual(request.retryCount, 2)
      default:
        XCTFail("Retrying greater than 2 times")
      }
    }

    let totalExpectation = expectation(description: "Time Response Recieved")
    let networkConfig = NetworkConfiguration(requestOperator: MultiplexRequestOperator(requestOperator: retrier))
    PubNub(configuration: .default, session: sessions.session).time(with: networkConfig) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.timetoken, 15_643_405_135_132_358)
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

  func testRetryRequest_Failure() {
    let sessionListener = SessionListener(queue: streamQueue)
    let sessionExpector = SessionExpector(session: sessionListener)

    let taskResources = ["networkConnectionLost", "timedOut", "cannotFindHost"]
    guard let sessions = try? MockURLSession.mockSession(for: taskResources, with: sessionListener) else {
      return XCTFail("Could not create mock url session")
    }

    let retrier = RetryExpector(expectedRetry: 3, all: &expectations)
    retrier.shouldRetry = { _, _, error, retryCount in
      switch retryCount {
      case 0:
        return .retry
      case 1:
        return .retryWithDelay(0.001)
      default:
        return .doNotRetryWithError(error)
      }
    }

    sessionExpector.expectDidRetryRequest(fullfil: 2) { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.mockRequest)
      self.retryCount += 1
      switch self.retryCount {
      case 1:
        XCTAssertEqual(request.retryCount, 1)
      case 2:
        XCTAssertEqual(request.retryCount, 2)
      default:
        XCTFail("Retrying greater than 2 times")
      }
    }

    let totalExpectation = expectation(description: "Time Response Recieved")
    let networkConfig = NetworkConfiguration(requestOperator: retrier)
    PubNub(configuration: .default, session: sessions.session).time(with: networkConfig) { result in
      switch result {
      case .success:
        XCTFail("Time request should fail")
      case let .failure(error):
        guard let task = sessions.mockSession.tasks.last else {
          return XCTFail("Could not get task")
        }

        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, self.getRetryError(from: task, for: .cannotFindHost, and: .timedOut))
      }
      totalExpectation.fulfill()
    }
    expectations.append(totalExpectation)

    XCTAssertEqual(sessionExpector.expectations.count, 1)
    expectations.append(contentsOf: sessionExpector.expectations)

    wait(for: expectations, timeout: 1.0)
  }

  func getRetryError(
    from task: MockURLSessionTask,
    for current: URLError.Code,
    and previous: URLError.Code
  ) -> PNError? {
    guard let curError = PNError.convert(endpoint: .time,
                                         error: URLError(current),
                                         request: task.mockRequest,
                                         response: task.mockResponse),
      let prevError = PNError.convert(endpoint: .time,
                                      error: URLError(previous),
                                      request: task.mockRequest,
                                      response: task.mockResponse) else {
      return nil
    }
    return PNError.requestRetryFailed(.time, task.mockRequest, dueTo: curError, withPreviousError: prevError)
  }

  func testRetryRequest_Multiple_Success() {
    let sessionListener = SessionListener(queue: streamQueue)
    let sessionExpector = SessionExpector(session: sessionListener)

    let taskResources = ["networkConnectionLost", "timedOut", "time_success"]
    guard let sessions = try? MockURLSession.mockSession(for: taskResources, with: sessionListener) else {
      return XCTFail("Could not create mock url session")
    }

    let retrier = RetryExpector(all: &expectations)
    retrier.shouldRetry = { _, _, _, retryCount in
      switch retryCount {
      case 0:
        return .retry
      case 1:
        return .retryWithDelay(0.001)
      default:
        return .doNotRetry
      }
    }

    sessionExpector.expectDidRetryRequest(fullfil: 2) { request in
      let urlRequest = sessions.mockSession.tasks.first?.mockRequest
      XCTAssertEqual(request.urlRequest, urlRequest)
      self.retryCount += 1
      switch self.retryCount {
      case 1:
        XCTAssertEqual(request.retryCount, 1)
      case 2:
        XCTAssertEqual(request.retryCount, 2)
      default:
        XCTFail("Retrying greater than 2 times")
      }
    }

    let totalExpectation = expectation(description: "Time Response Recieved")
    let networkConfig = NetworkConfiguration(
      requestOperator: MultiplexRequestOperator(operators: [DefaultOperator(), retrier])
    )
    PubNub(configuration: .default, session: sessions.session).time(with: networkConfig) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.timetoken, 15_643_405_135_132_358)
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
}
