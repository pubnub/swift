//
//  PubNubPublishContractTestSteps.swift
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

import Foundation
import Cucumberish
import PubNub


public class PubNubPublishContractTestSteps: PubNubContractTestCase {
  public override func setup() {
    self.startCucumberHookEventsListening()
    
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
