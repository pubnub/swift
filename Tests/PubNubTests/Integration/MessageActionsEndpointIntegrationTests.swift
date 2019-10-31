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

  func testAddThenDeleteMessageAction() {
    let addExpect = expectation(description: "Add Message Action Expectation")
    let fetchExpect = expectation(description: "Fetch Message Action Expectation")
    let removeExpect = expectation(description: "Remove Message Action Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let messageAction = ConcreteMessageAction(type: "reaction", value: "smiley_face")

    client.publishWithMessageAction(
      channel: testChannel,
      message: "Hello!",
      messageAction: messageAction
    ) { [unowned self] publishResult in
      switch publishResult {
      case let .success(publishResponse):
        XCTAssertEqual(publishResponse.action.uuid, configuration.uuid)
        XCTAssertEqual(publishResponse.action.type, messageAction.type)
        XCTAssertEqual(publishResponse.action.value, messageAction.value)

        // Fetch the Message
        client.fetchMessageActions(channel: self.testChannel) { [unowned self] actionResult in
          switch actionResult {
          case let .success(fetchResponse):
            // Assert that we successfully published to server
            XCTAssertNotNil(fetchResponse.actions.filter { $0 == publishResponse.action })
            // Remove the message
            client.removeMessageActions(
              channel: self.testChannel,
              message: publishResponse.action.messageTimetoken,
              action: publishResponse.action.actionTimetoken
            ) { removeResult in
              switch removeResult {
              case let .success(removeResponse):
                XCTAssertEqual(removeResponse.message, .acknowledge)
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

    wait(for: [addExpect, fetchExpect, removeExpect], timeout: 10.0)
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

    let messageAction = ConcreteMessageAction(type: "reaction", value: "smiley_face")

    client.publishWithMessageAction(
      channel: testChannel,
      message: "Hello!",
      messageAction: messageAction
    ) { [unowned self] publishResult in
      switch publishResult {
      case let .success(publishResponse):
        XCTAssertEqual(publishResponse.action.uuid, configuration.uuid)
        XCTAssertEqual(publishResponse.action.type, messageAction.type)
        XCTAssertEqual(publishResponse.action.value, messageAction.value)

        client.fetchMessageHistory(for: [self.testChannel], fetchActions: true) { historyResult in
          switch historyResult {
          case let .success(channels):
            let channelHistory = channels[self.testChannel]
            XCTAssertNotNil(channelHistory)
            let message = channelHistory?.messages
              .filter { $0.timetoken == publishResponse.action.messageTimetoken }

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
