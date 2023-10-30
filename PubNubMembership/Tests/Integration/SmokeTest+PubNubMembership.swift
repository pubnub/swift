//
//  SmokeTest+PubNubMembership.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
import PubNubMembership
import PubNubSpace
import PubNubUser

import XCTest

class PubNubMembershipInterfaceITests: XCTestCase {
  let testMembership = PubNubMembership(
    user: .init(id: "TestUserMembershipId"),
    space: .init(id: "TestSpaceMembershipId"),
    status: "TestStatus",
    custom: MembershipCustom(value: "TestValue")
  )
  let testUpdatedMembership = PubNubMembership(
    user: .init(id: "TestUserMembershipId"),
    space: .init(id: "TestSpaceMembershipId"),
    status: "UpdatedStatus",
    custom: MembershipCustom(value: "UpdatedValue")
  )
  var createdMembership: PubNubMembership?
  var updatedMembership: PubNubMembership?

  let config = PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "itest-swift-membershipId"
  )

  func testMembership_Smoke() throws {
    let expectation = XCTestExpectation(description: "Smoke Test Membership APIs")

    let createdEventExpectation = XCTestExpectation(description: "Created Event Listener")
    let updatedEventExpectation = XCTestExpectation(description: "Updated Event Listener")
    let removedEventExpectation = XCTestExpectation(description: "Removed Event Listener")

    let pubnub = PubNub(configuration: config)

    pubnub.subscribe(to: [testMembership.space.id])

    // Smoke Test Events
    let listener = eventListener_Memberships(
      createdEventExpectation,
      updatedEventExpectation,
      removedEventExpectation
    )

    pubnub.add(listener)

    // Validate Outputs
    pubnub.addMemberships(
      spaces: [testMembership.partialSpace],
      to: testMembership.user.id
    ) { [unowned self] result in
      do {
        switch result {
        case .success:
          self.fetchMemberships_Smoke(pubnub, expectation)

        case let .failure(error):
          XCTFail("Failed due to error \(error)")
          expectation.fulfill()
        }
      }
    }

    wait(
      for: [
        createdEventExpectation,
        updatedEventExpectation,
        expectation,
        removedEventExpectation
      ],
      timeout: 10.0
    )
  }

  func eventListener_Memberships(
    _ createdEventExpectation: XCTestExpectation,
    _ updatedEventExpectation: XCTestExpectation,
    _ removedEventExpectation: XCTestExpectation
  ) -> PubNubMembershipListener {
    let listener = PubNubMembershipListener()

    listener.didReceiveMembershipEvent = { [unowned self] event in
      switch event {
      case let .membershipUpdated(patcher):
        if updatedMembership == nil {
          // Membership was Added
          createdMembership = testMembership
          createdMembership?.eTag = patcher.eTag
          createdMembership?.updated = patcher.updated
          XCTAssertEqual(createdMembership, testMembership.apply(patcher))
          // Signal next event to verify update
          updatedMembership = testUpdatedMembership
          createdEventExpectation.fulfill()
        } else {
          // Membership was Updated
          updatedMembership?.eTag = patcher.eTag
          updatedMembership?.updated = patcher.updated
          XCTAssertEqual(updatedMembership, testUpdatedMembership.apply(patcher))
          updatedEventExpectation.fulfill()
        }
      case let .membershipRemoved(membership):
        XCTAssertEqual(membership.user.id, testMembership.user.id)
        XCTAssertEqual(membership.space.id, testMembership.space.id)

        removedEventExpectation.fulfill()
      }
    }

    return listener
  }

  func fetchMemberships_Smoke(
    _ pubnub: PubNub,
    _ expectation: XCTestExpectation
  ) {
    pubnub.fetchMemberships(
      userId: testMembership.user.id
    ) { [unowned self] result in
      switch result {
      case let .success((memberships, next)):
        var addedMembership = testMembership
        addedMembership.eTag = memberships.first?.eTag
        addedMembership.updated = memberships.first?.updated

        XCTAssertTrue(memberships.contains(addedMembership))
        XCTAssertNotNil(next)

        updateMembership_Smoke(pubnub, expectation)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }

  func updateMembership_Smoke(
    _ pubnub: PubNub,
    _ expectation: XCTestExpectation
  ) {
    pubnub.updateMemberships(
      spaces: [testUpdatedMembership.partialSpace],
      on: testUpdatedMembership.user.id
    ) { [unowned self] result in
      switch result {
      case .success:
        updatedMembership = testUpdatedMembership

        self.removeMembership_Smoke(pubnub, expectation)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }

  func removeMembership_Smoke(
    _ pubnub: PubNub,
    _ expectation: XCTestExpectation
  ) {
    pubnub.removeMemberships(
      spaceIds: [testMembership.space.id],
      from: testMembership.user.id
    ) { [unowned self] result in
      switch result {
      case .success:
        pubnub.fetchMemberships(
          userId: testMembership.user.id
        ) { result in
          switch result {
          case let .success((memberships, next)):
            XCTAssertTrue(memberships.isEmpty)
            XCTAssertNil(next?.start)
            XCTAssertNil(next?.end)
          case let .failure(error):
            XCTFail("Failed due to error \(error)")
          }
          expectation.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }
}
