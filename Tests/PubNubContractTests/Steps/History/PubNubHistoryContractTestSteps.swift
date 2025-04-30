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
import PubNubSDK

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
    
    Match(["And"], "^history response contains messages (with|without) (?:customMessageType|'([^']*)' and '([^']*)' (?:message )?types?)$") { args, _ in
      guard let matches = args, let inclusionFlag = matches.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }
      guard let lastResult = self.lastResult() else {
        XCTFail("Fetch history didn't returned response"); return
      }
      guard
        let result = lastResult as? (messagesByChannel: [String: [PubNubMessageBase]], next: PubNubBoundedPage?),
        let channel = result.messagesByChannel.first?.key, let messages = result.messagesByChannel[channel]
      else {
        XCTFail("Fetch history returned unexpected response"); return
      }
      
      XCTAssertGreaterThan(messages.count, 0)
      
      var messagesWithTypes: [String] = []
      
      switch self.currentScenario?.name {
      case "Client can fetch history without customMessageType enabled by default":
        messagesWithTypes = messages.compactMap { $0.customMessageType }
      case "Client can fetch history with customMessageType":
        messagesWithTypes = messages.compactMap { $0.customMessageType }
      case "Client can fetch history with message types":
        messagesWithTypes = messages.compactMap { String(describing: $0.messageType.rawValue) }
      default:
        XCTFail("Unexpected condition")
      }
      
      XCTAssertFalse(inclusionFlag == "with" && messagesWithTypes.count == 0)
      XCTAssertFalse(inclusionFlag == "without" && messagesWithTypes.count > 0)
      
      if matches.count > 1 {
        XCTAssertTrue(messagesWithTypes.map { String(describing: $0.rawValue) }.allSatisfy { Array(matches[1...]).contains($0) })
      } else {
        XCTAssertEqual(inclusionFlag == "with" ? messages.count : 0, messagesWithTypes.count)
      }
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
    
    When("^I fetch message history with (messageType|customMessageType) for '(.*)' channel$") { args, _ in
      guard let type = args?.first, let channel = args?.last else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }
      
      let historyExpect = self.expectation(description: "Fetch history Response")
      let includeMessageType = true
      let includeCustomMessageType = type == "customMessageType"
      
      self.client.fetchMessageHistory(
        for: [channel],
        includeMessageType: includeMessageType,
        includeCustomMessageType: includeCustomMessageType
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
      
      if args?.first == "include_custom_message_type" {
        includeType = args?[1] == "true"
      }
      
      let historyExpect = self.expectation(description: "Fetch history Response")

      self.client.fetchMessageHistory(
        for: [channel],
        includeCustomMessageType: includeType
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
