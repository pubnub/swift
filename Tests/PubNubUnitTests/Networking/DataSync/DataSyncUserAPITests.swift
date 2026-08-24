//
//  DataSyncUserAPITests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncUserAPITests: DataSyncAPITestCase {
  func test_GetUsers_IgnoresEntityClassOnTheWire() throws {
    let expectation = self.expectation(description: "getUsers")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getUsers(limit: 20) { [self] result in
      switch result {
      case let .success((users, next)):
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users[0].id, "alice")
        XCTAssertEqual(users[0].classLevel, .subKey)
        XCTAssertEqual(users[0].classVersion, 1)
        XCTAssertEqual(users[0].createdAt, createdAt)
        XCTAssertEqual(users[0].updatedAt, updatedAt)
        XCTAssertEqual(users[0].status, "active")
        XCTAssertNil(users[0].expiresAt)
        XCTAssertPayload(users[0].payload, equals: UserPayload(name: "Alice Summers"))
        XCTAssertEqual(next?.hasNext, false)
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GetUser_DecodesAllFields() throws {
    let expectation = self.expectation(description: "getUser")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getUser("alice") { [self] result in
      switch result {
      case let .success(user):
        XCTAssertEqual(user.id, "alice")
        XCTAssertEqual(user.eTag, "3w5e111uk7djz")
        XCTAssertEqual(user.expiresAt, expiresAt)
        XCTAssertPayload(user.payload, equals: UserPayload(name: "Alice Summers", email: "alice@example.com"))
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_CreateUser_DecodesCreatedUser() throws {
    let expectation = self.expectation(description: "createUser")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.createUser(
      classVersion: 1,
      id: "alice",
      payload: UserPayload(name: "Alice Summers")
    ) { result in
      switch result {
      case let .success(user):
        XCTAssertEqual(user.id, "alice")
        XCTAssertEqual(user.classVersion, 1)
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveUser_SucceedsWithoutBody() throws {
    let expectation = self.expectation(description: "removeUser")
    let sessions = try MockURLSession.mockSession(for: ["datasync_remove_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.removeUser("alice") { result in
      if case let .failure(error) = result {
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
