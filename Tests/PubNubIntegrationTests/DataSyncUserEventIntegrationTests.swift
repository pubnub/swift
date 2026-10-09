//
//  DataSyncUserEventIntegrationTests.swift
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

/// Integration coverage for the `Subscription.onDataSync` listener on built-in User objects
final class DataSyncUserEventIntegrationTests: XCTestCase {
  private let userClassVersion = 1
  private let eventTimeout: TimeInterval = 30.0
  private let testsBundle = Bundle(for: DataSyncUserEventIntegrationTests.self)

  func testListenForUserCreatedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncSubscribeConfiguration(from: testsBundle))
    let userId = randomString()
    let payload = TestDataSyncUserPayload(fullName: "Swift ITest User", email: "swift.itest@example.com")

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let createExpect = expectation(description: "Received user created event")
    createExpect.assertForOverFulfill = false
    createExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .dataSyncUser(userId)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .entityCreated(entityEvent) = event.change, entityEvent.entity.id == userId else {
        return
      }
      guard case let .user(user) = entityEvent.object else {
        XCTFail("A User entity event should narrow to .user, got \(entityEvent.kind)"); return
      }

      XCTAssertEqual(user.id, userId)
      XCTAssertEqual(user.className, "User")
      XCTAssertEqual(user.classLevel, .global)
      XCTAssertEqual(user.classVersion, self.userClassVersion)
      XCTAssertEqual(user.status, "active")
      XCTAssertFalse(user.eTag.isEmpty)
      XCTAssertPayload(user.payload, equals: payload)

      createExpect.fulfill()
    }

    let trigger = { [unowned adminClient] in
      adminClient.dataSync.createUser(
        classVersion: self.userClassVersion,
        id: userId,
        status: "active",
        payload: payload
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the user created event: \(error)")
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
      removeDataSyncUsers(client: adminClient, ids: [userId])
    }

    wait(for: [connectedExpect, createExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForUserUpdatedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncSubscribeConfiguration(from: testsBundle))
    let userId = randomString()

    createDataSyncUsers(client: adminClient, ids: [userId], classVersion: userClassVersion)

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let updateExpect = expectation(description: "Received user updated event")
    updateExpect.assertForOverFulfill = false
    updateExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .dataSyncUser(userId)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .entityUpdated(entityEvent) = event.change, entityEvent.entity.id == userId else {
        return
      }
      guard case let .user(user) = entityEvent.object else {
        XCTFail("A User entity event should narrow to .user, got \(entityEvent.kind)"); return
      }

      XCTAssertEqual(user.id, userId)
      XCTAssertEqual(user.className, "User")
      XCTAssertEqual(user.classLevel, .global)
      XCTAssertEqual(user.classVersion, self.userClassVersion)
      XCTAssertFalse(user.eTag.isEmpty)
      XCTAssertNotNil(user.payload)

      updateExpect.fulfill()
    }

    let trigger = { [unowned adminClient] in
      adminClient.dataSync.updateUser(
        id: userId,
        operations: [.replace(path: "/payload/email", value: "swift.patched@example.com")]
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the user updated event: \(error)")
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
      removeDataSyncUsers(client: adminClient, ids: [userId])
    }

    wait(for: [connectedExpect, updateExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForUserDeletedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncSubscribeConfiguration(from: testsBundle))
    let userId = randomString()

    createDataSyncUsers(client: adminClient, ids: [userId], classVersion: userClassVersion)

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let deleteExpect = expectation(description: "Received user deleted event")
    deleteExpect.assertForOverFulfill = false
    deleteExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .dataSyncUser(userId)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .entityDeleted(entityEvent) = event.change, entityEvent.removed.id == userId else {
        return
      }

      let removed = entityEvent.removed
      XCTAssertEqual(entityEvent.kind, .user)
      XCTAssertEqual(removed.className, "User")
      XCTAssertEqual(removed.classLevel, .global)
      XCTAssertEqual(removed.classVersion, self.userClassVersion)

      deleteExpect.fulfill()
    }

    let trigger = { [unowned adminClient] in
      adminClient.dataSync.removeUser(id: userId) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the user deleted event: \(error)")
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

    // No user cleanup: removing the user is what this test triggers
    defer { pubnub.disconnect() }

    wait(for: [connectedExpect, deleteExpect], timeout: eventTimeout, enforceOrder: true)
  }
}
