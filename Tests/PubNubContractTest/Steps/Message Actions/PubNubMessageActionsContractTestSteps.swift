//
//  PubNubMessageActionsContractTestSteps.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
