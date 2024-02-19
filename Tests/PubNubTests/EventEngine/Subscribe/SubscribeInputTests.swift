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
    
    let expAllSubscribedChannelNames = ["first-channel", "second-channel"]
    let expSubscribedChannelNames = ["first-channel", "second-channel"]

    XCTAssertTrue(input.subscribedChannelNames.sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(input.allSubscribedChannelNames.sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(input.subscribedGroupNames.isEmpty)
    XCTAssertTrue(input.allSubscribedGroupNames.isEmpty)
  }
  
  func test_ChannelsWithPresence() {
    let input = SubscribeInput(channels: [
      PubNubChannel(id: "first-channel", withPresence: true),
      PubNubChannel(id: "second-channel")
    ])
    
    let expAllSubscribedChannelNames = ["first-channel", "first-channel-pnpres", "second-channel"]
    let expSubscribedChannelNames = ["first-channel", "second-channel"]

    XCTAssertTrue(input.subscribedChannelNames.sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(input.allSubscribedChannelNames.sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(input.subscribedGroupNames.isEmpty)
    XCTAssertTrue(input.allSubscribedGroupNames.isEmpty)
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
    
    let expAllSubscribedChannelNames = ["first-channel", "second-channel"]
    let expSubscribedChannelNames = ["first-channel", "second-channel"]
    let expAllSubscribedGroupNames = ["group-1", "group-2"]
    let expSubscribedGroupNames = ["group-1", "group-2"]
    
    XCTAssertTrue(input.subscribedChannelNames.sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(input.allSubscribedChannelNames.sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(input.subscribedGroupNames.sorted(by: <).elementsEqual(expSubscribedGroupNames))
    XCTAssertTrue(input.allSubscribedGroupNames.sorted(by: <).elementsEqual(expAllSubscribedGroupNames))
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
    let result = input1.adding(channels: [
      PubNubChannel(id: "c1"),
      PubNubChannel(id: "c3", withPresence: true)
    ], and: [
      PubNubChannel(id: "g1"),
      PubNubChannel(id: "g3")
    ])
    
    let newInput = result.newInput
    let expAllSubscribedChannelNames = ["c1", "c2", "c2-pnpres", "c3", "c3-pnpres"]
    let expSubscribedChannelNames = ["c1", "c2", "c3"]
    let expAllSubscribedGroupNames = ["g1", "g2", "g3"]
    let expSubscribedGroupNames = ["g1", "g2", "g3"]
    
    XCTAssertTrue(newInput.allSubscribedChannelNames.sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(newInput.subscribedChannelNames.sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(newInput.subscribedGroupNames.sorted(by: <).elementsEqual(expSubscribedGroupNames))
    XCTAssertTrue(newInput.allSubscribedGroupNames.sorted(by: <).elementsEqual(expAllSubscribedGroupNames))
    XCTAssertTrue(result.insertedChannels == [PubNubChannel(id: "c3", withPresence: true)])
    XCTAssertTrue(result.insertedGroups == [PubNubChannel(id: "g3")])
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
    let result = input1.removing(
      mainChannels: [PubNubChannel(id: "c1"), PubNubChannel(id: "c3")],
      presenceChannelsOnly: [],
      mainGroups: [PubNubChannel(id: "g1"), PubNubChannel(id: "g3")],
      presenceGroupsOnly: []
    )
    
    let newInput = result.newInput
    let expAllSubscribedChannelNames = ["c2", "c2-pnpres"]
    let expSubscribedChannelNames = ["c2"]
    let expAllSubscribedGroupNames = ["g2"]
    let expSubscribedGroupNames = ["g2"]
    
    let expRemovedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true)
    ]
    let expRemovedGroups = [
      PubNubChannel(id: "g1"),
      PubNubChannel(id: "g3")
    ]
    
    XCTAssertTrue(newInput.allSubscribedChannelNames.sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(newInput.subscribedChannelNames.sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(newInput.subscribedGroupNames.sorted(by: <).elementsEqual(expSubscribedGroupNames))
    XCTAssertTrue(newInput.allSubscribedGroupNames.sorted(by: <).elementsEqual(expAllSubscribedGroupNames))
    XCTAssertTrue(result.removedChannels == expRemovedChannels)
    XCTAssertTrue(result.removedGroups == expRemovedGroups)
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
    let presenceChannelsToRemove = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true)
    ]
    let presenceGroupsToRemove = [
      PubNubChannel(id: "g1"),
      PubNubChannel(id: "g3")
    ]
    let result = input1.removing(
      mainChannels: [],
      presenceChannelsOnly: presenceChannelsToRemove,
      mainGroups: [],
      presenceGroupsOnly: presenceGroupsToRemove
    )
    
    let newInput = result.newInput
    let expAllSubscribedChannelNames = ["c1", "c2", "c2-pnpres", "c3"]
    let expSubscribedChannelNames = ["c1", "c2", "c3"]
    let expAllSubscribedGroupNames = ["g1", "g2", "g2-pnpres", "g3"]
    let expSubscribedGroupNames = ["g1", "g2", "g3"]
        
    XCTAssertTrue(newInput.allSubscribedChannelNames.sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(newInput.subscribedChannelNames.sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(newInput.subscribedGroupNames.sorted(by: <).elementsEqual(expSubscribedGroupNames))
    XCTAssertTrue(newInput.allSubscribedGroupNames.sorted(by: <).elementsEqual(expAllSubscribedGroupNames))
  }
}
