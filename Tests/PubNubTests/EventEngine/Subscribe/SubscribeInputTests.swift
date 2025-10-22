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

@testable import PubNubSDK

class SubscribeInputTests: XCTestCase {
  func test_WithoutPresence() {
    let input = SubscribeInput(channels: ["c1", "c2"])    
    let expAllSubscribedChannelNames = ["c1", "c2"]
    let expSubscribedChannelNames = ["c1", "c2"]

    XCTAssertTrue(input.channelNames(withPresence: true).sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(input.channelNames(withPresence: false).sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(input.channelGroupNames(withPresence: true).isEmpty)
    XCTAssertTrue(input.channelGroupNames(withPresence: false).isEmpty)
  }
  
  func test_WithPresence() {
    let input = SubscribeInput(channels: ["c1", "c1-pnpres", "c2"], channelGroups: ["g1", "g1-pnpres", "g2"])
    let expAllSubscribedChannelNames = ["c1", "c1-pnpres", "c2"]
    let expSubscribedChannelNames = ["c1", "c2"]
    let expAllSubscribedGroups = ["g1", "g1-pnpres", "g2"]
    let expSubscribedGroups = ["g1", "g2"]

    XCTAssertTrue(input.channelNames(withPresence: false).sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(input.channelNames(withPresence: true).sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(input.channelGroupNames(withPresence: false).sorted(by: <).elementsEqual(expSubscribedGroups))
    XCTAssertTrue(input.channelGroupNames(withPresence: true).sorted(by: <).elementsEqual(expAllSubscribedGroups))
  }
  
  func test_AddWithDuplicates() {
    let input = SubscribeInput(channels: ["c1", "c2", "c2-pnpres"], channelGroups: ["g1", "g2"])
    let newInput = input.adding(channels: ["c3", "c3-pnpres"], and: ["g3"])

    let diff = newInput.difference(from: input)
    let expAllSubscribedChannelNames = ["c1", "c2", "c2-pnpres", "c3", "c3-pnpres"]
    let expSubscribedChannelNames = ["c1", "c2", "c3"]
    let expAllSubscribedGroupNames = ["g1", "g2", "g3"]
    let expSubscribedGroupNames = ["g1", "g2", "g3"]
    
    XCTAssertTrue(newInput.channelNames(withPresence: true).sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(newInput.channelNames(withPresence: false).sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(newInput.channelGroupNames(withPresence: false).sorted(by: <).elementsEqual(expSubscribedGroupNames))
    XCTAssertTrue(newInput.channelGroupNames(withPresence: true).sorted(by: <).elementsEqual(expAllSubscribedGroupNames))
    XCTAssertTrue(diff.addedChannels == ["c3", "c3-pnpres"])
    XCTAssertTrue(diff.addedChannelGroups == ["g3"])
  }
  
  func test_Remove() {
    let input1 = SubscribeInput(channels: ["c1", "c2", "c3"], channelGroups: ["g1", "g2", "g3"])
    let newInput = input1.removing(channels: ["c1", "c3"], and: ["g1", "g3"])
    let diff = newInput.difference(from: input1)
    
    let expAllSubscribedChannelNames = ["c2"]
    let expSubscribedChannelNames = ["c2"]
    let expAllSubscribedGroupNames = ["g2"]
    let expSubscribedGroupNames = ["g2"]
    
    let expRemovedChannels = Set(["c1", "c3"])
    let expRemovedGroups = Set(["g1", "g3"])
    
    XCTAssertTrue(newInput.channelNames(withPresence: true).sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(newInput.channelNames(withPresence: false).sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(newInput.channelGroupNames(withPresence: false).sorted(by: <).elementsEqual(expSubscribedGroupNames))
    XCTAssertTrue(newInput.channelGroupNames(withPresence: true).sorted(by: <).elementsEqual(expAllSubscribedGroupNames))
    XCTAssertTrue(diff.removedChannels == expRemovedChannels)
    XCTAssertTrue(diff.removedChannelGroups == expRemovedGroups)
  }
  
  func test_RemovePresenceOnly() {
    let input1 = SubscribeInput(
      channels: [
        "c1",
        "c1-pnpres",
        "c2",
        "c2-pnpres",
        "c3",
        "c3-pnpres"
      ],
      channelGroups: [
        "g1",
        "g1-pnpres",
        "g2",
        "g2-pnpres",
        "g3",
        "g3-pnpres",
        "g4",
        "g4-pnpres"
      ]
    )
    
    let presenceChannelsToRemove: Set<String> = ["c1-pnpres", "c3-pnpres"]
    let presenceGroupsToRemove: Set<String> = ["g1-pnpres", "g3-pnpres"]
    let newInput = input1.removing(channels: presenceChannelsToRemove, and: presenceGroupsToRemove)
    
    let expAllSubscribedChannelNames = ["c1", "c2", "c2-pnpres", "c3"]
    let expSubscribedChannelNames = ["c1", "c2", "c3"]
    let expAllSubscribedGroupNames = ["g1", "g2", "g2-pnpres", "g3", "g4", "g4-pnpres"]
    let expSubscribedGroupNames = ["g1", "g2", "g3", "g4"]
        
    XCTAssertTrue(newInput.channelNames(withPresence: true).sorted(by: <).elementsEqual(expAllSubscribedChannelNames))
    XCTAssertTrue(newInput.channelNames(withPresence: false).sorted(by: <).elementsEqual(expSubscribedChannelNames))
    XCTAssertTrue(newInput.channelGroupNames(withPresence: false).sorted(by: <).elementsEqual(expSubscribedGroupNames))
    XCTAssertTrue(newInput.channelGroupNames(withPresence: true).sorted(by: <).elementsEqual(expAllSubscribedGroupNames))
  }
  
  func test_RemoveNonExistent() {
    let input = SubscribeInput(channels: ["c1", "c2"], channelGroups: ["g1", "g2", "g3"])    
    let newInput = input.removing(channels: ["c1", "c3", "c4"], and: ["g1", "g3", "g5"])
    let diff = newInput.difference(from: input)
    
    let expChannelNames = ["c2"]
    let expGroupNames = ["g2"]
    
    // Verify the diff only contains channels/groups that were actually in the original input
    let expRemovedChannels = Set(["c1"])
    let expRemovedGroups = Set(["g1", "g3"])
    
    XCTAssertTrue(newInput.channelNames(withPresence: false).sorted(by: <).elementsEqual(expChannelNames))
    XCTAssertTrue(newInput.channelGroupNames(withPresence: false).sorted(by: <).elementsEqual(expGroupNames))
    XCTAssertTrue(diff.removedChannels == expRemovedChannels)
    XCTAssertTrue(diff.removedChannelGroups == expRemovedGroups)
    XCTAssertTrue(diff.addedChannels.isEmpty)
    XCTAssertTrue(diff.addedChannelGroups.isEmpty)
  }
}
