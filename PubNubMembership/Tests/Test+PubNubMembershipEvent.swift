//
//  Test+PubNubMembershipEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
@testable import PubNubMembership
import PubNubSpace
import PubNubUser

import XCTest

class PubNubMembershipEventTests: XCTestCase {
  let testMembership = PubNubMembership(
    user: PubNubUser(id: "TestUserId"),
    space: PubNubSpace(id: "TestSpaceId"),
    status: "TestStatus",
    custom: MembershipCustom(value: "Tester"),
    updated: Date.distantPast,
    eTag: "TestETag"
  )

  var listener = PubNubMembershipListener()

  func testMembershipListener_Emit_UpdateEvent() {
    let expectation = XCTestExpectation(description: "Membership Update Event")
    expectation.expectedFulfillmentCount = 2

    let patchedMembership = PubNubMembership(
      user: testMembership.user,
      space: testMembership.space,
      status: "UpdatedStatus",
      custom: MembershipCustom(value: "UpdatedValue"),
      updated: Date.distantFuture,
      eTag: "UpdatedETag"
    )

    let entityEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .updated,
      type: .membership,
      data: [
        "uuid": ["id": patchedMembership.user.id],
        "channel": ["id": patchedMembership.space.id],
        "status": patchedMembership.status,
        "custom": ["value": "UpdatedValue"],
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": patchedMembership.eTag
      ]
    )

    let malformedEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .updated,
      type: .membership,
      data: AnyJSON("")
    )

    listener.didReceiveMembershipEvents = { [unowned self] events in
      for event in events {
        switch event {
        case let .membershipUpdated(patcher):
          XCTAssertEqual(patchedMembership, testMembership.apply(patcher))
        case .membershipRemoved:
          XCTFail("Membership Removed Event should not fire")
        }
      }
      expectation.fulfill()
    }

    listener.didReceiveMembershipEvent = { [unowned self] event in
      switch event {
      case let .membershipUpdated(patcher):
        XCTAssertEqual(patchedMembership, testMembership.apply(patcher))
      case .membershipRemoved:
        XCTFail("Membership Removed Event should not fire")
      }
      expectation.fulfill()
    }

    listener.emit(entity: [malformedEvent, entityEvent])

    wait(for: [expectation], timeout: 1.0)
  }

  func testMembershipListener_Emit_RemoveEvent() {
    let expectation = XCTestExpectation(description: "Membership Update Event")
    expectation.expectedFulfillmentCount = 2

    let entityEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .removed,
      type: .membership,
      data: [
        "uuid": ["id": testMembership.user.id],
        "channel": ["id": testMembership.space.id],
        "status": testMembership.status,
        "custom": ["value": "Tester"],
        "updated": "0001-01-01T00:00:00.000Z",
        "eTag": testMembership.eTag
      ]
    )

    let malformedEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .removed,
      type: .membership,
      data: AnyJSON("")
    )

    listener.didReceiveMembershipEvents = { [unowned self] events in
      for event in events {
        switch event {
        case let .membershipRemoved(membership):
          XCTAssertEqual(membership, testMembership)
        case .membershipUpdated:
          XCTFail("Membership Updated Event should not fire")
        }
      }
      expectation.fulfill()
    }

    listener.didReceiveMembershipEvent = { [unowned self] event in
      switch event {
      case let .membershipRemoved(membership):
        XCTAssertEqual(membership, testMembership)
      case .membershipUpdated:
        XCTFail("Membership Updated Event should not fire")
      }
      expectation.fulfill()
    }

    listener.emit(entity: [malformedEvent, entityEvent])

    wait(for: [expectation], timeout: 1.0)
  }
}
