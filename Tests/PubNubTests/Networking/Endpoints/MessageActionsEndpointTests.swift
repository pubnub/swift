//
//  MessageActionsEndpointTests.swift
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

final class MessageActionsEndpointTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")
  let testMessageAction = ConcreteMessageAction(type: "reaction", value: "smiley_face")

  // MARK: - Fetch Message Actions Tests

  func testFetchAll_Endpoint() {
    let endpoint = Endpoint.fetchMessageActions(channel: "TestChannel", start: nil, end: nil, limit: nil)

    XCTAssertEqual(endpoint.description, "Fetch a List of Message Actions")
    XCTAssertEqual(endpoint.category, .fetchMessageActions)
    XCTAssertEqual(endpoint.operationCategory, .messageActions)
    XCTAssertNil(endpoint.validationError)
  }

  func testFetchAll_Endpoint_ValidationError() {
    let endpoint = Endpoint.fetchMessageActions(channel: "", start: nil, end: nil, limit: nil)

    XCTAssertEqual(endpoint.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, endpoint: endpoint))
  }

  func testFetchAll_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.fetchMessageActions(channel: "TestChannel", start: 0, end: 1, limit: 2)

    XCTAssertEqual(endpoint.associatedValue.count, 4)

    XCTAssertEqual(endpoint.associatedValue["channel"] as? String, "TestChannel")
    XCTAssertEqual(endpoint.associatedValue["start"] as? Timetoken, 0)
    XCTAssertEqual(endpoint.associatedValue["end"] as? Timetoken, 1)
    XCTAssertEqual(endpoint.associatedValue["limit"] as? Int, 2)
  }

  func testFetchAll_Success() {
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

  func testFetchAll_Success_empty() {
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

  func testFetchAll_error_400() {
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

  func testFetchAll_error_403() {
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

extension MessageActionsEndpointTests {
  func testAdd_Endpoint() {
    let endpoint = Endpoint.addMessageAction(channel: "TestChannel", message: testMessageAction, timetoken: 0)

    XCTAssertEqual(endpoint.description, "Add a Message Action")
    XCTAssertEqual(endpoint.category, .addMessageAction)
    XCTAssertEqual(endpoint.operationCategory, .messageActions)
    XCTAssertNil(endpoint.validationError)
  }

  func testAdd_Endpoint_ValidationError() {
    let endpoint = Endpoint.addMessageAction(channel: "", message: testMessageAction, timetoken: 0)

    XCTAssertEqual(endpoint.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, endpoint: endpoint))

    let invalidTimetoken = Endpoint.addMessageAction(channel: "TestChannel", message: testMessageAction, timetoken: -1)

    XCTAssertEqual(invalidTimetoken.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, endpoint: endpoint))
  }

  func testAdd_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.addMessageAction(channel: "TestChannel", message: testMessageAction, timetoken: 0)

    XCTAssertEqual(endpoint.associatedValue.count, 3)

    XCTAssertEqual(endpoint.associatedValue["channel"] as? String, "TestChannel")
    XCTAssertEqual(endpoint.associatedValue["message"] as? ConcreteMessageAction, testMessageAction)
    XCTAssertEqual(endpoint.associatedValue["timetoken"] as? Timetoken, 0)
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

extension MessageActionsEndpointTests {
  func testRemove_Endpoint() {
    let endpoint = Endpoint.removeMessageAction(channel: "TestChannel", message: 0, action: 0)

    XCTAssertEqual(endpoint.description, "Remove a Message Action")
    XCTAssertEqual(endpoint.category, .removeMessageAction)
    XCTAssertEqual(endpoint.operationCategory, .messageActions)
    XCTAssertNil(endpoint.validationError)
  }

  func testRemove_Endpoint_ValidationError() {
    let emptyChannel = Endpoint.removeMessageAction(channel: "", message: 0, action: 0)
    XCTAssertEqual(emptyChannel.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, endpoint: emptyChannel))

    let invalidMessageTimetoken = Endpoint.removeMessageAction(channel: "TestChannel", message: -1, action: 0)
    XCTAssertEqual(invalidMessageTimetoken.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, endpoint: invalidMessageTimetoken))

    let invalidActionTimetoken = Endpoint.removeMessageAction(channel: "TestChannel", message: 0, action: -1)
    XCTAssertEqual(invalidActionTimetoken.validationError?.pubNubError,
                   PubNubError(.missingRequiredParameter, endpoint: invalidActionTimetoken))
  }

  func testRemove_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.removeMessageAction(channel: "TestChannel", message: 0, action: 1)

    XCTAssertEqual(endpoint.associatedValue.count, 3)

    XCTAssertEqual(endpoint.associatedValue["channel"] as? String, "TestChannel")
    XCTAssertEqual(endpoint.associatedValue["message"] as? Timetoken, 0)
    XCTAssertEqual(endpoint.associatedValue["action"] as? Timetoken, 1)
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

  // swiftlint:disable:next file_length
}
