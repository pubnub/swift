//
//  DataSyncChannelEventIntegrationTests.swift
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

/// Integration coverage for the `Subscription.onDataSync` listener on built-in Channel objects
final class DataSyncChannelEventIntegrationTests: XCTestCase {
  private let channelClassVersion = 1
  private let eventTimeout: TimeInterval = 30.0
  private let testsBundle = Bundle(for: DataSyncChannelEventIntegrationTests.self)

  func testListenForChannelCreatedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncSubscribeConfiguration(from: testsBundle))
    let channelId = randomString()

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let createExpect = expectation(description: "Received channel created event")
    createExpect.assertForOverFulfill = false
    createExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .dataSyncChannel(channelId)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .entityCreated(entity) = event, entity.id == channelId else {
        return
      }

      XCTAssertEqual(entity.className, "Channel")
      XCTAssertEqual(entity.classLevel, .global)
      XCTAssertEqual(entity.classVersion, self.channelClassVersion)
      XCTAssertEqual(entity.status, "active")
      XCTAssertFalse(entity.eTag.isEmpty)
      XCTAssertNotNil(entity.payload)
      createExpect.fulfill()
    }

    let trigger = { [unowned adminClient] in
      adminClient.dataSync.createChannel(
        classVersion: self.channelClassVersion,
        id: channelId,
        status: "active",
        payload: TestDataSyncChannelPayload(
          name: channelId,
          description: "Created by the Swift integration tests"
        )
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the channel created event: \(error)")
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
      removeDataSyncChannels(client: adminClient, ids: [channelId])
    }

    wait(for: [connectedExpect, createExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForChannelUpdatedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncSubscribeConfiguration(from: testsBundle))
    let channelId = randomString()

    createDataSyncChannels(client: adminClient, ids: [channelId], classVersion: channelClassVersion)

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let updateExpect = expectation(description: "Received channel updated event")
    updateExpect.assertForOverFulfill = false
    updateExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .dataSyncChannel(channelId)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .entityUpdated(entity) = event, entity.id == channelId else {
        return
      }

      XCTAssertEqual(entity.className, "Channel")
      XCTAssertEqual(entity.classLevel, .global)
      XCTAssertEqual(entity.classVersion, self.channelClassVersion)
      XCTAssertFalse(entity.eTag.isEmpty)
      XCTAssertNotNil(entity.payload)
      updateExpect.fulfill()
    }

    let trigger = { [unowned adminClient] in
      adminClient.dataSync.updateChannel(
        id: channelId,
        operations: [.replace(path: "/payload/description", value: "Patched by the Swift integration tests")]
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the channel updated event: \(error)")
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
      removeDataSyncChannels(client: adminClient, ids: [channelId])
    }

    wait(for: [connectedExpect, updateExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForChannelDeletedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncSubscribeConfiguration(from: testsBundle))
    let channelId = randomString()

    createDataSyncChannels(client: adminClient, ids: [channelId], classVersion: channelClassVersion)

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let deleteExpect = expectation(description: "Received channel deleted event")
    deleteExpect.assertForOverFulfill = false
    deleteExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .dataSyncChannel(channelId)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .entityDeleted(removed) = event, removed.id == channelId else {
        return
      }

      XCTAssertEqual(removed.className, "Channel")
      XCTAssertEqual(removed.classLevel, .global)
      XCTAssertEqual(removed.classVersion, self.channelClassVersion)
      deleteExpect.fulfill()
    }

    let trigger = { [unowned adminClient] in
      adminClient.dataSync.removeChannel(id: channelId) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the channel deleted event: \(error)")
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

    // No channel cleanup: removing the channel is what this test triggers
    defer { pubnub.disconnect() }

    wait(for: [connectedExpect, deleteExpect], timeout: eventTimeout, enforceOrder: true)
  }
}
