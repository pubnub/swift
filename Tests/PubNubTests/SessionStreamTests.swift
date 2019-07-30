//
//  SessionStreamTests.swift
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

class SessionStreamTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  // swiftlint:disable:next function_body_length
  func testSessionStream_Closure() {
    var expectations = [XCTestExpectation]()
    let totalExpectation = expectation(description: "Time Response Recieved")
    expectations.append(totalExpectation)
    let streamQueue = DispatchQueue(label: "Session Listener",
                                    qos: .userInitiated,
                                    attributes: .concurrent)

    let closureStream = SessionListener(queue: streamQueue)
    let multiplexStream = MultiplexSessionStream([closureStream])

    guard let sessions = try? MockURLSession.mockSession(for: "time_success",
                                                         with: multiplexStream) else {
      return XCTFail("Could not create mock url session")
    }

    let sessionMultiplex = sessions.session?.sessionStream as? MultiplexSessionStream
    let sessionListener = sessionMultiplex?.streams.first as? SessionListener

    XCTAssertEqual(sessionMultiplex, multiplexStream)
    XCTAssertEqual(sessionListener, closureStream)

    let didCreateURLRequestExpectation = expectation(description: "didCreateURLRequest")
    expectations.append(didCreateURLRequestExpectation)
    closureStream.didCreateURLRequest = { request, urlRequest in
      XCTAssertEqual(request.urlRequest, urlRequest)
      XCTAssertEqual(urlRequest, sessions.mockSession.tasks.first?.mockRequest)
      didCreateURLRequestExpectation.fulfill()
    }

    closureStream.didFailToCreateURLRequestWithError = { _, _ in
      XCTFail("didFailToCreateURLRequestWithError should not be called")
    }

    let didCreateTaskErrorExpectation = expectation(description: "didCreateTask")
    expectations.append(didCreateTaskErrorExpectation)
    closureStream.didCreateTask = { request, task in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(request.urlRequest, mockTask?.mockRequest)
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
      didCreateTaskErrorExpectation.fulfill()
    }

    let didResumeTaskErrorExpectation = expectation(description: "didResumeTask")
    expectations.append(didResumeTaskErrorExpectation)
    closureStream.didResumeTask = { request, _ in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.mockRequest)
      didResumeTaskErrorExpectation.fulfill()
    }

    closureStream.didCancelTask = { _, _ in
      XCTFail("didCancelTask should not be called")
    }

    let didCompleteTaskExpectation = expectation(description: "didCompleteTask")
    expectations.append(didCompleteTaskExpectation)
    closureStream.didCompleteTask = { request, task in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(request.urlRequest, mockTask?.mockRequest)
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
      didCompleteTaskExpectation.fulfill()
    }

    closureStream.didCompleteTaskWithError = { _, _, _ in
      XCTFail("didCompleteTaskWithError should not be called")
    }

    let didResumeRequestExpectation = expectation(description: "didResumeRequest")
    expectations.append(didResumeRequestExpectation)
    closureStream.didResumeRequest = { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.mockRequest)
      didResumeRequestExpectation.fulfill()
    }

    let didFinishRequestExpectation = expectation(description: "didFinishRequest")
    expectations.append(didFinishRequestExpectation)
    closureStream.didFinishRequest = { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.mockRequest)
      didFinishRequestExpectation.fulfill()
    }

    closureStream.didCancelRequest = { _ in
      XCTFail("didCancelRequest should not be called")
    }

    closureStream.didRetryRequest = { _ in
      XCTFail("didRetryRequest should not be called")
    }

    closureStream.didMutateRequest = { _, _, _ in
      XCTFail("didMutateRequest should not be called")
    }

    closureStream.didFailToMutateRequest = { _, _, _ in
      XCTFail("didFailToMutateRequest should not be called")
    }

    let didDecodeResponseExpectation = expectation(description: "didDecodeResponse")
    expectations.append(didDecodeResponseExpectation)
    closureStream.didDecodeResponse = { dataResponse in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(dataResponse.request, mockTask?.mockRequest)
      XCTAssertEqual(dataResponse.response, mockTask?.mockResponse)
      XCTAssertEqual(dataResponse.data, mockTask?.mockData)
      didDecodeResponseExpectation.fulfill()
    }

    closureStream.failedToDecodeResponse = { _, _ in
      XCTFail("failedToDecodeResponse should not be called")
    }

    let sessionTaskDidReceiveDataExpectation = expectation(description: "sessionTaskDidReceiveData")
    expectations.append(sessionTaskDidReceiveDataExpectation)
    closureStream.sessionTaskDidReceiveData = { _, task, data in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
      XCTAssertEqual(data, mockTask?.mockData)
      sessionTaskDidReceiveDataExpectation.fulfill()
    }

    let sessionTaskDidCompleteExpectation = expectation(description: "sessionTaskDidComplete")
    expectations.append(sessionTaskDidCompleteExpectation)
    closureStream.sessionTaskDidComplete = { _, task, error in
      XCTAssertEqual(task.taskIdentifier, sessions.mockSession.tasks.first?.taskIdentifier)
      XCTAssertNil(error)
      sessionTaskDidCompleteExpectation.fulfill()
    }

    closureStream.sessionDidBecomeInvalidated = { _, _ in
      XCTFail("sessionDidBecomeInvalidated should not be called")
    }

    pubnub = PubNub(configuration: .default, session: sessions.session)
    pubnub.time { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.timetoken, 15_643_405_135_132_358)
      case let .failure(error):
        XCTFail("Time request failed with error: \(error.localizedDescription)")
      }
      totalExpectation.fulfill()
    }

    wait(for: expectations, timeout: 1.0)
  }
}
