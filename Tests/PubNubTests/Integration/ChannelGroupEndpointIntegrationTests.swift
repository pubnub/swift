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
  
  func testListChannelGroups() {
    let listGroupsExpect = expectation(description: "List Channel Groups Response")
    let client = PubNub(configuration: config)
    
    client.listChannelGroups { result in
      switch result {
      case let .success(groups):
        XCTAssertNotNil(groups)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listGroupsExpect.fulfill()
    }
    
    wait(for: [listGroupsExpect], timeout: 10.0)
  }
  
  func testListChannelsInGroup() {
    let listChannelsExpect = expectation(description: "List Channels Response")
    let client = PubNub(configuration: config)
    let testGroup = "testListChannelsGroup"
    let testChannels = ["testChannel1", "testChannel2"]
    
    // First add channels to the group
    client.add(channels: testChannels, to: testGroup) { _ in
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
    let client = PubNub(configuration: config)
    let testGroup = "testAddChannelsGroup"
    let testChannels = ["testChannel1", "testChannel2"]
    
    client.add(channels: testChannels, to: testGroup) { result in
      switch result {
      case let .success(response):
        XCTAssertEqual(response.group, testGroup)
        XCTAssertEqual(Set(response.channels), Set(testChannels))
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
    
    wait(for: [addChannelsExpect], timeout: 10.0)
  }
  
  func testRemoveChannelsFromGroup() {
    let removeChannelsExpect = expectation(description: "Remove Channels Response")
    let client = PubNub(configuration: config)
    let testGroup = "testRemoveChannelsGroup"
    let testChannels = ["testChannel1", "testChannel2"]
    
    // First add channels to the group
    client.add(channels: testChannels, to: testGroup) { _ in
      // Then remove them
      client.remove(channels: testChannels, from: testGroup) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.group, testGroup)
          XCTAssertEqual(Set(response.channels), Set(testChannels))
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
    
    wait(for: [removeChannelsExpect], timeout: 10.0)
  }
  
  func testRemoveChannelGroup() {
    let removeGroupExpect = expectation(description: "Remove Channel Group Response")
    let client = PubNub(configuration: config)
    let testGroup = "testRemoveGroup"
    let testChannels = ["testChannel1", "testChannel2"]
    
    // First add channels to the group
    client.add(channels: testChannels, to: testGroup) { _ in
      // Then remove the group
      client.remove(channelGroup: testGroup) { result in
        switch result {
        case let .success(group):
          XCTAssertEqual(group, testGroup)
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
    
    wait(for: [removeGroupExpect], timeout: 10.0)
  }
}
