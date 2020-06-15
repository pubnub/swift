//
//  MessageActionsEndpointIntegrationTests.swift
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

import PubNub
import XCTest

class MessageActionsEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: MessageActionsEndpointIntegrationTests.self)
  let testChannel = "SwiftITest-MessageActions"

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  func testAddThenDeleteMessageAction() {
    let addExpect = expectation(description: "Add Message Action Expectation")
    let fetchExpect = expectation(description: "Fetch Message Action Expectation")
    let removeExpect = expectation(description: "Remove Message Action Expectation")

    let addedEventExcept = expectation(description: "Add Message Action Event Expectation")
    let removedEventExcept = expectation(description: "Remove Message Action Event Expectation")

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
              client.fetchMessageActions(channel: self.testChannel) { [unowned self] actionResult in
                switch actionResult {
                case let .success((messageActions, _)):
                  // Assert that we successfully published to server
                  XCTAssertNotNil(messageActions.filter { $0.actionTimetoken == messageAction.actionTimetoken })
                  // Remove the message
                  client.removeMessageActions(
                    channel: self.testChannel,
                    message: messageAction.messageTimetoken,
                    action: messageAction.actionTimetoken
                  ) { removeResult in
                    switch removeResult {
                    case let .success((channel, _, _)):
                      XCTAssertEqual(channel, self.testChannel)
                    case .failure:
                      XCTFail("Failed Fetching Message Actions")
                    }
                    removeExpect.fulfill()
                  }
                case .failure:
                  XCTFail("Failed Fetching Message Actions")
                }
                fetchExpect.fulfill()
              }
            case .failure:
              XCTFail("Failed Fetching Message Actions")
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

    defer { listener.cancel() }

    wait(for: [addExpect, fetchExpect, removeExpect, addedEventExcept, removedEventExcept], timeout: 10.0)
  }

  func testFetchMessageActionsEndpoint() {
    let fetchExpect = expectation(description: "Fetch Message Actions Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    client.fetchMessageActions(channel: testChannel) { result in
      switch result {
      case .success:
        break
      case .failure:
        XCTFail("Failed Fetching Message Actions")
      }
      fetchExpect.fulfill()
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

        client.fetchMessageHistory(for: [self.testChannel], includeActions: true) { historyResult in
          switch historyResult {
          case let .success((messages, _)):
            let channelHistory = messages[self.testChannel]
            XCTAssertNotNil(channelHistory)

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

    wait(for: [addExpect, historyExpect], timeout: 10.0)
  }
}
