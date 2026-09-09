//
//  DataSyncMembershipEventIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import PubNubSDK
import XCTest

/// Integration coverage for the `Subscription.onDataSync` listener on built-in Membership objects
final class DataSyncMembershipEventIntegrationTests: XCTestCase {
  private let userClassVersion = 1
  private let channelClassVersion = 1
  private let membershipClassVersion = 1
  private let eventTimeout: TimeInterval = 30.0
  private let testsBundle = Bundle(for: DataSyncMembershipEventIntegrationTests.self)

  func testListenForMembershipCreatedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncSubscribeConfiguration(from: testsBundle))
    let userId = randomString()
    let channelId = randomString()
    let membershipId = randomString()

    createDataSyncUsers(client: adminClient, ids: [userId], classVersion: userClassVersion)
    createDataSyncChannels(client: adminClient, ids: [channelId], classVersion: channelClassVersion)

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    // The service fans a membership event out to both the channel's and the user's channel
    let createExpect = expectation(description: "Received membership created event")
    createExpect.assertForOverFulfill = true
    createExpect.expectedFulfillmentCount = 2

    let subscription = pubnub.subscription(
      targets: [pubnub.dataSyncChannel(channelId), pubnub.dataSyncUser(userId)]
    )

    subscription.onDataSync = { event in
      guard case let .relationshipCreated(relationship) = event, relationship.id == membershipId else {
        return
      }

      XCTAssertEqual(relationship.className, "Membership")
      XCTAssertEqual(relationship.classVersion, self.membershipClassVersion)
      XCTAssertEqual(relationship.entityAId, channelId)
      XCTAssertEqual(relationship.entityBId, userId)
      XCTAssertEqual(relationship.status, "active")
      XCTAssertFalse(relationship.eTag.isEmpty)
      XCTAssertNotNil(relationship.payload)
      createExpect.fulfill()
    }

    let trigger = { [unowned adminClient] in
      adminClient.dataSync.createMembership(
        channelId: channelId,
        userId: userId,
        classVersion: self.membershipClassVersion,
        id: membershipId,
        status: "active",
        payload: TestDataSyncMembershipPayload(role: "moderator", invitedBy: "swift-itest")
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the membership created event: \(error)")
        }
      }
    }

    pubnub.onConnectionStateChange = { newStatus in
      if newStatus == .connected {
        connectedExpect.fulfill()
        trigger()
      }
    }

    subscription.subscribe()

    defer {
      pubnub.disconnect()
      removeDataSyncMemberships(client: adminClient, ids: [membershipId])
      removeDataSyncUsers(client: adminClient, ids: [userId])
      removeDataSyncChannels(client: adminClient, ids: [channelId])
    }

    wait(for: [connectedExpect, createExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForMembershipUpdatedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncSubscribeConfiguration(from: testsBundle))
    let userId = randomString()
    let channelId = randomString()
    let membershipId = randomString()

    createDataSyncUsers(client: adminClient, ids: [userId], classVersion: userClassVersion)
    createDataSyncChannels(client: adminClient, ids: [channelId], classVersion: channelClassVersion)
    createMembership(
      client: adminClient,
      id: membershipId,
      channelId: channelId,
      userId: userId
    )

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    // The service fans a membership event out to both the channel's and the user's channel
    let updateExpect = expectation(description: "Received membership updated event")
    updateExpect.assertForOverFulfill = true
    updateExpect.expectedFulfillmentCount = 2

    let subscription = pubnub.subscription(
      targets: [pubnub.dataSyncChannel(channelId), pubnub.dataSyncUser(userId)]
    )

    subscription.onDataSync = { event in
      guard case let .relationshipUpdated(relationship) = event, relationship.id == membershipId else {
        return
      }

      XCTAssertEqual(relationship.className, "Membership")
      XCTAssertEqual(relationship.classVersion, self.membershipClassVersion)
      XCTAssertEqual(relationship.entityAId, channelId)
      XCTAssertEqual(relationship.entityBId, userId)
      XCTAssertFalse(relationship.eTag.isEmpty)
      XCTAssertNotNil(relationship.payload)
      updateExpect.fulfill()
    }

    let trigger = { [unowned adminClient] in
      adminClient.dataSync.updateMembership(
        id: membershipId,
        operations: [.replace(path: "/payload/role", value: "admin")]
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the membership updated event: \(error)")
        }
      }
    }

    pubnub.onConnectionStateChange = { newStatus in
      if newStatus == .connected {
        connectedExpect.fulfill()
        trigger()
      }
    }

    subscription.subscribe()

    defer {
      pubnub.disconnect()
      removeDataSyncMemberships(client: adminClient, ids: [membershipId])
      removeDataSyncUsers(client: adminClient, ids: [userId])
      removeDataSyncChannels(client: adminClient, ids: [channelId])
    }

    wait(for: [connectedExpect, updateExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForMembershipDeletedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncSubscribeConfiguration(from: testsBundle))
    let userId = randomString()
    let channelId = randomString()
    let membershipId = randomString()

    createDataSyncUsers(client: adminClient, ids: [userId], classVersion: userClassVersion)
    createDataSyncChannels(client: adminClient, ids: [channelId], classVersion: channelClassVersion)
    createMembership(
      client: adminClient,
      id: membershipId,
      channelId: channelId,
      userId: userId
    )

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    // The service fans a membership event out to both the channel's and the user's channel
    let deleteExpect = expectation(description: "Received membership deleted event")
    deleteExpect.assertForOverFulfill = true
    deleteExpect.expectedFulfillmentCount = 2

    let subscription = pubnub.subscription(
      targets: [pubnub.dataSyncChannel(channelId), pubnub.dataSyncUser(userId)]
    )

    subscription.onDataSync = { event in
      guard case let .relationshipDeleted(removed) = event, removed.id == membershipId else {
        return
      }

      XCTAssertEqual(removed.className, "Membership")
      XCTAssertEqual(removed.classVersion, self.membershipClassVersion)
      deleteExpect.fulfill()
    }

    let trigger = { [unowned adminClient] in
      adminClient.dataSync.removeMembership(id: membershipId) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the membership deleted event: \(error)")
        }
      }
    }

    pubnub.onConnectionStateChange = { newStatus in
      if newStatus == .connected {
        connectedExpect.fulfill()
        trigger()
      }
    }

    subscription.subscribe()

    // The membership is removed by the trigger itself, leaving only the user and channel to clean up
    defer {
      pubnub.disconnect()
      removeDataSyncUsers(client: adminClient, ids: [userId])
      removeDataSyncChannels(client: adminClient, ids: [channelId])
    }

    wait(for: [connectedExpect, deleteExpect], timeout: eventTimeout, enforceOrder: true)
  }
}

// MARK: - Setup

private extension DataSyncMembershipEventIntegrationTests {
  func createMembership(client: PubNub, id: String, channelId: String, userId: String) {
    let setupExpect = expectation(description: "Create Test Membership Expectation")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true

    client.dataSync.createMembership(
      channelId: channelId,
      userId: userId,
      classVersion: membershipClassVersion,
      id: id,
      status: "active",
      payload: TestDataSyncMembershipPayload(role: "moderator", invitedBy: "swift-itest")
    ) { result in
      if case let .failure(error) = result {
        XCTFail("Failed to setup test membership \(id): \(error)")
      }
      setupExpect.fulfill()
    }

    wait(for: [setupExpect], timeout: 20.0)
  }
}
