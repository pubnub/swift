//
//  SmokeTest+PubNubMembership.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
