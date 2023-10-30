//
//  PubNubHistoryContractTestSteps.swift
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

public class PubNubHistoryContractTestSteps: PubNubContractTestCase {
  override public func setup() {
    startCucumberHookEventsListening()

    When("^I fetch message history for (.*) channel(s)?$") { args, _ in
      guard let type = args?.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }

      let historyExpect = self.expectation(description: "Fetch history Response")
      let channels = type == "multiple" ? ["test1", "test2"] : ["test"]

      self.client.fetchMessageHistory(for: channels) { result in
        switch result {
        case let .success((messagesByChannel, next)):
          self.handleResult(result: (messagesByChannel, next))
        case let .failure(error):
          self.handleResult(result: error)
        }
        historyExpect.fulfill()
      }

      self.wait(for: [historyExpect], timeout: 60.0)
    }

    Then("the response contains pagination info") { _, _ in
      guard let lastResult = self.lastResult() else {
        XCTAssert(false, "Fetch history didn't returned response")
        return
      }
      guard let result = lastResult as? (messagesByChannel: [String: [PubNubMessage]], next: PubNubBoundedPage?) else {
        XCTAssert(false, "Fetch history returned unexpected response")
        return
      }

      XCTAssertNotNil(result.next)
    }

    When("I fetch message history with message actions") { _, _ in
      let historyExpect = self.expectation(description: "Fetch history with action Response")

      self.client.fetchMessageHistory(for: ["test"], includeActions: true) { result in
        switch result {
        case let .success((messagesByChannel, next)):
          self.handleResult(result: (messagesByChannel, next))
        case let .failure(error):
          self.handleResult(result: error)
        }
        historyExpect.fulfill()
      }

      self.wait(for: [historyExpect], timeout: 60.0)
    }
  }
}
