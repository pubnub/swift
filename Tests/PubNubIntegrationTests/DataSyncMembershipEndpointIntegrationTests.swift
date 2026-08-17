//
//  DataSyncMembershipEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

class DataSyncMembershipEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: DataSyncMembershipEndpointIntegrationTests.self)
  let userClassVersion = 1
  let channelClassVersion = 1
  let membershipClassVersion = 1

  func testCreateAndFetchMembership() throws {
    let fetchExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()
    let channelId = randomString()
    let membershipId = randomString()
    let payload = TestMembershipPayload(role: "moderator")

    setUpMembershipTestData(
      client: client,
      userIds: [userId],
      channelIds: [channelId]
    )

    client.dataSync.createMembership(
      channelId: channelId,
      userId: userId,
      classVersion: membershipClassVersion,
      id: membershipId,
      status: "active",
      payload: payload
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdMembership):
        XCTAssertEqual(createdMembership.id, membershipId)
        XCTAssertFalse(createdMembership.eTag.isEmpty)

        client.dataSync.getMembership(membershipId) { fetchResult in
          switch fetchResult {
          case let .success(membership):
            XCTAssertEqual(membership.id, membershipId)
            XCTAssertEqual(membership.channelId, channelId)
            XCTAssertEqual(membership.userId, userId)
            XCTAssertEqual(membership.status, "active")
            XCTAssertEqual(membership.classVersion, self.membershipClassVersion)
            XCTAssertEqual(membership.eTag, createdMembership.eTag)
            XCTAssertPayload(membership.payload, equals: payload)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          fetchExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        fetchExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeMembership(
          membershipId,
          completion: $0
        )
      }
      tearDownMembershipTestData(
        client: client,
        userIds: [userId],
        channelIds: [channelId]
      )
    }

    wait(for: [fetchExpect], timeout: 15.0)
  }

  func testSetMembershipReplacesPayloadWholesale() throws {
    let replaceExpect = expectation(description: "Replace Membership Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()
    let channelId = randomString()
    let membershipId = randomString()

    setUpMembershipTestData(
      client: client,
      userIds: [userId],
      channelIds: [channelId]
    )

    client.dataSync.createMembership(
      channelId: channelId,
      userId: userId,
      classVersion: membershipClassVersion,
      id: membershipId,
      status: "active",
      payload: TestMembershipPayload(role: "moderator", invitedBy: "swift-itest")
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdMembership):
        // The replacement omits `invitedBy`, which must therefore be cleared rather than preserved
        let replacementPayload = TestMembershipPayload(role: "member")

        client.dataSync.setMembership(
          membershipId,
          classVersion: self.membershipClassVersion,
          status: "inactive",
          payload: replacementPayload
        ) { replaceResult in
          switch replaceResult {
          case let .success(replacedMembership):
            XCTAssertEqual(replacedMembership.id, membershipId)
            XCTAssertEqual(replacedMembership.channelId, channelId)
            XCTAssertEqual(replacedMembership.userId, userId)
            XCTAssertEqual(replacedMembership.status, "inactive")
            XCTAssertPayload(replacedMembership.payload, equals: replacementPayload)
            XCTAssertNotEqual(replacedMembership.eTag, createdMembership.eTag)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          replaceExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        replaceExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeMembership(
          membershipId,
          completion: $0
        )
      }
      tearDownMembershipTestData(
        client: client,
        userIds: [userId],
        channelIds: [channelId]
      )
    }

    wait(for: [replaceExpect], timeout: 15.0)
  }

  func testUpdateMembershipAppliesOperationsAndKeepsUntouchedFields() throws {
    let patchExpect = expectation(description: "Patch Membership Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()
    let channelId = randomString()
    let membershipId = randomString()

    setUpMembershipTestData(
      client: client,
      userIds: [userId],
      channelIds: [channelId]
    )

    client.dataSync.createMembership(
      channelId: channelId,
      userId: userId,
      classVersion: membershipClassVersion,
      id: membershipId,
      status: "active",
      payload: TestMembershipPayload(role: "moderator", invitedBy: "swift-itest")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        let expectedPayload = TestMembershipPayload(role: "admin", invitedBy: "swift-itest")

        client.dataSync.updateMembership(
          membershipId,
          operations: [.replace(path: "/payload/role", value: "admin")]
        ) { patchResult in
          switch patchResult {
          case let .success(patchedMembership):
            XCTAssertPayload(patchedMembership.payload, equals: expectedPayload)
            XCTAssertEqual(patchedMembership.status, "active")
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          patchExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        patchExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeMembership(
          membershipId,
          completion: $0
        )
      }
      tearDownMembershipTestData(
        client: client,
        userIds: [userId],
        channelIds: [channelId]
      )
    }

    wait(for: [patchExpect], timeout: 15.0)
  }

  func testSetMembershipWithStaleEtagFails() throws {
    let replaceExpect = expectation(description: "Replace Membership Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()
    let channelId = randomString()
    let membershipId = randomString()

    setUpMembershipTestData(
      client: client,
      userIds: [userId],
      channelIds: [channelId]
    )

    client.dataSync.createMembership(
      channelId: channelId,
      userId: userId,
      classVersion: membershipClassVersion,
      id: membershipId,
      status: "active",
      payload: TestMembershipPayload(role: "moderator")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.setMembership(
          membershipId,
          classVersion: self.membershipClassVersion,
          status: "inactive",
          payload: TestMembershipPayload(role: "member"),
          ifMatchesEtag: "stale-etag"
        ) { replaceResult in
          switch replaceResult {
          case .success:
            XCTFail("Test should fail")
          case let .failure(error):
            XCTAssertNotNil(error.pubNubError)
            XCTAssertEqual(error.pubNubError?.reason, .preconditionFailed)
          }
          replaceExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        replaceExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeMembership(
          membershipId,
          completion: $0
        )
      }
      tearDownMembershipTestData(
        client: client,
        userIds: [userId],
        channelIds: [channelId]
      )
    }

    wait(for: [replaceExpect], timeout: 15.0)
  }

  func testGetMembershipsForUserReturnsEveryChannelJoined() throws {
    let listExpect = expectation(description: "List Memberships Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()
    let channelIds = [randomString(), randomString()]
    let membershipIds = [randomString(), randomString()]

    setUpMembershipTestData(
      client: client,
      userIds: [userId],
      channelIds: channelIds
    )
    createMemberships(
      client: client,
      memberships: zip(membershipIds, channelIds).map { TestMembership(id: $0, channelId: $1, userId: userId) }
    )

    client.dataSync.getMemberships(userId: userId) { result in
      switch result {
      case let .success((memberships, _)):
        XCTAssertEqual(Set(memberships.map { $0.id }), Set(membershipIds))
        XCTAssertEqual(Set(memberships.map { $0.channelId }), Set(channelIds))
        XCTAssertTrue(memberships.allSatisfy { $0.userId == userId })
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      for membershipId in membershipIds {
        waitForCompletion {
          client.dataSync.removeMembership(
            membershipId,
            completion: $0
          )
        }
      }
      tearDownMembershipTestData(
        client: client,
        userIds: [userId],
        channelIds: channelIds
      )
    }

    wait(for: [listExpect], timeout: 15.0)
  }

  func testGetMembershipsForChannelReturnsEveryUserJoined() throws {
    let listExpect = expectation(description: "List Memberships Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userIds = [randomString(), randomString()]
    let channelId = randomString()
    let membershipIds = [randomString(), randomString()]

    setUpMembershipTestData(
      client: client,
      userIds: userIds,
      channelIds: [channelId]
    )
    createMemberships(
      client: client,
      memberships: zip(membershipIds, userIds).map { TestMembership(id: $0, channelId: channelId, userId: $1) }
    )

    client.dataSync.getMemberships(channelId: channelId) { result in
      switch result {
      case let .success((memberships, _)):
        XCTAssertEqual(Set(memberships.map { $0.id }), Set(membershipIds))
        XCTAssertEqual(Set(memberships.map { $0.userId }), Set(userIds))
        XCTAssertTrue(memberships.allSatisfy { $0.channelId == channelId })
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      for membershipId in membershipIds {
        waitForCompletion {
          client.dataSync.removeMembership(
            membershipId,
            completion: $0
          )
        }
      }
      tearDownMembershipTestData(
        client: client,
        userIds: userIds,
        channelIds: [channelId]
      )
    }

    wait(for: [listExpect], timeout: 15.0)
  }

  func testRemoveMembershipThenFetchFails() throws {
    let removeExpect = expectation(description: "Remove Membership Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()
    let channelId = randomString()
    let membershipId = randomString()

    setUpMembershipTestData(
      client: client,
      userIds: [userId],
      channelIds: [channelId]
    )

    client.dataSync.createMembership(
      channelId: channelId,
      userId: userId,
      classVersion: membershipClassVersion,
      id: membershipId,
      status: "active",
      payload: TestMembershipPayload(role: "moderator")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.removeMembership(membershipId) { removeResult in
          switch removeResult {
          case .success:
            client.dataSync.getMembership(membershipId) { fetchResult in
              switch fetchResult {
              case .success:
                XCTFail("Test should fail")
              case let .failure(error):
                XCTAssertNotNil(error.pubNubError)
                XCTAssertEqual(error.pubNubError?.reason, .resourceNotFound)
              }
              removeExpect.fulfill()
            }
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
            removeExpect.fulfill()
          }
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        removeExpect.fulfill()
      }
    }

    // Only the user and the channel need cleaning up: removing the membership is the subject of this test
    defer {
      tearDownMembershipTestData(
        client: client,
        userIds: [userId],
        channelIds: [channelId]
      )
    }

    wait(for: [removeExpect], timeout: 15.0)
  }
}

// MARK: - Test Data

private struct TestMembership {
  let id: String
  let channelId: String
  let userId: String
}

private struct TestMembershipPayload: JSONCodable, Equatable {
  let role: String?
  let invitedBy: String?

  init(role: String? = nil, invitedBy: String? = nil) {
    self.role = role
    self.invitedBy = invitedBy
  }
}

private struct TestUserSetupPayload: JSONCodable, Equatable {
  let fullName: String
}

private struct TestChannelSetupPayload: JSONCodable, Equatable {
  let name: String
  let description: String
}

private extension DataSyncMembershipEndpointIntegrationTests {
  func setUpMembershipTestData(client: PubNub, userIds: [String], channelIds: [String]) {
    let setupExpect = expectation(description: "Setup Membership Test Data Expectation")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true

    func createNextChannel(_ remainingIds: [String]) {
      guard let channelId = remainingIds.first else {
        setupExpect.fulfill(); return
      }

      client.dataSync.createChannel(
        classVersion: channelClassVersion,
        id: channelId,
        status: "active",
        payload: TestChannelSetupPayload(
          name: channelId,
          description: "Created by the Swift integration tests"
        )
      ) { result in
        switch result {
        case .success:
          createNextChannel(Array(remainingIds.dropFirst()))
        case let .failure(error):
          XCTFail("Failed to setup test channel \(channelId): \(error)")
        }
      }
    }

    func createNextUser(_ remainingIds: [String]) {
      guard let userId = remainingIds.first else {
        createNextChannel(channelIds); return
      }

      client.dataSync.createUser(
        classVersion: userClassVersion,
        id: userId,
        status: "active",
        payload: TestUserSetupPayload(fullName: userId)
      ) { result in
        switch result {
        case .success:
          createNextUser(Array(remainingIds.dropFirst()))
        case let .failure(error):
          XCTFail("Failed to setup test user \(userId): \(error)")
        }
      }
    }

    createNextUser(userIds)

    wait(for: [setupExpect], timeout: 20.0)
  }

  func tearDownMembershipTestData(client: PubNub, userIds: [String], channelIds: [String]) {
    for userId in userIds {
      waitForCompletion {
        client.dataSync.removeUser(
          userId,
          completion: $0
        )
      }
    }
    for channelId in channelIds {
      waitForCompletion {
        client.dataSync.removeChannel(
          channelId,
          completion: $0
        )
      }
    }
  }

  func createMemberships(client: PubNub, memberships: [TestMembership]) {
    let setupExpect = expectation(description: "Create Test Memberships Expectation")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true

    func createNext(_ remaining: [TestMembership]) {
      guard let membership = remaining.first else {
        setupExpect.fulfill(); return
      }

      client.dataSync.createMembership(
        channelId: membership.channelId,
        userId: membership.userId,
        classVersion: membershipClassVersion,
        id: membership.id,
        status: "active",
        payload: TestMembershipPayload(role: "member")
      ) { result in
        switch result {
        case .success:
          createNext(Array(remaining.dropFirst()))
        case let .failure(error):
          XCTFail("Failed to setup test membership \(membership.id): \(error)")
        }
      }
    }

    createNext(memberships)

    wait(for: [setupExpect], timeout: 20.0)
  }
}
