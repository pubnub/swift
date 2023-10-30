//
//  Test+PubNubUserEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
@testable import PubNubUser

import XCTest

class PubNubUserEventTests: XCTestCase {
  let testUser = PubNubUser(
    id: "TestUserId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    externalId: "TestExternalID",
    profileURL: URL(string: "http://example.com"),
    email: "TestEmail",
    custom: nil,
    updated: Date.distantPast,
    eTag: "TestETag"
  )

  var listener = PubNubUserListener()

  func testUserListener_Emit_UpdateEvent() {
    let expectation = XCTestExpectation(description: "User Update Event")
    expectation.expectedFulfillmentCount = 2

    let patchedUser = PubNubUser(
      id: "TestUserId",
      name: "NewName",
      type: testUser.type,
      status: testUser.status,
      externalId: testUser.externalId,
      profileURL: testUser.profileURL,
      email: testUser.email,
      custom: testUser.custom,
      updated: Date.distantFuture,
      eTag: "NewETag"
    )

    let entityEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .updated,
      type: .user,
      data: [
        "id": patchedUser.id,
        "name": patchedUser.name,
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": patchedUser.eTag
      ]
    )

    let malformedEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .updated,
      type: .user,
      data: AnyJSON("")
    )

    listener.didReceiveUserEvents = { [unowned self] events in
      for event in events {
        switch event {
        case let .userUpdated(patch):
          XCTAssertEqual(patchedUser, self.testUser.apply(patch))
        case .userRemoved:
          XCTFail("User Removed Event should not fire")
        }
      }
      expectation.fulfill()
    }

    listener.didReceiveUserEvent = { [unowned self] event in
      switch event {
      case let .userUpdated(patch):
        XCTAssertEqual(patchedUser, self.testUser.apply(patch))
      case .userRemoved:
        XCTFail("User Removed Event should not fire")
      }
      expectation.fulfill()
    }

    listener.emit(entity: [malformedEvent, entityEvent])

    wait(for: [expectation], timeout: 1.0)
  }

  func testUserListener_Emit_RemoveEvent() {
    let expectation = XCTestExpectation(description: "User Update Event")
    expectation.expectedFulfillmentCount = 2

    let entityEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .removed,
      type: .user,
      data: [
        "id": testUser.id
      ]
    )

    let malformedEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .removed,
      type: .user,
      data: AnyJSON("")
    )

    listener.didReceiveUserEvents = { [unowned self] events in
      for event in events {
        switch event {
        case let .userRemoved(user):
          XCTAssertEqual(self.testUser.id, user.id)
        case .userUpdated:
          XCTFail("User Updated Event should not fire")
        }
      }
      expectation.fulfill()
    }

    listener.didReceiveUserEvent = { [unowned self] event in
      switch event {
      case let .userRemoved(user):
        XCTAssertEqual(self.testUser.id, user.id)
      case .userUpdated:
        XCTFail("User Updated Event should not fire")
      }
      expectation.fulfill()
    }

    listener.emit(entity: [malformedEvent, entityEvent])

    wait(for: [expectation], timeout: 1.0)
  }
}
