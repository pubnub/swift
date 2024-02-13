//
//  SessionStreamTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class SessionStreamTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)

  // swiftlint:disable:next function_body_length
  func testSessionStream_Closure() {
    var expectations = [XCTestExpectation]()

    let closureStream = SessionListener(queue: DispatchQueue(label: "Session Listener",
                                                             qos: .userInitiated,
                                                             attributes: .concurrent))
    let multiplexStream = MultiplexSessionStream([closureStream])

    guard let sessions = try? MockURLSession.mockSession(for: ["time_success"],
                                                         with: multiplexStream)
    else {
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
      XCTAssertEqual(request.urlRequest, mockTask?.originalRequest)
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
    }

    sessionExpector.expectDidResumeTask { request, task in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(request.urlRequest, mockTask?.originalRequest)
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
    }

    sessionExpector.expectDidCompleteTask { request, task in
      let mockTask = sessions.mockSession.tasks.first
      XCTAssertEqual(request.urlRequest, mockTask?.originalRequest)
      XCTAssertEqual(task.taskIdentifier, mockTask?.taskIdentifier)
    }

    sessionExpector.expectDidResumeRequest { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.originalRequest)
    }

    sessionExpector.expectDidFinishRequest { request in
      XCTAssertEqual(request.urlRequest, sessions.mockSession.tasks.first?.originalRequest)
    }

    sessionExpector.expectDidReceiveURLSessionData { urlSession, task, data in
      let mockTask = sessions.mockSession.tasks.first as? MockURLSessionDataTask
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

    XCTAssertEqual(sessionExpector.expectations.count, 8)
    expectations.append(contentsOf: sessionExpector.expectations)

    wait(for: expectations, timeout: 1.0)
  }
}
