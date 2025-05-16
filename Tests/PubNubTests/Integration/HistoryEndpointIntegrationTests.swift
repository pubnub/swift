//
//  HistoryEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest
import PubNubSDK

class HistoryEndpointIntegrationTests: XCTestCase {
  let config = PubNubConfiguration(from: Bundle(for: FilesEndpointIntegrationTests.self))
  
  func testFetchMessageHistory() throws {
    let channel = randomString()
    let messagesToSend = ["Message 1", "Message 2", "Message 3"]
    
    // Populate the channel with test messages
    populateChannel(channel, with: messagesToSend)
    
    let historyExpect = expectation(description: "History Response")
    let client = PubNub(configuration: config)
    
    client.fetchMessageHistory(for: [channel]) { result in
      switch result {
      case let .success(response):
        XCTAssertEqual(response.messagesByChannel.count, 1)
        XCTAssertEqual(response.messagesByChannel[channel]?.count, 3)
        XCTAssertEqual(response.messagesByChannel[channel]?.compactMap { $0.payload.stringOptional }, ["Message 1", "Message 2", "Message 3"])
      case let .failure(error):
        XCTFail("Failed to fetch history: \(error)")
      }
      historyExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.deleteMessageHistory(
          from: channel,
          completion: $0
        )
      }
    }
    
    wait(for: [historyExpect], timeout: 10.0)
  }
  
  func testDeleteMessageHistory() throws {
    let channel = randomString()
    let messagesToSend = ["Message 1", "Message 2", "Message 3"]
    
    // Populate the channel with test messages
    populateChannel(channel, with: messagesToSend)
    
    let deleteHistoryExpect = expectation(description: "History Response")
    let client = PubNub(configuration: config)
    
    client.deleteMessageHistory(from: channel) { [unowned client] _ in
      client.fetchMessageHistory(for: [channel]) { fetchHistoryResult in
        switch fetchHistoryResult {
        case let .success(historyResponse):
          XCTAssertTrue(historyResponse.messagesByChannel.isEmpty)
        case let .failure(error):
          XCTFail("Unexpected error: \(error)")
        }
        deleteHistoryExpect.fulfill()
      }
    }
    
    defer {
      waitForCompletion {
        client.deleteMessageHistory(
          from: channel,
          completion: $0
        )
      }
    }
    
    wait(for: [deleteHistoryExpect], timeout: 10.0)
  }
  
  func testMessageCounts() throws {
    let channel1 = randomString()
    let channel2 = randomString()
    let channel3 = randomString()
    
    let messagesToSend = ["Message 1", "Message 2", "Message 3"]
    
    // Populate both channels with test messages
    populateChannel(channel1, with: messagesToSend)
    populateChannel(channel2, with: messagesToSend)
    
    let messageCountsExpect = expectation(description: "Message Counts Response")
    let client = PubNub(configuration: config)
    
    client.messageCounts(channels: [channel1, channel2, channel3]) { result in
      switch result {
      case let .success(response):
        XCTAssertEqual(response.count, 3)
        XCTAssertEqual(response[channel1], 3)
        XCTAssertEqual(response[channel2], 3)
        XCTAssertEqual(response[channel3], 0)
      case let .failure(error):
        XCTFail("Failed to get message counts: \(error)")
      }
      messageCountsExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.deleteMessageHistory(
          from: channel1,
          completion: $0
        )
      }
      waitForCompletion {
        client.deleteMessageHistory(
          from: channel2,
          completion: $0
        )
      }
      waitForCompletion {
        client.deleteMessageHistory(
          from: channel3,
          completion: $0
        )
      }
    }
    
    wait(for: [messageCountsExpect], timeout: 10.0)
  }
}

// MARK: - Channel Population

private extension HistoryEndpointIntegrationTests {
  func populateChannel(_ channel: String, with messages: [String]) {
    let publishExpect = expectation(description: "Publish Messages")
    publishExpect.expectedFulfillmentCount = messages.count
    publishExpect.assertForOverFulfill = true
    
    let client = PubNub(configuration: config)
    
    func publishNext(_ remainingMessages: [String]) {
      if let message = remainingMessages.first {
        client.publish(channel: channel, message: message) { result in
          switch result {
          case .success:
            publishNext(Array(remainingMessages.dropFirst()))
          case let .failure(error):
            XCTFail("Failed to publish message: \(error)")
          }
          publishExpect.fulfill()
        }
      }
    }
    
    // Start the publishing process
    publishNext(messages)
    // Wait for all messages to be published
    wait(for: [publishExpect], timeout: 10.0)
  }
}
