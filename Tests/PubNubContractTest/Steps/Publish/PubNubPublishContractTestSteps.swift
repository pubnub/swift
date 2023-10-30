//
//  PubNubPublishContractTestSteps.swift
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

public class PubNubPublishContractTestSteps: PubNubContractTestCase {
  override public func setup() {
    startCucumberHookEventsListening()

    When("I publish a message") { _, _ in
      let publishMessageExpect = self.expectation(description: "Publish message Response")

      self.client.publish(channel: "test", message: "hello") { result in
        switch result {
        case let .success(timetoken):
          self.handleResult(result: timetoken)
        case let .failure(error):
          self.handleResult(result: error)
        }
        publishMessageExpect.fulfill()
      }

      self.wait(for: [publishMessageExpect], timeout: 60.0)
    }

    When("^I publish a message with (.*) metadata$") { args, _ in
      guard let type = args?.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }

      let publishMessageExpect = self.expectation(description: "Publish message with metadata Response")
      let meat: JSONCodable = type == "JSON" ? ["test-user": "bob"] : "test-user=bob"

      self.client.publish(channel: "test", message: "hello", meta: meat) { result in
        switch result {
        case let .success(timetoken):
          self.handleResult(result: timetoken)
        case let .failure(error):
          self.handleResult(result: error)
        }
        publishMessageExpect.fulfill()
      }

      self.wait(for: [publishMessageExpect], timeout: 60.0)
    }

    When("I send a signal") { _, _ in
      let sendSignalExpect = self.expectation(description: "Send signal Response")

      self.client.signal(channel: "test", message: "hello") { result in
        switch result {
        case let .success(timetoken):
          self.handleResult(result: timetoken)
        case let .failure(error):
          self.handleResult(result: error)
        }
        sendSignalExpect.fulfill()
      }

      self.wait(for: [sendSignalExpect], timeout: 60.0)
    }
  }
}
