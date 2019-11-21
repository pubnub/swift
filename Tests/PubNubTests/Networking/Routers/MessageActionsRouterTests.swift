//
//  MessageActionsRouterTests.swift
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

final class MessageActionsRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")
  let testMessageAction = ConcreteMessageAction(type: "reaction", value: "smiley_face")
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

    let action = MessageActionPayload(uuid: "terryterry69420", type: "reaction", value: "smiley_face",
                                      actionTimetoken: 15_610_547_826_970_050,
                                      messageTimetoken: 15_610_547_826_969_050)

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageActions(channel: "TestChannel") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.actions.first, action)
          XCTAssertEqual(payload.start, 15_610_547_826_970_050)
          XCTAssertEqual(payload.end, 15_645_905_639_093_361)
          XCTAssertEqual(payload.limit, 2)

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

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageActions(channel: "TestChannel") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.actions.count, 0)
          XCTAssertEqual(payload.start, nil)
          XCTAssertEqual(payload.end, nil)
          XCTAssertEqual(payload.limit, nil)

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

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageActions(channel: "TestChannel") { result in
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

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageActions(channel: "TestChannel") { result in
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
    let router = MessageActionsRouter(.add(channel: "TestChannel", message: testMessageAction, timetoken: 0),
                                      configuration: config)

    XCTAssertEqual(router.endpoint.description, "Add a Message Action")
    XCTAssertEqual(router.category, "Add a Message Action")
    XCTAssertEqual(router.service, .messageActions)
  }

  func testAdd_Router_ValidationError() {
    let router = MessageActionsRouter(.add(channel: "", message: testMessageAction, timetoken: 0),
                                      configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, router: router))
  }

  func testAdd_Success() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["addMessageAction_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let action = MessageActionPayload(uuid: "terryterry69420", type: "reaction", value: "smiley_face",
                                      actionTimetoken: 15_610_547_826_970_050,
                                      messageTimetoken: 15_610_547_826_969_050)

    PubNub(configuration: config, session: sessions.session)
      .addMessageAction(
        channel: "TestChannel",
        message: testMessageAction,
        messageTimetoken: 15_610_547_826_969_050
      ) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.action, action)

        case let .failure(error):
          XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testAdd_success_207() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["addMessageAction_success_207"]) else {
      return XCTFail("Could not create mock url session")
    }

    let action = MessageActionPayload(uuid: "user-456", type: "reaction", value: "smiley_face",
                                      actionTimetoken: 15_610_547_826_970_050,
                                      messageTimetoken: 15_610_547_826_969_050)

    let error = ErrorPayload(message: .successFailedToPublishEvent, source: "actions")

    PubNub(configuration: config, session: sessions.session)
      .addMessageAction(
        channel: "TestChannel",
        message: testMessageAction,
        messageTimetoken: 15_610_547_826_969_050
      ) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.action, action)
          XCTAssertEqual(payload.error, error)

        case let .failure(error):
          XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
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

    PubNub(configuration: config, session: sessions.session)
      .addMessageAction(
        channel: "TestChannel",
        message: testMessageAction,
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

    PubNub(configuration: config, session: sessions.session)
      .addMessageAction(
        channel: "TestChannel",
        message: testMessageAction,
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

    PubNub(configuration: config, session: sessions.session)
      .addMessageAction(
        channel: "TestChannel",
        message: testMessageAction,
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

    PubNub(configuration: config, session: sessions.session)
      .removeMessageActions(
        channel: "TestChannel",
        message: 15_610_547_826_969_050,
        action: 15_610_547_826_970_050
      ) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.message, .acknowledge)

        case let .failure(error):
          XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testRemove_success_207() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["removeMessageAction_success_207"]) else {
      return XCTFail("Could not create mock url session")
    }

    let error = ErrorPayload(message: .successFailedToPublishEvent, source: "actions")

    PubNub(configuration: config, session: sessions.session)
      .removeMessageActions(
        channel: "TestChannel",
        message: 15_610_547_826_969_050,
        action: 15_610_547_826_970_050
      ) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.message, .acknowledge)
          XCTAssertEqual(payload.error, error)
        case let .failure(error):
          XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
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

    PubNub(configuration: config, session: sessions.session)
      .removeMessageActions(
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

    PubNub(configuration: config, session: sessions.session)
      .removeMessageActions(
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

    PubNub(configuration: config, session: sessions.session)
      .removeMessageActions(
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

// MARK: - MessageAction Object

extension MessageActionsRouterTests {
  func testValidationError_MissingRequiredParameter() {
    let action = ConcreteMessageAction(type: "", value: "")

    XCTAssertEqual(action.validationError?.pubNubError?.reason, .missingRequiredParameter)
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

  func testInit_ActionsMore() {
    let payload = MessageActionsResponsePayload(actions: [], more: .init(start: 123, end: 890, limit: 5))
    XCTAssertEqual(payload.actions, [])
    XCTAssertEqual(payload.start, 123)
    XCTAssertEqual(payload.end, 890)
    XCTAssertEqual(payload.limit, 5)
  }

  func testEncode() {
    let payload = MessageActionsResponsePayload(actions: [], start: 123, end: 890, limit: 5)
    guard let encoded = try? JSONEncoder().encode(payload) else {
      return XCTFail("Failed to encode MessageActionsResponsePayload")
    }
    guard let deocded = try? JSONDecoder().decode(AnyJSON.self, from: encoded).dictionaryOptional else {
      return XCTFail("Failed to decode MessageActionsResponsePayload")
    }

    XCTAssertEqual(deocded["data"] as? [MessageActionPayload], [])
    XCTAssertEqual(deocded["start"] as? Timetoken, 123)
    XCTAssertEqual(deocded["end"] as? Timetoken, 890)
    XCTAssertEqual(deocded["limit"] as? Int, 5)
  }

  func testMessageActionPayload_Decode_InvalidTimetokenStrings() {
    guard let action = ["uuid": "UUIDString", "type": "ActionType", "value": "ValueType",
                        "actionTimetoken": "notTimetoken", "messageTimetoken": "notTimetoken"].jsonData else {
      return XCTFail("Could not convert object to data")
    }
    let payload = try? JSONDecoder().decode(MessageActionPayload.self, from: action)

    XCTAssertEqual(payload?.actionTimetoken, 0)
    XCTAssertEqual(payload?.messageTimetoken, 0)
  }

  func testMessageActionMorePaylaod_Decode_InvalidTimetokenStrings() {
    guard let action = ["limit": 1].jsonData else {
      return XCTFail("Could not convert object to data")
    }
    let payload = try? JSONDecoder().decode(MessageActionMorePaylaod.self, from: action)

    XCTAssertEqual(payload?.start, nil)
    XCTAssertEqual(payload?.end, nil)
  }

  // swiftlint:disable:next file_length
}
