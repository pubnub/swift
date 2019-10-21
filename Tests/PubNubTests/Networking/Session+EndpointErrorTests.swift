//
//  Session+GeneralSystemError.swift
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

final class SessionEndpointErrorTests: XCTestCase {
  let testBundle = Bundle(for: PubNubTests.self)
  var pubnub: PubNub!

  func testEndpointError(payload: GenericServicePayloadResponse?, for resource: String) {
    let expectation = self.expectation(description: "Endpoint Error \(resource) Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: [resource]) else {
      return XCTFail("Could not create mock url session")
    }

    pubnub = PubNub(configuration: .default, session: sessions.session)
    pubnub.time { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        guard let task = sessions.mockSession.tasks.first,
          let response = task.mockResponse else {
          return XCTFail("Could not get task")
        }

        let pubnubError = PubNubError(reason: payload?.pubnubReason,
                                      endpoint: .time,
                                      request: task.mockRequest,
                                      response: response)

        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, pubnubError)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // Contains Server Response Message
  func testCouldNotParseRequest() {
    testEndpointError(payload: .init(message: .couldNotParseRequest,
                                     service: "access manager",
                                     status: 400,
                                     error: true),
                      for: "couldNotParseRequest")
  }

  func testInvalidSubscribeKey() {
    testEndpointError(payload: .init(message: .invalidSubscribeKey,
                                     service: "access manager",
                                     status: 400,
                                     error: true),
                      for: "invalidSubscribeKey")
  }

  func testNotFound_Message() {
    testEndpointError(payload: .init(message: .notFound,
                                     service: "presence",
                                     status: 404,
                                     error: true),
                      for: "resourceNotFound_Message")
  }

  func testRequestURITooLong_Message() {
    testEndpointError(payload: .init(message: .requestURITooLong,
                                     service: "balancer",
                                     status: 414,
                                     error: true),
                      for: "requestURITooLong_Message")
  }

  // Derived from response status code
  func testBadRequest_StatusCode() {
    testEndpointError(payload: nil, for: "badRequest_StatusCode")
  }

  func testUnauthorized_StatusCode() {
    testEndpointError(payload: nil, for: "unauthorized_StatusCode")
  }

  func testForbidden_StatusCode() {
    testEndpointError(payload: nil, for: "forbidden_StatusCode")
  }

  func testNotFound_StatusCode() {
    testEndpointError(payload: nil, for: "resourceNotFound_StatusCode")
  }

  func testRequestURITooLong_StatusCode() {
    testEndpointError(payload: nil, for: "requestURITooLong_StatusCode")
  }

  func testMalformedFilterExpression_StatusCode() {
    testEndpointError(payload: nil, for: "malformedFilterExpression_StatusCode")
  }

  func testInternalServiceError_StatusCode() {
    testEndpointError(payload: nil, for: "internalServiceError_StatusCode")
  }

  func testUnrecognizedErrorPayload() {
    testEndpointError(payload: .init(message: .unknown(message: "Some New Message"),
                                     service: "New Endpoint",
                                     status: 451,
                                     error: true),
                      for: "unrecognizedEndpointError")
  }
}
