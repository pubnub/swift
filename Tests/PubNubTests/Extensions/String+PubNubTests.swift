//
//  String+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class StringPubNubTests: XCTestCase {
  func testPresenceChannel() {
    let channel = "channelName"
    let presece = "channelName-pnpres"

    XCTAssertEqual(channel.presenceChannelName, presece)
  }

  func testIsPresenceChannel() {
    let channel = "channelName"
    let presece = "channelName-pnpres"

    XCTAssertFalse(channel.isPresenceChannelName)
    XCTAssertTrue(presece.isPresenceChannelName)
  }

  func testURLEncodeSlash() {
    let userInput = "unsanitary/input".urlEncodeSlash
    let path = "/path/component/\(userInput)/end"

    let sanitaryInput = userInput.replacingOccurrences(of: "/", with: "%2F")
    let sanitaryPath = "/path/component/\(sanitaryInput)/end"

    XCTAssertEqual(path, sanitaryPath)
  }
}
