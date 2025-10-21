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
  let config = PubNubConfiguration(bundle: Bundle(for: FilesEndpointIntegrationTests.self))
  
  func testFetchMessageHistory() throws {
    let channel = randomString()
    let messagesToSend = ["A", "B", "C"]
    
    // Populate the channel with test messages
    populate(channel: channel, with: messagesToSend)
    
    let historyExpect = expectation(description: "History Response")
    let client = PubNub(configuration: config)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [unowned client] in
      client.fetchMessageHistory(for: [channel]) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.messagesByChannel.count, 1)
          XCTAssertEqual(response.messagesByChannel[channel]?.count, messagesToSend.count)
          XCTAssertEqual(response.messagesByChannel[channel]?.compactMap { $0.payload.stringOptional }, messagesToSend)
        case let .failure(error):
          XCTFail("Failed to fetch history: \(error)")
        }
        historyExpect.fulfill()
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
    
    wait(for: [historyExpect], timeout: 15.0)
  }
  
  func testDeleteMessageHistory() throws {
    let channel = randomString()
    let messagesToSend = ["A", "B", "C"]
    
    // Populate the channel with test messages
    populate(channel: channel, with: messagesToSend)

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

  func testFetchMessageHistoryWithWithStartAndEnd() throws {
    let channel = randomString()
    let messagesToSend = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    
    // Populate the channel with test messages
    let timetokens = populate(channel: channel, with: messagesToSend)
    let startIndex = 2
    let endIndex = 7
    
    let startTimetoken = timetokens[startIndex]
    let endTimetoken = timetokens[endIndex]
    let historyExpect = expectation(description: "History Response")
    let client = PubNub(configuration: config)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [unowned client] in
      client.fetchMessageHistory(
        for: [channel],
        page: PubNubBoundedPageBase(start: startTimetoken, end: endTimetoken)
      ) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.messagesByChannel.count, 1)
          XCTAssertEqual(response.messagesByChannel[channel]?.count, (startIndex.advanced(by: 1)...endIndex).count)
          XCTAssertEqual(response.messagesByChannel[channel]?.compactMap { $0.payload.stringOptional }, Array(messagesToSend[startIndex.advanced(by: 1)...endIndex]))
        case let .failure(error):
          XCTFail("Failed to fetch history: \(error)")
        }
        historyExpect.fulfill()
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
    
    wait(for: [historyExpect], timeout: 15.0)
  }
  
  func testMessageCounts() throws {
    let channel1 = randomString()
    let channel2 = randomString()
    let channel3 = randomString()
    
    let messagesToSend = ["A", "B", "C"]
    
    // Populate both channels with test messages
    populate(channel: channel1, with: messagesToSend)
    populate(channel: channel2, with: messagesToSend)

    let messageCountsExpect = expectation(description: "Message Counts Response")
    let client = PubNub(configuration: config)
    
    client.messageCounts(channels: [channel1, channel2, channel3]) { result in
      switch result {
      case let .success(response):
        XCTAssertEqual(response.count, 3)
        XCTAssertEqual(response[channel1], messagesToSend.count)
        XCTAssertEqual(response[channel2], messagesToSend.count)
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

  func testFetchMessageHistoryWithOtherOptions() throws {
    let channel = randomString()
    let messagesToSend = ["A", "B", "C"]
    
    // Populate the channel with test messages
    populate(channel: channel, with: messagesToSend)

    let historyExpect = expectation(description: "History Response")
    let client = PubNub(configuration: config)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [unowned client] in
      client.fetchMessageHistory(
        for: [channel],
        includeMeta: true,
        includeUUID: true,
        includeMessageType: true,
        includeCustomMessageType: true
      ) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.messagesByChannel.count, 1)
          XCTAssertEqual(response.messagesByChannel[channel]?.count, messagesToSend.count)
          XCTAssertEqual(response.messagesByChannel[channel]?.compactMap { $0.payload.stringOptional }, messagesToSend)
          XCTAssertEqual(response.messagesByChannel[channel]?.compactMap { $0.metadata?.stringOptional }, messagesToSend.map { $0 + "meta" })
          XCTAssertEqual(response.messagesByChannel[channel]?.compactMap { $0.customMessageType?.stringOptional }, messagesToSend.map { $0 + "type" })
          XCTAssertEqual(response.messagesByChannel[channel]?.compactMap { $0.publisher?.stringOptional }, messagesToSend.map { _ in client.configuration.userId })
          XCTAssertEqual(response.messagesByChannel[channel]?.compactMap { $0.messageType.rawValue }, messagesToSend.map { _ in PubNubMessageType.message.rawValue })
        case let .failure(error):
          XCTFail("Failed to fetch history: \(error)")
        }
        historyExpect.fulfill()
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
    
    wait(for: [historyExpect], timeout: 15.0)
  }
}

// MARK: - Channel Population

private extension HistoryEndpointIntegrationTests {
  @discardableResult
  func populate(channel: String, with messages: [String]) -> [Timetoken] {
    let publishExpect = expectation(description: "Publish Messages")
    publishExpect.expectedFulfillmentCount = messages.count
    publishExpect.assertForOverFulfill = true
    
    let client = PubNub(configuration: config)
    var timetokens: [Timetoken] = []
    
    func publishNext(_ remainingMessages: [String]) {
      if let message = remainingMessages.first {
        client.publish(
          channel: channel,
          message: message,
          customMessageType: message + "type",
          meta: message + "meta"
        ) { result in
          switch result {
          case let .success(timetoken):
            timetokens.append(timetoken)
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
    
    return timetokens
  }
}
