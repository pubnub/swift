//
//  DataSyncMembershipAPITests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncMembershipAPITests: DataSyncAPITestCase {
  func test_GetMemberships_DecodesChannelAndUserIds() throws {
    let expectation = self.expectation(description: "getMemberships")
    let sessions = try MockURLSession.mockSession(for: ["datasync_membership_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getMemberships(channelId: "general", limit: 5) { [self] result in
      switch result {
      case let .success((memberships, next)):
        XCTAssertEqual(memberships.count, 1)
        XCTAssertEqual(memberships[0].id, "general__alice")
        XCTAssertEqual(memberships[0].channelId, "general")
        XCTAssertEqual(memberships[0].userId, "alice")
        XCTAssertEqual(memberships[0].classVersion, 1)
        XCTAssertEqual(memberships[0].createdAt, createdAt)
        XCTAssertEqual(memberships[0].updatedAt, updatedAt)
        XCTAssertEqual(memberships[0].status, "active")
        XCTAssertNil(memberships[0].expiresAt)
        XCTAssertPayload(memberships[0].payload, equals: MembershipPayload(role: "admin"))

        XCTAssertEqual(next?.cursor, "TjQw")
        XCTAssertEqual(next?.hasNext, true)
        XCTAssertEqual(next?.limit, 5)
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_CreateMembership_DecodesCreatedMembership() throws {
    let expectation = self.expectation(description: "createMembership")
    let sessions = try MockURLSession.mockSession(for: ["datasync_membership_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.createMembership(
      channelId: "general",
      userId: "alice",
      classVersion: 1,
      payload: MembershipPayload(role: "admin")
    ) { result in
      switch result {
      case let .success(membership):
        XCTAssertEqual(membership.channelId, "general")
        XCTAssertEqual(membership.userId, "alice")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveMembership_SucceedsWithoutBody() throws {
    let expectation = self.expectation(description: "removeMembership")
    let sessions = try MockURLSession.mockSession(for: ["datasync_remove_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.removeMembership("general__alice") { result in
      if case let .failure(error) = result {
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
