//
//  MessageActionsEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

class MessageActionsEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: MessageActionsEndpointIntegrationTests.self)
  let testChannel = "SwiftITest-MessageActions"

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  func testAddMessageAction() {
    let addExpect = expectation(description: "Add Message Action Expectation")
    let fetchExpect = expectation(description: "Fetch Message Action Expectation")
    let addedEventExcept = expectation(description: "Add Message Action Event Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)
    let actionType = "reaction"
    let actionValue = "smiley_face"

    let listener = SubscriptionListener()
    
    listener.didReceiveMessageAction = { event in
      switch event {
      case let .added(action):
        XCTAssertEqual(action.actionType, actionType)
        XCTAssertEqual(action.actionValue, actionValue)
        addedEventExcept.fulfill()
      case .removed:
        XCTFail("Unexpected message action removal")
      }
    }

    listener.didReceiveStatus = { [unowned self] status in
      switch status {
      case let .success(connection):
        if connection.isConnected {
          client.publishWithMessageAction(
            channel: self.testChannel,
            message: "Hello!",
            actionType: actionType, actionValue: actionValue
          ) { [unowned self] publishResult in
            switch publishResult {
            case let .success(messageAction):
              XCTAssertEqual(messageAction.publisher, configuration.uuid)
              XCTAssertEqual(messageAction.actionType, actionType)
              XCTAssertEqual(messageAction.actionValue, actionValue)

              // Fetch the Message
              client.fetchMessageActions(channel: self.testChannel) { actionResult in
                switch actionResult {
                case let .success((messageActions, _)):
                  // Assert that we successfully published to server
                  XCTAssertNotNil(messageActions.filter { $0.actionTimetoken == messageAction.actionTimetoken })
                case .failure:
                  XCTFail("Failed Fetching Message Actions")
                }
                fetchExpect.fulfill()
              }
            case .failure:
              XCTFail("Failed Adding Message Action")
            }
            addExpect.fulfill()
          }
        }
      case .failure:
        XCTFail("An error occurred")
      }
    }

    client.add(listener)
    client.subscribe(to: [testChannel])

    defer {
      listener.cancel()
      waitForCompletion { client.deleteMessageHistory(from: testChannel, completion: $0) }
    }

    wait(for: [addExpect, fetchExpect, addedEventExcept], timeout: 10.0)
  }

  func testDeleteMessageAction() {
    let addExpect = expectation(description: "Add Message Action Expectation")
    let removeExpect = expectation(description: "Remove Message Action Expectation")
    let removedEventExcept = expectation(description: "Remove Message Action Event Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)
    let actionType = "reaction"
    let actionValue = "smiley_face"

    let listener = SubscriptionListener()
    
    listener.didReceiveMessageAction = { event in
      switch event {
      case .added:
        XCTFail("Unexpected message action addition")
      case let .removed(action):
        XCTAssertEqual(action.actionType, actionType)
        XCTAssertEqual(action.actionValue, actionValue)
        removedEventExcept.fulfill()
      }
    }

    listener.didReceiveStatus = { [unowned self] status in
      switch status {
      case let .success(connection):
        if connection.isConnected {
          // First add a message action
          client.publishWithMessageAction(
            channel: self.testChannel,
            message: "Hello!",
            actionType: actionType, actionValue: actionValue
          ) { [unowned self] publishResult in
            switch publishResult {
            case let .success(messageAction):
              // Then remove it
              client.removeMessageActions(
                channel: self.testChannel,
                message: messageAction.messageTimetoken,
                action: messageAction.actionTimetoken
              ) { removeResult in
                switch removeResult {
                case let .success((channel, _, _)):
                  XCTAssertEqual(channel, self.testChannel)
                case .failure:
                  XCTFail("Failed Removing Message Action")
                }
                removeExpect.fulfill()
              }
            case .failure:
              XCTFail("Failed Adding Message Action")
            }
            addExpect.fulfill()
          }
        }
      case .failure:
        XCTFail("An error occurred")
      }
    }

    client.add(listener)
    client.subscribe(to: [testChannel])

    defer {
      listener.cancel()
      waitForCompletion { client.deleteMessageHistory(from: testChannel, completion: $0) }
    }

    wait(for: [addExpect, removeExpect, removedEventExcept], timeout: 10.0)
  }

  func testFetchMessageActionsEndpoint() {
    let fetchExpect = expectation(description: "Fetch Message Actions Expectation")
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    client.publish(channel: testChannel, message: "This is a message") { [unowned self] result in
      if let timetoken = try? result.get() {
        client.addMessageAction(
          channel: self.testChannel,
          type: "reaction",
          value: ":+1",
          messageTimetoken: timetoken
        ) { _ in
          client.fetchMessageActions(channel: self.testChannel) { fetchMessageActionsResult in
            if let messageActions = try? fetchMessageActionsResult.get().actions {
              XCTAssertEqual(messageActions.count, 1)
              XCTAssertEqual(messageActions.first?.actionType, "reaction")
              XCTAssertEqual(messageActions.first?.actionValue, ":+1")
            } else {
              XCTFail("Unexpected condition. Unable to retrieve fetched message actions")
            }
            fetchExpect.fulfill()
          }
        }
      } else {
        XCTFail("Unexpected condition")
      }
    }
    
    defer {
      waitForCompletion {
        client.deleteMessageHistory(
          from: testChannel,
          completion: $0
        )
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testHistoryWithMessageActions() {
    let addExpect = expectation(description: "Add Message Action Expectation")
    let historyExpect = expectation(description: "Fetch Message Action Expectation")
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)
    let actionType = "reaction"
    let actionValue = "smiley_face"

    client.publishWithMessageAction(
      channel: testChannel,
      message: "Hello!",
      actionType: actionType, actionValue: actionValue
    ) { [unowned self] publishResult in
      switch publishResult {
      case let .success(messageAction):
        XCTAssertEqual(messageAction.publisher, configuration.uuid)
        XCTAssertEqual(messageAction.actionType, actionType)
        XCTAssertEqual(messageAction.actionValue, actionValue)

        client.fetchMessageHistory(
          for: [self.testChannel],
          includeActions: true
        ) { historyResult in
          switch historyResult {
          case let .success((messages, _)):
            let channelHistory = messages[self.testChannel]
            let message = channelHistory?.filter { $0.published == messageAction.messageTimetoken }
            XCTAssertNotNil(message)
          case .failure:
            XCTFail("Failed Fetching Message Actions")
          }
          historyExpect.fulfill()
        }
      case .failure:
        XCTFail("Failed Fetching Message Actions")
      }
      addExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.deleteMessageHistory(
          from: testChannel,
          completion: $0
        )
      }
    }

    wait(for: [addExpect, historyExpect], timeout: 10.0)
  }
}
