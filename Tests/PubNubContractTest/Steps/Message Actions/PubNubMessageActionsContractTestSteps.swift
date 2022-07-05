//
//  PubNubMessageActionsContractTestSteps.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2021 PubNub Inc.
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

import Cucumberish
import Foundation
import PubNub

public class PubNubMessageActionsContractTestSteps: PubNubContractTestCase {
  override public func setup() {
    startCucumberHookEventsListening()

    When("I add a message action") { _, _ in
      let addMessageActionExpect = self.expectation(description: "Add message action Response")

      self.client.addMessageAction(channel: "test", type: "test", value: "contract", messageTimetoken: 1234) { result in
        switch result {
        case let .success(action):
          self.handleResult(result: action)
        case let .failure(error):
          self.handleResult(result: error)
        }
        addMessageActionExpect.fulfill()
      }

      self.wait(for: [addMessageActionExpect], timeout: 60.0)
    }

    When("I fetch message actions") { _, _ in
      let fetchActionsExpect = self.expectation(description: "Fetch message actions Response")

      self.client.fetchMessageActions(channel: "test", page: PubNubBoundedPageBase(limit: 10)) { result in
        switch result {
        case let .success((actions, next)):
          self.handleResult(result: (actions, next))
        case let .failure(error):
          self.handleResult(result: error)
        }
        fetchActionsExpect.fulfill()
      }

      self.wait(for: [fetchActionsExpect], timeout: 60.0)
    }

    When("I delete a message action") { _, _ in
      let deleteActionExpect = self.expectation(description: "Delete message action Response")

      self.client.removeMessageActions(channel: "test", message: 123_456_789, action: 123_456_799) { result in
        switch result {
        case let .success((channel, message, action)):
          self.handleResult(result: (channel, message, action))
        case let .failure(error):
          self.handleResult(result: error)
        }
        deleteActionExpect.fulfill()
      }

      self.wait(for: [deleteActionExpect], timeout: 60.0)
    }
  }
}
