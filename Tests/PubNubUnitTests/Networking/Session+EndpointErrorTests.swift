//
//  Session+EndpointErrorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class SessionEndpointErrorTests: XCTestCase {
  let testBundle = Bundle(for: PubNubTests.self)

  func testEndpointError(payload: GenericServicePayloadResponse?, for resource: String) throws {
    let expectation = self.expectation(description: "Endpoint Error \(resource) Expectation")
    let sessions = try MockURLSession.mockSession(for: [resource])
    let config = TestPubNubFactory.makeConfig(publishKey: "FakePubKey", subscribeKey: "FakeSubKey")
    let pubnub = PubNub(configuration: config, session: sessions.session)

    pubnub.time { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        guard
          let task = sessions.mockSession.tasks.first,
          let request = task.originalRequest,
          let response = task.httpResponse
        else {
          return XCTFail("Could not get task")
        }

        let pubnubError = PubNubError(
          reason: payload?.pubnubReason,
          router: TimeRouter(.time, configuration: config),
          request: request,
          response: response
        )

        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, pubnubError)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Session_EndpointCouldNotParseRequest_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: .init(
        message: .couldNotParseRequest,
        service: "access manager",
        status: 400,
        error: true
      ),
      for: "couldNotParseRequest"
    )
  }

  func test_Session_EndpointInvalidSubscribeKey_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: .init(
        message: .invalidSubscribeKey,
        service: "access manager",
        status: 400,
        error: true
      ),
      for: "invalidSubscribeKey"
    )
  }

  func test_Session_EndpointNotFoundMessage_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: .init(
        message: .notFound,
        service: "presence",
        status: 404,
        error: true
      ),
      for: "resourceNotFound_Message"
    )
  }

  func test_Session_EndpointRequestURITooLongMessage_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: .init(
        message: .requestURITooLong,
        service: "balancer",
        status: 414,
        error: true
      ),
      for: "requestURITooLong_Message"
    )
  }

  // Derived from response status code
  func test_Session_EndpointBadRequestStatusCode_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: nil,
      for: "badRequest_StatusCode"
    )
  }

  func test_Session_EndpointUnauthorizedStatusCode_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: nil,
      for: "unauthorized_StatusCode"
    )
  }

  func test_Session_EndpointForbiddenStatusCode_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: nil,
      for: "forbidden_StatusCode"
    )
  }

  func test_Session_EndpointNotFoundStatusCode_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: nil,
      for: "resourceNotFound_StatusCode"
    )
  }

  func test_Session_EndpointRequestURITooLongStatusCode_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: nil,
      for: "requestURITooLong_StatusCode"
    )
  }

  func test_Session_EndpointMalformedFilterExpressionStatusCode_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: nil,
      for: "malformedFilterExpression_StatusCode"
    )
  }

  func test_Session_EndpointInternalServiceErrorStatusCode_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: nil,
      for: "internalServiceError_StatusCode"
    )
  }

  func test_Session_EndpointUnrecognizedErrorPayload_ReturnsPubNubError() throws {
    try testEndpointError(
      payload: .init(
        message: .unknown(message: "Some New Message"),
        service: "New Endpoint",
        status: 451,
        error: true
      ),
      for: "unrecognizedEndpointError"
    )
  }
}
