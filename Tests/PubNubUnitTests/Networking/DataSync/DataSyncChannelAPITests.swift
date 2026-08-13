//
//  DataSyncChannelAPITests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncChannelAPITests: DataSyncAPITestCase {
  func test_GetChannel_IgnoresEntityClassOnTheWire() throws {
    let expectation = self.expectation(description: "getChannel")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getChannel("general") { [self] result in
      switch result {
      case let .success(channel):
        XCTAssertEqual(channel.id, "general")
        XCTAssertEqual(channel.classLevel, .subKey)
        XCTAssertEqual(channel.classVersion, 1)
        XCTAssertEqual(channel.createdAt, createdAt)
        XCTAssertNil(channel.expiresAt)
        XCTAssertPayload(channel.payload, equals: ChannelPayload(name: "General", description: "Company-wide announcements"))
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_PatchChannel_DecodesPatchedChannel() throws {
    let expectation = self.expectation(description: "patchChannel")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.patchChannel(
      "general",
      operations: [.replace(path: "/payload/name", value: "General")],
      ifMatchesEtag: "3w5e111uk7djz"
    ) { result in
      switch result {
      case let .success(channel):
        XCTAssertEqual(channel.id, "general")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
