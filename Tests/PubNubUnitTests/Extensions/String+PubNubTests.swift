//
//  String+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class StringPubNubTests: XCTestCase {
  func test_PresenceChannelName_ForRegularChannel_AppendsPnpres() {
    let channel = "channelName"
    let presece = "channelName-pnpres"

    XCTAssertEqual(channel.presenceChannelName, presece)
  }

  func test_IsPresenceChannelName_ForRegularAndPresenceChannel_ReturnsCorrectBool() {
    let channel = "channelName"
    let presece = "channelName-pnpres"

    XCTAssertFalse(channel.isPresenceChannelName)
    XCTAssertTrue(presece.isPresenceChannelName)
  }

  func test_URLEncodeSlash_WithSlashCharacter_EncodesCorrectly() {
    let userInput = "unsanitary/input".urlEncodeSlash
    let path = "/path/component/\(userInput)/end"

    let sanitaryInput = userInput.replacingOccurrences(of: "/", with: "%2F")
    let sanitaryPath = "/path/component/\(sanitaryInput)/end"

    XCTAssertEqual(path, sanitaryPath)
  }
}
