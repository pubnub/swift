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
  func test_GetChannel_DecodesAllFields() throws {
    let expectation = self.expectation(description: "getChannel")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getChannel(id: "general") { [self] result in
      switch result {
      case let .success(channel):
        XCTAssertEqual(channel.id, "general")
        XCTAssertEqual(channel.className, "Channel")
        XCTAssertEqual(channel.classLevel, .subKey)
        XCTAssertEqual(channel.classVersion, 1)
        XCTAssertEqual(channel.createdAt, createdAt)
        XCTAssertEqual(channel.expiresAt, expiresAt)
        XCTAssertPayload(channel.payload, equals: ChannelPayload(name: "General", description: "Company-wide announcements"))
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_CreateChannel_WithClassNameAndLevel_SendsThemInBody() throws {
    let expectation = self.expectation(description: "createChannel class identity")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.createChannel(
      className: "PrivateChannel",
      classVersion: 2,
      classLevel: .subKey,
      id: "general"
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    let body = try requestBody(sessions.mockSession)

    XCTAssertEqual(body["entityClass"]?.stringOptional, "PrivateChannel")
    XCTAssertEqual(body["entityClassVersion"]?.intOptional, 2)
    XCTAssertEqual(body["entityClassLevel"]?.stringOptional, "SubKey")
  }

  func test_UpdateChannel_DecodesUpdatedChannel() throws {
    let expectation = self.expectation(description: "updateChannel")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.updateChannel(
      id: "general",
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
