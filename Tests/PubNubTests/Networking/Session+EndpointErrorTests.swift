//
//  Session+EndpointErrorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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

    let config = PubNubConfiguration(publishKey: "FakePubKey", subscribeKey: "FakeSubKey", userId: UUID().uuidString)
    pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.time { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        guard let task = sessions.mockSession.tasks.first,
              let request = task.originalRequest,
              let response = task.httpResponse
        else {
          return XCTFail("Could not get task")
        }

        let pubnubError = PubNubError(reason: payload?.pubnubReason,
                                      router: TimeRouter(.time, configuration: config),
                                      request: request,
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
