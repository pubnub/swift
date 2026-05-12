//
//  MessageActionsRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class MessageActionsRouterTests: XCTestCase {}

// MARK: - Fetch Message Actions Tests

extension MessageActionsRouterTests {
  func test_FetchMessageActionsRouter_WithValidConfig_SetsExpectedEndpoint() {
    let config = TestPubNubFactory.makeConfig()
    let router = MessageActionsRouter(.fetch(channel: "TestChannel", start: nil, end: nil, limit: nil),
                                      configuration: config)

    XCTAssertEqual(router.endpoint.description, "Fetch a List of Message Actions")
    XCTAssertEqual(router.category, "Fetch a List of Message Actions")
    XCTAssertEqual(router.service, .messageActions)
  }

  func test_FetchMessageActions_WhenChannelEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()
    let router = MessageActionsRouter(.fetch(channel: "", start: nil, end: nil, limit: nil),
                                      configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, router: router))
  }

  func test_FetchMessageActions_WithValidChannel_ReturnsActionsAndPaging() throws {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["fetchMessageAction_success"])

    let testAction = PubNubMessageActionBase(
      actionType: "reaction", actionValue: "smiley_face",
      actionTimetoken: 15_610_547_826_970_050, messageTimetoken: 15_610_547_826_969_050,
      publisher: "testUser", channel: "TestChannel"
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.fetchMessageActions(channel: "TestChannel") { result in
      switch result {
      case let .success((actions, next)):
        XCTAssertEqual(try? actions.first?.transcode(), testAction)
        XCTAssertEqual(next?.start, 15_610_547_826_970_050)
        XCTAssertEqual(next?.end, 15_645_905_639_093_361)
        XCTAssertEqual(next?.limit, 2)

      case let .failure(error):
        XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchMessageActions_WithNoActions_ReturnsEmptyList() throws {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["fetchMessageAction_success_empty"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.fetchMessageActions(channel: "TestChannel") { result in
      switch result {
      case let .success((actions, next)):
        XCTAssertTrue(actions.isEmpty)
        XCTAssertNil(next)

      case let .failure(error):
        XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchMessageActions_WhenInvalidSubscribeKey_ReturnsInvalidSubscribeKeyError() throws {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["fetchMessageAction_error_400"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.fetchMessageActions(channel: "TestChannel") { result in
      switch result {
      case .success:
        XCTFail("Request should fail.")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .invalidSubscribeKey)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchMessageActions_WhenForbidden_ReturnsForbiddenError() throws {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["fetchMessageAction_error_403"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.fetchMessageActions(channel: "TestChannel") { result in
      switch result {
      case .success:
        XCTFail("Request should fail.")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .forbidden)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Add Message Actions Tests

extension MessageActionsRouterTests {
  func test_AddMessageActionRouter_WithValidConfig_SetsExpectedEndpoint() {
    let config = TestPubNubFactory.makeConfig()
    let router = MessageActionsRouter(
      .add(channel: "TestChannel", type: "reaction", value: "smiley_face", timetoken: 0),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Add a Message Action")
    XCTAssertEqual(router.category, "Add a Message Action")
    XCTAssertEqual(router.service, .messageActions)
  }

  func test_AddMessageAction_WhenChannelEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()
    let router = MessageActionsRouter(.add(channel: "", type: "reaction", value: "smiley_face", timetoken: 0),
                                      configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, router: router))
  }

  func test_AddMessageAction_WithValidParams_ReturnsCreatedAction() throws {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["addMessageAction_success"])

    let testAction = PubNubMessageActionBase(
      actionType: "reaction", actionValue: "smiley_face",
      actionTimetoken: 15_610_547_826_970_050, messageTimetoken: 15_610_547_826_969_050,
      publisher: "testUser", channel: "TestChannel"
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.addMessageAction(
      channel: "TestChannel",
      type: "reaction", value: "smiley_face",
      messageTimetoken: 15_610_547_826_969_050
    ) { result in
      switch result {
      case let .success(action):
        XCTAssertEqual(try? action.transcode(), testAction)

      case let .failure(error):
        XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_AddMessageAction_WhenPartialSuccess207_ReturnsActionAndPublishError() throws {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")
    expectation.expectedFulfillmentCount = 1

    let sessions = try MockURLSession.mockSession(for: ["addMessageAction_success_207"])

    let testAction = PubNubMessageActionBase(
      actionType: "reaction", actionValue: "smiley_face",
      actionTimetoken: 15_610_547_826_970_050, messageTimetoken: 15_610_547_826_969_050,
      publisher: "testUser", channel: "TestChannel"
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.addMessageAction(
      channel: "TestChannel",
      type: "reaction", value: "smiley_face",
      messageTimetoken: 15_610_547_826_969_050
    ) { result in
      switch result {
      case let .success(action):
        XCTAssertEqual(try? action.transcode(), testAction)
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .failedToPublish)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_AddMessageAction_WhenBadRequest_ReturnsBadRequestError() throws {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["addMessageAction_error_400"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.addMessageAction(
      channel: "TestChannel",
      type: "reaction", value: "smiley_face",
      messageTimetoken: 15_610_547_826_969_050
    ) { result in
      switch result {
      case .success:
        XCTFail("Request should fail.")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .badRequest)
        XCTAssertEqual(error.pubNubError?.details, ["Request payload contained invalid input.", "Missing field"])
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_AddMessageAction_WhenForbidden_ReturnsForbiddenError() throws {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["addMessageAction_error_403"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.addMessageAction(
      channel: "TestChannel",
      type: "reaction", value: "smiley_face",
      messageTimetoken: 15_610_547_826_969_050
    ) { result in
      switch result {
      case .success:
        XCTFail("Request should fail.")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .forbidden)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_AddMessageAction_WhenConflict_ReturnsConflictError() throws {
    let expectation = self.expectation(description: "409 Error Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["addMessageAction_error_409"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.addMessageAction(
      channel: "TestChannel",
      type: "reaction", value: "smiley_face",
      messageTimetoken: 15_610_547_826_969_050
    ) { result in
      switch result {
      case .success:
        XCTFail("Request should fail.")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .conflict)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Remove Message Actions Tests

extension MessageActionsRouterTests {
  func test_RemoveMessageActionRouter_WithValidConfig_SetsExpectedEndpoint() {
    let config = TestPubNubFactory.makeConfig()
    let router = MessageActionsRouter(.remove(channel: "TestChannel", message: 0, action: 0), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Remove a Message Action")
    XCTAssertEqual(router.category, "Remove a Message Action")
    XCTAssertEqual(router.service, .messageActions)
  }

  func test_RemoveMessageAction_WhenChannelEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()
    let emptyChannel = MessageActionsRouter(.remove(channel: "", message: 0, action: 0), configuration: config)
    XCTAssertEqual(emptyChannel.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, router: emptyChannel))
  }

  func test_RemoveMessageAction_WithValidParams_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["removeMessageAction_success"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.removeMessageActions(
      channel: "TestChannel",
      message: 15_610_547_826_969_050,
      action: 15_610_547_826_970_050
    ) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveMessageAction_WhenPartialSuccess207_ReturnsPublishError() throws {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")
    expectation.expectedFulfillmentCount = 1

    let sessions = try MockURLSession.mockSession(for: ["removeMessageAction_success_207"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.removeMessageActions(
      channel: "TestChannel",
      message: 15_610_547_826_969_050,
      action: 15_610_547_826_970_050
    ) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .failedToPublish)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveMessageAction_WhenNothingToDelete_ReturnsNothingToDeleteError() throws {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["removeMessageAction_error_400_noMessage"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.removeMessageActions(
      channel: "TestChannel",
      message: 15_610_547_826_969_050,
      action: 15_610_547_826_970_050
    ) { result in
      switch result {
      case .success:
        XCTFail("Request should fail.")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .nothingToDelete)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveMessageAction_WhenInvalidUUID_ReturnsInvalidUUIDError() throws {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["removeMessageAction_error_400"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.removeMessageActions(
      channel: "TestChannel",
      message: 15_610_547_826_969_050,
      action: 15_610_547_826_970_050
    ) { result in
      switch result {
      case .success:
        XCTFail("Request should fail.")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .invalidUUID)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveMessageAction_WhenForbidden_ReturnsForbiddenError() throws {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["removeMessageAction_error_403"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.removeMessageActions(
      channel: "TestChannel",
      message: 15_610_547_826_969_050,
      action: 15_610_547_826_970_050
    ) { result in
      switch result {
      case .success:
        XCTFail("Request should fail.")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .forbidden)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - MessageActions Response Payload

extension MessageActionsRouterTests {
  func test_MessageActionsResponsePayload_WithDefaults_SetsExpectedValues() {
    let payload = MessageActionsResponsePayload(actions: [], start: 123)
    XCTAssertEqual(payload.actions, [])
    XCTAssertEqual(payload.start, 123)
    XCTAssertEqual(payload.end, nil)
    XCTAssertEqual(payload.limit, nil)
  }

  func test_MessageActionPayload_WithInvalidTimetokenStrings_DecodesToZero() throws {
    let action = try XCTUnwrap(
      ["uuid": "UUIDString", "type": "ActionType", "value": "ValueType",
       "actionTimetoken": "notTimetoken", "messageTimetoken": "notTimetoken"].jsonData
    )
    let payload = try? JSONDecoder().decode(MessageActionPayload.self, from: action)

    XCTAssertEqual(payload?.actionTimetoken, 0)
    XCTAssertEqual(payload?.messageTimetoken, 0)
  }
}
