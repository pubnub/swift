//
//  ChannelGroupEndpointIntegrationTests.swift
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

final class ChannelGroupEndpointIntegrationTests: XCTestCase {
  let config = PubNubConfiguration(from: Bundle(for: ChannelGroupEndpointIntegrationTests.self))
  
  func testListChannelsInGroup() {
    let listChannelsExpect = expectation(description: "List Channels Response")
    let client = PubNub(configuration: config)
    let testGroup = randomString()
    let testChannels = [randomString(), randomString()]
    
    // First add channels to the group
    client.add(channels: testChannels, to: testGroup) { [unowned client] _ in
      // Then list channels in the group
      client.listChannels(for: testGroup) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.group, testGroup)
          XCTAssertEqual(Set(response.channels), Set(testChannels))
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        listChannelsExpect.fulfill()
      }
    }
    
    defer {
      waitForCompletion {
        client.remove(
          channels: testChannels,
          from: testGroup,
          completion: $0
        )
      }
      waitForCompletion {
        client.remove(
          channelGroup: testGroup,
          completion: $0
        )
      }
    }
    
    wait(for: [listChannelsExpect], timeout: 10.0)
  }
  
  func testAddChannelsToGroup() {
    let addChannelsExpect = expectation(description: "Add Channels Response")
    let listChannelsExpect = expectation(description: "List Channels Response")
    
    let client = PubNub(configuration: config)
    let testGroup = randomString()
    let testChannels = [randomString(), randomString()]
    
    client.add(channels: testChannels, to: testGroup) { [unowned client] result in
      switch result {
      case let .success(addChannelsResponse):
        XCTAssertEqual(Set(addChannelsResponse.channels), Set(testChannels))
        XCTAssertEqual(addChannelsResponse.group, testGroup)        
        // Fetch the channels for the group and verify they are the same as the ones added
        client.listChannels(for: testGroup) { listChannelsResult in
          switch listChannelsResult {
          case let .success((group, channels)):
            XCTAssertEqual(group, testGroup)
            XCTAssertEqual(Set(channels), Set(testChannels))
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          listChannelsExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      addChannelsExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.remove(
          channels: testChannels,
          from: testGroup,
          completion: $0
        )
      }
      waitForCompletion {
        client.remove(
          channelGroup: testGroup,
          completion: $0
        )
      }
    }
    
    wait(for: [addChannelsExpect, listChannelsExpect], timeout: 100.0)
  }
  
  func testRemoveChannelsFromGroup() {
    let removeChannelsExpect = expectation(description: "Remove Channels Response")
    let listChannelsExpect = expectation(description: "List Channels Response")
    
    let client = PubNub(configuration: config)
    let testGroup = randomString()
    let testChannels = [randomString(), randomString()]
    
    // First add channels to the group
    client.add(channels: testChannels, to: testGroup) { [unowned client] _ in
      // Then remove them
      client.remove(channels: testChannels, from: testGroup) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.group, testGroup)
          XCTAssertEqual(Set(response.channels), Set(testChannels))
          // Fetch the channels for the group and verify they are empty
          client.listChannels(for: testGroup) { listChannelsResult in
            switch listChannelsResult {
            case let .success((group, channels)):
              XCTAssertEqual(group, testGroup)
              XCTAssertTrue(channels.isEmpty)
            case let .failure(error):
              XCTFail("Failed due to error: \(error)")
            }
            listChannelsExpect.fulfill()
          }
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        removeChannelsExpect.fulfill()
      }
    }
    
    defer {
      waitForCompletion {
        client.remove(
          channels: testChannels,
          from: testGroup,
          completion: $0
        )
      }
      waitForCompletion {
        client.remove(
          channelGroup: testGroup,
          completion: $0
        )
      }
    }
    
    wait(for: [removeChannelsExpect, listChannelsExpect], timeout: 10.0)
  }
  
  func testRemoveChannelGroup() {
    let removeGroupExpect = expectation(description: "Remove Channel Group Response")
    let listGroupsExpect = expectation(description: "List Groups Response")

    let client = PubNub(configuration: config)
    let testGroup = randomString()
    let testChannels = [randomString(), randomString()]
    
    // First add channels to the group
    client.add(channels: testChannels, to: testGroup) { [unowned client] _ in
      // Then remove the group
      client.remove(channelGroup: testGroup) { result in
        switch result {
        case let .success(group):
          XCTAssertEqual(group, testGroup)
          // Fetch the groups and verify the tested group is not in the list
          client.listChannelGroups { listGroupsResult in
            switch listGroupsResult {
            case let .success(groups):
              XCTAssertFalse(groups.contains { $0 == testGroup })
            case let .failure(error):
              XCTFail("Failed due to error: \(error)")
            }
            listGroupsExpect.fulfill()
          }
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        removeGroupExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.remove(
          channels: testChannels,
          from: testGroup,
          completion: $0
        )
      }
      waitForCompletion {
        client.remove(
          channelGroup: testGroup,
          completion: $0
        )
      }
    }
    
    wait(for: [removeGroupExpect, listGroupsExpect], timeout: 10.0)
  }
}
