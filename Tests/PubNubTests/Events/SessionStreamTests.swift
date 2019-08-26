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

    let closureStream = SessionListener(queue: DispatchQueue(label: "Session Listener",
                                                             qos: .userInitiated,
                                                             attributes: .concurrent))
    let multiplexStream = MultiplexSessionStream([closureStream])

    guard let sessions = try? MockURLSession.mockSession(for: ["time_success"],
                                                         with: multiplexStream) else {
      return XCTFail("Could not create mock url session")
    }

    let sessionMultiplex = sessions.session?.sessionStream as? MultiplexSessionStream
    let sessionListener = sessionMultiplex?.streams.first as? SessionListener

    XCTAssertEqual(sessionMultiplex, multiplexStream)
    XCTAssertEqual(sessionListener, closureStream)

    let sessionExpector = SessionExpector(session: closureStream)

    sessionExpector.expectDidCreateURLRequest { request, urlRequest in
      XCTAssertEqual(request.urlRequest, urlRequest)
    }

    sessionExpector.expectDidCreateTask { request, task in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(request.urlRequest, mockTask?.mockRequest)
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
    }

    sessionExpector.expectDidResumeTask { request, task in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(request.urlRequest, mockTask?.mockRequest)
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
    }

    sessionExpector.expectDidCompleteTask { request, task in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(request.urlRequest, mockTask?.mockRequest)
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
    }

    sessionExpector.expectDidResumeRequest { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.mockRequest)
    }

    sessionExpector.expectDidFinishRequest { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.mockRequest)
    }

    sessionExpector.expectDidDecodeResponse { dataResponse in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(dataResponse.request, mockTask?.mockRequest)
      XCTAssertEqual(dataResponse.response, mockTask?.mockResponse)
      XCTAssertEqual(dataResponse.data, mockTask?.mockData)
    }

    sessionExpector.expectDidReceiveURLSessionData { urlSession, task, data in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(urlSession.sessionDescription, sessions.mockSession.sessionDescription)
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
      XCTAssertEqual(data, mockTask?.mockData)
    }

    sessionExpector.expectDidCompleteURLSessionTask { urlSession, task, error in
      XCTAssertEqual(urlSession.sessionDescription, sessions.mockSession.sessionDescription)
      XCTAssertEqual(task.taskIdentifier, sessions.mockSession.tasks.first?.taskIdentifier)
      XCTAssertNil(error)
    }

    let totalExpectation = expectation(description: "Time Response Received")
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
    expectations.append(totalExpectation)

    XCTAssertEqual(sessionExpector.expectations.count, 9)
    expectations.append(contentsOf: sessionExpector.expectations)

    wait(for: expectations, timeout: 1.0)
  }
}
