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
    
    When("^I fetch message history for '(.*)' channel$") { args, _ in
      guard let channel = args?.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }

      let historyExpect = self.expectation(description: "Fetch history Response")

      self.client.fetchMessageHistory(for: [channel]) { result in
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

    Match(["And"], "^history response contains messages (with|without) ('(.*)' and '(.*)') message types$") { args, _ in
      guard let matches = args, let inclusionFlag = matches.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }
      
      guard let lastResult = self.lastResult() else {
        XCTAssert(false, "Fetch history didn't returned response")
        return
      }
      
      guard let result = lastResult as? (messagesByChannel: [String: [PubNubMessageBase]], next: PubNubBoundedPage?),
        let channel = result.messagesByChannel.first?.key, let messages = result.messagesByChannel[channel] else {
        XCTAssert(false, "Fetch history returned unexpected response")
        return
      }
      
      XCTAssertGreaterThan(messages.count, 0)
      
      let messagesWithTypes = messages.compactMap { $0.messageType }
      XCTAssertFalse(inclusionFlag == "with" && messagesWithTypes.count == 0)
      XCTAssertFalse(inclusionFlag == "without" && messagesWithTypes.count > 0)
      
      if matches.count > 1 {
        XCTAssertTrue(messagesWithTypes.map { String(describing: $0.rawValue) }.allSatisfy { Array(matches[1...]).contains($0) })
      } else {
        XCTAssertEqual(inclusionFlag == "with" ? messages.count : 0, messagesWithTypes.count)
      }
    }
    
    Match(["And"], "^history response contains messages (with|without) ('(.*)' and '(.*)' )?types$") { args, _ in
      guard let matches = args, let inclusionFlag = matches.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }
      
      guard let lastResult = self.lastResult() else {
        XCTAssert(false, "Fetch history didn't returned response")
        return
      }
      
      guard let result = lastResult as? (messagesByChannel: [String: [PubNubMessageBase]], next: PubNubBoundedPage?),
        let channel = result.messagesByChannel.first?.key, let messages = result.messagesByChannel[channel] else {
        XCTAssert(false, "Fetch history returned unexpected response")
        return
      }
      
      XCTAssertGreaterThan(messages.count, 0)
      
      let messagesWithTypes = messages.compactMap { $0.type }
      XCTAssertFalse(inclusionFlag == "with" && messagesWithTypes.count == 0)
      XCTAssertFalse(inclusionFlag == "without" && messagesWithTypes.count > 0)
      
      if matches.count > 1 {
        XCTAssertTrue(messagesWithTypes.map { $0 }.allSatisfy { Array(matches[1...]).contains($0) })
      } else {
        XCTAssertEqual(inclusionFlag == "with" ? messages.count : 0, messagesWithTypes.count)
      }
    }
    
    Match(["And"], "^history response contains messages (with|without) space ids$") { args, _ in
      guard let matches = args, let inclusionFlag = matches.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }
      
      guard let lastResult = self.lastResult() else {
        XCTAssert(false, "Fetch history didn't returned response")
        return
      }
      
      guard let result = lastResult as? (messagesByChannel: [String: [PubNubMessageBase]], next: PubNubBoundedPage?),
        let channel = result.messagesByChannel.first?.key, let messages = result.messagesByChannel[channel] else {
        XCTAssert(false, "Fetch history returned unexpected response")
        return
      }
      
      XCTAssertGreaterThan(messages.count, 0)
      
      let messagesWithSpaceId = messages.map { $0.spaceId }.filter { $0 != nil }
      XCTAssertFalse(inclusionFlag == "with" && messagesWithSpaceId.count == 0)
      XCTAssertFalse(inclusionFlag == "without" && messagesWithSpaceId.count > 0)
      XCTAssertEqual(inclusionFlag == "with" ? messages.count : 0, messagesWithSpaceId.count)
    }
    
    When("^I fetch message history for (single|multiple) channel(s)?$") { args, _ in
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
    
    When("^I fetch message history with '(.*)' set to '(.*)' for '(.*)' channel$") { args, _ in
      guard args?.count == 3, let channel = args?[2] else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }
      
      /// Message types enabled by default and user can only opt-out them.
      var includeType = true
      var includeSpaceId = false
      
      if args?.first == "includeType" {
        includeType = args?[1] == "true"
      } else if args?.first == "includeSpaceId" {
        includeSpaceId = args?[1] == "true"
      }

      let historyExpect = self.expectation(description: "Fetch history Response")

      self.client.fetchMessageHistory(
        for: [channel],
        includeType: includeType,
        includeSpaceId: includeSpaceId
      ) { result in
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
