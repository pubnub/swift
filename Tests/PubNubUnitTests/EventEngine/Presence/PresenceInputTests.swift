//
//  PresenceInputTests.swift
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

class PresenceInputTests: XCTestCase {
  func test_InitWithChannelsAndGroups() {
    let input = PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    
    XCTAssertTrue(input.channels.sorted(by: <).elementsEqual(["c1", "c2"]))
    XCTAssertTrue(input.groups.sorted(by: <).elementsEqual(["g1", "g2"]))
    XCTAssertFalse(input.isEmpty)
  }
  
  func test_InitEmpty() {
    let input = PresenceInput()
    
    XCTAssertTrue(input.channels.isEmpty)
    XCTAssertTrue(input.groups.isEmpty)
    XCTAssertTrue(input.isEmpty)
  }
  
  func test_InitRemovesDuplicates() {
    let input = PresenceInput(channels: ["c1", "c1", "c2"], groups: ["g1", "g2", "g2"])
    
    XCTAssertTrue(input.channels.sorted(by: <).elementsEqual(["c1", "c2"]))
    XCTAssertTrue(input.groups.sorted(by: <).elementsEqual(["g1", "g2"]))
  }
  
  func test_AdditionOperator() {
    let input1 = PresenceInput(channels: ["c1", "c2"], groups: ["g1"])
    let input2 = PresenceInput(channels: ["c3"], groups: ["g2", "g3"])
    let result = input1 + input2
    
    XCTAssertTrue(result.channels.sorted(by: <).elementsEqual(["c1", "c2", "c3"]))
    XCTAssertTrue(result.groups.sorted(by: <).elementsEqual(["g1", "g2", "g3"]))
  }
  
  func test_AddWithDuplicates() {
    let input1 = PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    let input2 = PresenceInput(channels: ["c2", "c3"], groups: ["g2", "g3"])
    let result = input1 + input2
    
    XCTAssertTrue(result.channels.sorted(by: <).elementsEqual(["c1", "c2", "c3"]))
    XCTAssertTrue(result.groups.sorted(by: <).elementsEqual(["g1", "g2", "g3"]))
  }
  
  func test_SubtractionOperator() {
    let input1 = PresenceInput(channels: ["c1", "c2", "c3"], groups: ["g1", "g2", "g3"])
    let input2 = PresenceInput(channels: ["c1", "c3"], groups: ["g1", "g3"])
    let result = input1 - input2
    
    XCTAssertTrue(result.channels.sorted(by: <).elementsEqual(["c2"]))
    XCTAssertTrue(result.groups.sorted(by: <).elementsEqual(["g2"]))
  }
  
  func test_SubtractNonExistent() {
    let input1 = PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2", "g3"])
    let input2 = PresenceInput(channels: ["c1", "c3", "c4"], groups: ["g1", "g3", "g5"])
    let result = input1 - input2
    
    XCTAssertTrue(result.channels.sorted(by: <).elementsEqual(["c2"]))
    XCTAssertTrue(result.groups.sorted(by: <).elementsEqual(["g2"]))
  }
  
  func test_Equality() {
    let input1 = PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    let input2 = PresenceInput(channels: ["c2", "c1"], groups: ["g2", "g1"])
    let input3 = PresenceInput(channels: ["c1", "c3"], groups: ["g1", "g2"])
    
    XCTAssertTrue(input1 == input2)
    XCTAssertFalse(input1 == input3)
  }
  
  func test_AddEmptyInput() {
    let input1 = PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    let input2 = PresenceInput()
    let result = input1 + input2
    
    XCTAssertTrue(result.channels.sorted(by: <).elementsEqual(["c1", "c2"]))
    XCTAssertTrue(result.groups.sorted(by: <).elementsEqual(["g1", "g2"]))
    XCTAssertTrue(result == input1)
  }
  
  func test_SubtractEmptyInput() {
    let input1 = PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    let input2 = PresenceInput()
    let result = input1 - input2
    
    XCTAssertTrue(result.channels.sorted(by: <).elementsEqual(["c1", "c2"]))
    XCTAssertTrue(result.groups.sorted(by: <).elementsEqual(["g1", "g2"]))
    XCTAssertTrue(result == input1)
  }
  
  func test_SubtractAll() {
    let input1 = PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    let input2 = PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    let result = input1 - input2
    
    XCTAssertTrue(result.channels.isEmpty)
    XCTAssertTrue(result.groups.isEmpty)
    XCTAssertTrue(result.isEmpty)
  }
}
