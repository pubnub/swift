//
//  PubNubTimeContractTestSteps.swift
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

public class PubNubTimeContractTestSteps: PubNubContractTestCase {
  override public func setup() {
    startCucumberHookEventsListening()

    When("I request current time") { _, _ in
      let timeExpect = self.expectation(description: "Time Response")

      self.client.time { result in
        switch result {
        case let .success(timetoken):
          self.handleResult(result: timetoken)
        case let .failure(error):
          self.handleResult(result: error)
        }
        timeExpect.fulfill()
      }

      self.wait(for: [timeExpect], timeout: 60.0)
    }
  }
}
