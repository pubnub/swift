//
//  DataSyncEntityEventIntegrationTests.swift
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

/// Integration coverage for the `Subscription.onDataSync` listener
final class DataSyncEntityEventIntegrationTests: XCTestCase {
  private let eventChannel = "__admin__swift-patient-alice"
  private let patientId = "swift-patient-alice"
  private let practitionerId = "swift-practitioner-carter"
  private let relationshipId = "swift-rel-attending-carter-alice"
  private let patientClass = HealthcareClass.patient
  private let attendingPhysicianClass = HealthcareClass.attendingPhysician
  private let eventTimeout: TimeInterval = 30.0
  private let testsBundle = Bundle(for: DataSyncEntityEventIntegrationTests.self)

  override func setUpWithError() throws {
    try skipUnlessDataSyncTokensCanBeGranted(from: testsBundle)
  }

  // MARK: - Entity events

  func testListenForEntityCreatedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncHealthcareSubsribeConfiguration(from: testsBundle))

    removeEntities(client: adminClient, ids: [patientId])

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let createExpect = expectation(description: "Received entity created event")
    createExpect.assertForOverFulfill = false
    createExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .channel(eventChannel)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .entityCreated(entity) = event, entity.id == self.patientId else {
        return
      }

      XCTAssertEqual(entity.id, "swift-patient-alice")
      XCTAssertEqual(entity.className, "patient")
      XCTAssertFalse(entity.eTag.isEmpty)
      XCTAssertNotNil(entity.payload)
      createExpect.fulfill()
    }

    let trigger = { [unowned adminClient, unowned self] in
      adminClient.dataSync.createEntity(
        entityClass: self.patientClass.name,
        entityClassVersion: self.patientClass.version,
        id: self.patientId,
        status: "active",
        payload: TestPatientPayload.standard(mrn: self.patientId)
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the entity created event: \(error)")
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
      removeEntities(client: adminClient, ids: [patientId])
    }

    wait(for: [connectedExpect, createExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForEntityUpdateEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncHealthcareSubsribeConfiguration(from: testsBundle))

    removeEntities(client: adminClient, ids: [patientId])
    createEntities(client: adminClient, [.patient(id: patientId)])

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let updateExpect = expectation(description: "Received entity update event")
    updateExpect.assertForOverFulfill = false
    updateExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .channel(eventChannel)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .entityUpdated(entity) = event, entity.id == self.patientId else {
        return
      }

      XCTAssertEqual(entity.id, "swift-patient-alice")
      XCTAssertEqual(entity.className, "patient")
      XCTAssertFalse(entity.eTag.isEmpty)
      XCTAssertNotNil(entity.payload)
      updateExpect.fulfill()
    }

    let trigger = { [unowned adminClient, unowned self] in
      adminClient.dataSync.updateEntity(
        self.patientId,
        operations: [.replace(path: "/payload/diagnosis", value: "Essential hypertension (I10)")]
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the entity update event: \(error)")
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
      removeEntities(client: adminClient, ids: [patientId])
    }
    wait(for: [connectedExpect, updateExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForEntityDeletedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncHealthcareSubsribeConfiguration(from: testsBundle))

    removeEntities(client: adminClient, ids: [patientId])
    createEntities(client: adminClient, [.patient(id: patientId)])

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let deleteExpect = expectation(description: "Received entity deleted event")
    deleteExpect.assertForOverFulfill = false
    deleteExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .channel(eventChannel)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .entityDeleted(removed) = event, removed.id == self.patientId else {
        return
      }

      XCTAssertEqual(removed.id, "swift-patient-alice")
      XCTAssertEqual(removed.className, "patient")
      deleteExpect.fulfill()
    }

    let trigger = { [unowned adminClient, unowned self] in
      adminClient.dataSync.removeEntity(self.patientId) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the entity deleted event: \(error)")
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

    // No entity cleanup: removing the entity is what this test triggers
    defer { pubnub.disconnect() }
    wait(for: [connectedExpect, deleteExpect], timeout: eventTimeout, enforceOrder: true)
  }

  // MARK: - Relationship events

  func testListenForRelationshipCreatedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncHealthcareSubsribeConfiguration(from: testsBundle))

    removeRelationships(client: adminClient, ids: [relationshipId])
    removeEntities(client: adminClient, ids: [practitionerId, patientId])
    createEntities(client: adminClient, [.practitioner(id: practitionerId), .patient(id: patientId)])

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let createExpect = expectation(description: "Received relationship created event")
    createExpect.assertForOverFulfill = false
    createExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .channel(eventChannel)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .relationshipCreated(relationship) = event, relationship.id == self.relationshipId else {
        return
      }

      XCTAssertEqual(relationship.id, "swift-rel-attending-carter-alice")
      XCTAssertEqual(relationship.className, "attending-physician")
      XCTAssertEqual(relationship.entityAId, "swift-practitioner-carter")
      XCTAssertEqual(relationship.entityBId, "swift-patient-alice")
      XCTAssertFalse(relationship.eTag.isEmpty)
      XCTAssertNotNil(relationship.payload)
      createExpect.fulfill()
    }

    let trigger = { [unowned adminClient, unowned self] in
      adminClient.dataSync.createRelationship(
        relationshipClass: self.attendingPhysicianClass.name,
        entityAId: self.practitionerId,
        entityBId: self.patientId,
        relationshipClassVersion: self.attendingPhysicianClass.version,
        id: self.relationshipId,
        status: "active",
        payload: TestAttendingPhysicianPayload(role: "attending", since: "2024-01-15")
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the relationship created event: \(error)")
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
      removeRelationships(client: adminClient, ids: [relationshipId])
      removeEntities(client: adminClient, ids: [practitionerId, patientId])
    }
    wait(for: [connectedExpect, createExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForRelationshipUpdatedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncHealthcareSubsribeConfiguration(from: testsBundle))

    removeRelationships(
      client: adminClient,
      ids: [relationshipId]
    )
    removeEntities(
      client: adminClient,
      ids: [practitionerId, patientId]
    )
    createEntities(
      client: adminClient,
      [.practitioner(id: practitionerId), .patient(id: patientId)]
    )
    createRelationships(
      client: adminClient,
      [.attendingPhysician(id: relationshipId, practitionerId: practitionerId, patientId: patientId)]
    )

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let updateExpect = expectation(description: "Received relationship updated event")
    updateExpect.assertForOverFulfill = false
    updateExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .channel(eventChannel)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .relationshipUpdated(relationship) = event, relationship.id == self.relationshipId else {
        return
      }

      XCTAssertEqual(relationship.id, "swift-rel-attending-carter-alice")
      XCTAssertEqual(relationship.className, "attending-physician")
      XCTAssertEqual(relationship.entityAId, "swift-practitioner-carter")
      XCTAssertEqual(relationship.entityBId, "swift-patient-alice")
      XCTAssertFalse(relationship.eTag.isEmpty)
      XCTAssertNotNil(relationship.payload)
      updateExpect.fulfill()
    }

    let trigger = { [unowned adminClient, unowned self] in
      adminClient.dataSync.updateRelationship(
        self.relationshipId,
        operations: [.replace(path: "/payload/role", value: "consulting")]
      ) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the relationship updated event: \(error)")
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
      removeRelationships(client: adminClient, ids: [relationshipId])
      removeEntities(client: adminClient, ids: [practitionerId, patientId])
    }
    wait(for: [connectedExpect, updateExpect], timeout: eventTimeout, enforceOrder: true)
  }

  func testListenForRelationshipDeletedEvent() throws {
    let adminClient = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let pubnub = PubNub(configuration: try dataSyncHealthcareSubsribeConfiguration(from: testsBundle))

    removeRelationships(
      client: adminClient,
      ids: [relationshipId]
    )
    removeEntities(
      client: adminClient,
      ids: [practitionerId, patientId]
    )
    createEntities(
      client: adminClient,
      [.practitioner(id: practitionerId), .patient(id: patientId)]
    )
    createRelationships(
      client: adminClient,
      [.attendingPhysician(id: relationshipId, practitionerId: practitionerId, patientId: patientId)]
    )

    let connectedExpect = expectation(description: "Subscription connected")
    connectedExpect.assertForOverFulfill = false
    connectedExpect.expectedFulfillmentCount = 1

    let deleteExpect = expectation(description: "Received relationship deleted event")
    deleteExpect.assertForOverFulfill = false
    deleteExpect.expectedFulfillmentCount = 1

    let subscription = pubnub
      .channel(eventChannel)
      .subscription()

    subscription.onDataSync = { event in
      guard case let .relationshipDeleted(removed) = event, removed.id == self.relationshipId else {
        return
      }

      XCTAssertEqual(removed.id, "swift-rel-attending-carter-alice")
      XCTAssertEqual(removed.className, "attending-physician")
      deleteExpect.fulfill()
    }

    let trigger = { [unowned adminClient, unowned self] in
      adminClient.dataSync.removeRelationship(self.relationshipId) { result in
        if case let .failure(error) = result {
          XCTFail("Failed to trigger the relationship deleted event: \(error)")
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

    // The relationship is removed by the trigger itself, leaving only the entities it linked to clean up
    defer {
      pubnub.disconnect()
      removeEntities(client: adminClient, ids: [practitionerId, patientId])
    }
    wait(for: [connectedExpect, deleteExpect], timeout: eventTimeout, enforceOrder: true)
  }
}
