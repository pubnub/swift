//
//  SubscribeInputTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
import Foundation
import XCTest

@testable import PubNub

class SubscribeInputTests: XCTestCase {
  func test_ChannelsWithoutPresence() {
    let input = SubscribeInput(channels: [
      PubNubChannel(id: "first-channel"),
      PubNubChannel(id: "second-channel")
    ])
    
    let expectedAllSubscribedChannels = ["first-channel", "second-channel"]
    let expectedSubscribedChannels = ["first-channel", "second-channel"]

    XCTAssertTrue(input.subscribedChannels.sorted(by: <).elementsEqual(expectedSubscribedChannels))
    XCTAssertTrue(input.allSubscribedChannels.sorted(by: <).elementsEqual(expectedAllSubscribedChannels))
    XCTAssertTrue(input.subscribedGroups.isEmpty)
    XCTAssertTrue(input.allSubscribedGroups.isEmpty)
  }
  
  func test_ChannelsWithPresence() {
    let input = SubscribeInput(channels: [
      PubNubChannel(id: "first-channel", withPresence: true),
      PubNubChannel(id: "second-channel")
    ])
    
    let expectedAllSubscribedChannels = ["first-channel", "first-channel-pnpres", "second-channel"]
    let expectedSubscribedChannels = ["first-channel", "second-channel"]

    XCTAssertTrue(input.subscribedChannels.sorted(by: <).elementsEqual(expectedSubscribedChannels))
    XCTAssertTrue(input.allSubscribedChannels.sorted(by: <).elementsEqual(expectedAllSubscribedChannels))
    XCTAssertTrue(input.subscribedGroups.isEmpty)
    XCTAssertTrue(input.allSubscribedGroups.isEmpty)
  }
  
  func test_ChannelGroups() {
    let input = SubscribeInput(
      channels: [
        PubNubChannel(id: "first-channel"),
        PubNubChannel(id: "second-channel")
      ],
      groups: [
        PubNubChannel(channel: "group-1"),
        PubNubChannel(channel: "group-2")
      ]
    )
    
    let expectedAllSubscribedChannels = ["first-channel", "second-channel"]
    let expectedSubscribedChannels = ["first-channel", "second-channel"]
    let expectedAllSubscribedGroups = ["group-1", "group-2"]
    let expectedSubscribedGroups = ["group-1", "group-2"]
    
    XCTAssertTrue(input.subscribedChannels.sorted(by: <).elementsEqual(expectedSubscribedChannels))
    XCTAssertTrue(input.allSubscribedChannels.sorted(by: <).elementsEqual(expectedAllSubscribedChannels))
    XCTAssertTrue(input.subscribedGroups.sorted(by: <).elementsEqual(expectedSubscribedGroups))
    XCTAssertTrue(input.allSubscribedGroups.sorted(by: <).elementsEqual(expectedAllSubscribedGroups))
  }
  
  func test_addingInputContainsNoDuplicates() {
    let input1 = SubscribeInput(
      channels: [
        PubNubChannel(id: "c1"),
        PubNubChannel(id: "c2", withPresence: true)
      ],
      groups: [
        PubNubChannel(id: "g1"),
        PubNubChannel(id: "g2")
      ]
    )
    let result = input1 + SubscribeInput(channels: [
      PubNubChannel(id: "c1"),
      PubNubChannel(id: "c3", withPresence: true)
    ], groups: [
      PubNubChannel(id: "g1"),
      PubNubChannel(id: "g3")
    ])
    
    let expectedAllSubscribedChannels = ["c1", "c2", "c2-pnpres", "c3", "c3-pnpres"]
    let expectedSubscribedChannels = ["c1", "c2", "c3"]
    let expectedAllSubscribedGroups = ["g1", "g2", "g3"]
    let expectedSubscribedGroups = ["g1", "g2", "g3"]
    
    XCTAssertTrue(result.allSubscribedChannels.sorted(by: <).elementsEqual(expectedAllSubscribedChannels))
    XCTAssertTrue(result.subscribedChannels.sorted(by: <).elementsEqual(expectedSubscribedChannels))
    XCTAssertTrue(result.subscribedGroups.sorted(by: <).elementsEqual(expectedSubscribedGroups))
    XCTAssertTrue(result.allSubscribedGroups.sorted(by: <).elementsEqual(expectedAllSubscribedGroups))
  }
  
  func test_RemovingInput() {
    let input1 = SubscribeInput(
      channels: [
        PubNubChannel(id: "c1", withPresence: true),
        PubNubChannel(id: "c2", withPresence: true),
        PubNubChannel(id: "c3", withPresence: true)
      ],
      groups: [
        PubNubChannel(id: "g1"),
        PubNubChannel(id: "g2"),
        PubNubChannel(id: "g3")
      ]
    )
    
    let result = input1 - (channels: ["c1", "c3"], groups: ["g1", "g3"])
    let expectedAllSubscribedChannels = ["c2", "c2-pnpres"]
    let expectedSubscribedChannels = ["c2"]
    let expectedAllSubscribedGroups = ["g2"]
    let expectedSubscribedGroups = ["g2"]

    XCTAssertTrue(result.allSubscribedChannels.sorted(by: <).elementsEqual(expectedAllSubscribedChannels))
    XCTAssertTrue(result.subscribedChannels.sorted(by: <).elementsEqual(expectedSubscribedChannels))
    XCTAssertTrue(result.subscribedGroups.sorted(by: <).elementsEqual(expectedSubscribedGroups))
    XCTAssertTrue(result.allSubscribedGroups.sorted(by: <).elementsEqual(expectedAllSubscribedGroups))
  }
  
  func test_RemovingInputWithPresenceOnly() {
    let input1 = SubscribeInput(
      channels: [
        PubNubChannel(id: "c1", withPresence: true),
        PubNubChannel(id: "c2", withPresence: true),
        PubNubChannel(id: "c3", withPresence: true)
      ],
      groups: [
        PubNubChannel(id: "g1", withPresence: true),
        PubNubChannel(id: "g2", withPresence: true),
        PubNubChannel(id: "g3", withPresence: true)
      ]
    )
    
    let result = input1 - (
      channels: ["c1".presenceChannelName, "c2".presenceChannelName, "c3".presenceChannelName],
      groups: ["g1".presenceChannelName, "g3".presenceChannelName]
    )
    
    let expectedAllSubscribedChannels = ["c1", "c2", "c3"]
    let expectedSubscribedChannels = ["c1", "c2", "c3"]
    let expectedAllSubscribedGroups = ["g1", "g2", "g2-pnpres", "g3"]
    let expectedSubscribedGroups = ["g1", "g2", "g3"]

    XCTAssertTrue(result.allSubscribedChannels.sorted(by: <).elementsEqual(expectedAllSubscribedChannels))
    XCTAssertTrue(result.subscribedChannels.sorted(by: <).elementsEqual(expectedSubscribedChannels))
    XCTAssertTrue(result.subscribedGroups.sorted(by: <).elementsEqual(expectedSubscribedGroups))
    XCTAssertTrue(result.allSubscribedGroups.sorted(by: <).elementsEqual(expectedAllSubscribedGroups))
  }
}
