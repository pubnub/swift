//
//  MessageActionsRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class MessageActionsRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)
}

// MARK: - Fetch Message Actions Tests

extension MessageActionsRouterTests {
  func testFetch_Router() {
    let router = MessageActionsRouter(.fetch(channel: "TestChannel", start: nil, end: nil, limit: nil),
                                      configuration: config)

    XCTAssertEqual(router.endpoint.description, "Fetch a List of Message Actions")
    XCTAssertEqual(router.category, "Fetch a List of Message Actions")
    XCTAssertEqual(router.service, .messageActions)
  }

  func testFetch_Router_ValidationError() {
    let router = MessageActionsRouter(.fetch(channel: "", start: nil, end: nil, limit: nil),
                                      configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, router: router))
  }

  func testFetch_Success() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["fetchMessageAction_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testAction = PubNubMessageActionBase(
      actionType: "reaction", actionValue: "smiley_face",
      actionTimetoken: 15_610_547_826_970_050, messageTimetoken: 15_610_547_826_969_050,
      publisher: "testUser", channel: "TestChannel"
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testFetch_Success_empty() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["fetchMessageAction_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testFetch_error_400() {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["fetchMessageAction_error_400"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testFetch_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["fetchMessageAction_error_403"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
  func testAdd_Router() {
    let router = MessageActionsRouter(
      .add(channel: "TestChannel", type: "reaction", value: "smiley_face", timetoken: 0),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Add a Message Action")
    XCTAssertEqual(router.category, "Add a Message Action")
    XCTAssertEqual(router.service, .messageActions)
  }

  func testAdd_Router_ValidationError() {
    let router = MessageActionsRouter(.add(channel: "", type: "reaction", value: "smiley_face", timetoken: 0),
                                      configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, router: router))
  }

  func testAdd_Success() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["addMessageAction_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testAction = PubNubMessageActionBase(
      actionType: "reaction", actionValue: "smiley_face",
      actionTimetoken: 15_610_547_826_970_050, messageTimetoken: 15_610_547_826_969_050,
      publisher: "testUser", channel: "TestChannel"
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testAdd_success_207() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")
    expectation.expectedFulfillmentCount = 2

    guard let sessions = try? MockURLSession.mockSession(for: ["addMessageAction_success_207"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testAction = PubNubMessageActionBase(
      actionType: "reaction", actionValue: "smiley_face",
      actionTimetoken: 15_610_547_826_970_050, messageTimetoken: 15_610_547_826_969_050,
      publisher: "testUser", channel: "TestChannel"
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testAdd_error_400() {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["addMessageAction_error_400"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
        XCTAssertEqual(error.pubNubError?.details, ["Missing field"])
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testAdd_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["addMessageAction_error_403"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testAdd_error_409() {
    let expectation = self.expectation(description: "409 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["addMessageAction_error_409"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
  func testRemove_Router() {
    let router = MessageActionsRouter(.remove(channel: "TestChannel", message: 0, action: 0), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Remove a Message Action")
    XCTAssertEqual(router.category, "Remove a Message Action")
    XCTAssertEqual(router.service, .messageActions)
  }

  func testRemove_Router_ValidationError() {
    let emptyChannel = MessageActionsRouter(.remove(channel: "", message: 0, action: 0), configuration: config)
    XCTAssertEqual(emptyChannel.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, router: emptyChannel))
  }

  func testRemove_Success() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["removeMessageAction_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testRemove_success_207() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")
    expectation.expectedFulfillmentCount = 2

    guard let sessions = try? MockURLSession.mockSession(for: ["removeMessageAction_success_207"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testRemove_error_400() {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["removeMessageAction_error_400_noMessage"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testRemove_error_400_NoMessage() {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["removeMessageAction_error_400"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testRemove_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["removeMessageAction_error_403"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
  func testInit_Defaults() {
    let payload = MessageActionsResponsePayload(actions: [], start: 123)
    XCTAssertEqual(payload.actions, [])
    XCTAssertEqual(payload.start, 123)
    XCTAssertEqual(payload.end, nil)
    XCTAssertEqual(payload.limit, nil)
  }

  func testMessageActionPayload_Decode_InvalidTimetokenStrings() {
    guard let action = ["uuid": "UUIDString", "type": "ActionType", "value": "ValueType",
                        "actionTimetoken": "notTimetoken", "messageTimetoken": "notTimetoken"].jsonData
    else {
      return XCTFail("Could not convert object to data")
    }
    let payload = try? JSONDecoder().decode(MessageActionPayload.self, from: action)

    XCTAssertEqual(payload?.actionTimetoken, 0)
    XCTAssertEqual(payload?.messageTimetoken, 0)
  }

  // swiftlint:disable:next file_length
}
