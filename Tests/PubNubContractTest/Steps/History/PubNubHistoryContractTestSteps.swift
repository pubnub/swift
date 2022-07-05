//
//  PubNubHistoryContractTestSteps.swift
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
