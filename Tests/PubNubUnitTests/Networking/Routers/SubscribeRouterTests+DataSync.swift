//
//  SubscribeRouterTests+DataSync.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

// MARK: - DataSync Response

extension SubscribeRouterTests {
  func test_Subscribe_WithDataSyncEntityCreateEvent_ReceivesEntity() throws {
    let expectedEntity = PubNubDataSyncEntity(
      id: "hcn-patient-alice",
      className: "patient",
      classLevel: .subKey,
      classVersion: 1,
      createdAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:11:17.077390Z")),
      updatedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:11:17.077390Z")),
      eTag: "3w5e111hppk83",
      expiresAt: try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2027-07-29T00:00:00Z")),
      status: "active",
      payload: AnyJSON([
        "mrn": "MRN-100001",
        "fullName": "Alice Summers",
        "dateOfBirth": "1985-04-12",
        "heightCm": 167,
        "weightKg": 61.5,
        "isSmoker": false,
        "dischargedAt": NSNull(),
        "allergies": ["penicillin", "latex"],
        "emergencyContact": [
          "name": "Mark Summers",
          "phone": "+1-555-0142"
        ]
      ])
    )

    let event = try decodeEvent(from: "subscription_dataSyncEntityCreate_success")
    let entity = try XCTUnwrap(event.createdDataSyncEntity)

    XCTAssertEqual(entity, expectedEntity)
  }

  func test_Subscribe_WithDataSyncEntityUpdateEvent_ReceivesProjectedPayload() throws {
    let expectedEntity = PubNubDataSyncEntity(
      id: "hcn-patient-alice",
      className: "patient",
      classLevel: .subKey,
      classVersion: 1,
      createdAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:11:17.077390Z")),
      updatedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:20:25.783379Z")),
      eTag: "3w5e111hq1bsx",
      expiresAt: try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2027-07-29T00:00:00Z")),
      status: "active",
      payload: AnyJSON([
        "diagnosis": "Essential hypertension (I10)",
        "dateOfBirth": "1985-03-14",
        "weightKg": 60.4,
        "isSmoker": true
      ])
    )

    let event = try decodeEvent(from: "subscription_dataSyncEntityUpdate_success")
    let entity = try XCTUnwrap(event.updatedDataSyncEntity)

    XCTAssertEqual(entity, expectedEntity)
  }

  func test_Subscribe_WithDataSyncEntityDeleteEvent_ReceivesRemovedEntity() throws {
    let expectedRemoval = PubNubDataSyncRemovedObject(
      id: "hcn-patient-dubois",
      className: "patient",
      classLevel: .subKey,
      classVersion: 1,
      deletedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:07:52.934258Z"))
    )

    let event = try decodeEvent(from: "subscription_dataSyncEntityDelete_success")
    let removed = try XCTUnwrap(event.deletedDataSyncEntity)

    XCTAssertEqual(removed, expectedRemoval)
  }

  func test_Subscribe_WithDataSyncRelationshipCreateEvent_ReceivesRelationship() throws {
    let expectedRelationship = PubNubDataSyncRelationship(
      id: "hcn-rel-attending-carter-alice",
      className: "attending-physician",
      classLevel: .subKey,
      classVersion: 1,
      entityAId: "hcn-practitioner-carter",
      entityBId: "hcn-patient-alice",
      createdAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:11:35.242585Z")),
      updatedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:11:35.242585Z")),
      eTag: "3w5e111hppyni",
      expiresAt: try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2027-07-29T00:00:00Z")),
      status: "active",
      payload: AnyJSON([
        "role": "attending",
        "since": "2024-01-15",
        "isPrimary": true,
        "visitsPerMonth": 3
      ])
    )

    let event = try decodeEvent(from: "subscription_dataSyncRelationshipCreate_success")
    let relationship = try XCTUnwrap(event.createdDataSyncRelationship)

    XCTAssertEqual(relationship, expectedRelationship)
  }

  func test_Subscribe_WithDataSyncRelationshipUpdateEvent_ReceivesRelationship() throws {
    let expectedRelationship = PubNubDataSyncRelationship(
      id: "hcn-rel-attending-carter-alice",
      className: "attending-physician",
      classLevel: .subKey,
      classVersion: 1,
      entityAId: "hcn-practitioner-carter",
      entityBId: "hcn-patient-alice",
      createdAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:11:35.242585Z")),
      updatedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:24:50.283068Z")),
      eTag: "3w5e111hq6zil",
      expiresAt: try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2027-07-29T00:00:00Z")),
      status: "active",
      payload: AnyJSON([
        "role": "consulting",
        "since": "2024-01-15",
        "isPrimary": false,
        "visitsPerMonth": 1
      ])
    )

    let event = try decodeEvent(from: "subscription_dataSyncRelationshipUpdate_success")
    let relationship = try XCTUnwrap(event.updatedDataSyncRelationship)

    XCTAssertEqual(relationship, expectedRelationship)
  }

  func test_Subscribe_WithDataSyncRelationshipDeleteEvent_ReceivesRemovedRelationship() throws {
    let expectedRemoval = PubNubDataSyncRemovedObject(
      id: "hcn-rel-attending-tanaka-dubois",
      className: "attending-physician",
      classLevel: .subKey,
      classVersion: 1,
      deletedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:07:47.243657Z"))
    )

    let event = try decodeEvent(from: "subscription_dataSyncRelationshipDelete_success")
    let removed = try XCTUnwrap(event.deletedDataSyncRelationship)

    XCTAssertEqual(removed, expectedRemoval)
  }

  func test_Subscribe_WithDataSyncClassLevels_ReceivesMatchingLevel() throws {
    let levels: [String: PubNubDataSyncClassLevel] = [
      "SubKey": .subKey,
      "Account": .account,
      "Global": .global
    ]

    for (rawClassLevel, expectedLevel) in levels {
      let event = mockDataSyncPayload(classLevel: rawClassLevel).asPubNubEvent()
      let entity = try XCTUnwrap(event.createdDataSyncEntity, "\(rawClassLevel) should decode")

      XCTAssertEqual(entity.classLevel, expectedLevel, "\(rawClassLevel) should decode as \(expectedLevel)")
      XCTAssertEqual(entity.classLevel.stringValue, rawClassLevel)
    }
  }

  func test_Subscribe_WithUnrecognizedDataSyncClassLevel_ReceivesUnknownLevel() throws {
    let event = mockDataSyncPayload(classLevel: "Space").asPubNubEvent()
    let entity = try XCTUnwrap(event.createdDataSyncEntity)

    XCTAssertEqual(entity.classLevel, .unknown("Space"))
    XCTAssertEqual(entity.classLevel.stringValue, "Space")
  }

  func test_Subscribe_WithDataSyncNullableFieldsAbsent_ReceivesEntity() throws {
    let event = mockDataSyncPayload(data: [
      "id": "hcn-patient-alice",
      "createdAt": "2026-07-28T09:11:17.077390Z",
      "updatedAt": "2026-07-28T09:11:17.077390Z",
      "eTag": "3w5e111hppk83",
      "expiresAt": "2027-07-29T00:00:00Z"
    ]).asPubNubEvent()

    let entity = try XCTUnwrap(event.createdDataSyncEntity)

    XCTAssertNil(entity.status)
    XCTAssertNil(entity.payload)
  }

  func test_Subscribe_WithDataSyncNullableFieldsNull_ReceivesEntity() throws {
    let event = mockDataSyncPayload(data: [
      "id": "hcn-patient-alice",
      "createdAt": "2026-07-28T09:11:17.077390Z",
      "updatedAt": "2026-07-28T09:11:17.077390Z",
      "eTag": "3w5e111hppk83",
      "expiresAt": "2027-07-29T00:00:00Z",
      "status": NSNull(),
      "payload": NSNull()
    ]).asPubNubEvent()

    let entity = try XCTUnwrap(event.createdDataSyncEntity)

    XCTAssertNil(entity.status)
    XCTAssertNil(entity.payload)
  }

  func test_Subscribe_WithDataSyncMissingRequiredFields_ReceivesMessage() throws {
    for missingField in ["eTag", "expiresAt"] {
      var data: [String: Any] = [
        "id": "hcn-patient-alice",
        "createdAt": "2026-07-28T09:11:17.077390Z",
        "updatedAt": "2026-07-28T09:11:17.077390Z",
        "eTag": "3w5e111hppk83",
        "expiresAt": "2027-07-29T00:00:00Z"
      ]

      data.removeValue(forKey: missingField)

      let payload = mockDataSyncPayload(data: data)
      let event = payload.asPubNubEvent()

      XCTAssertNotNil(event.message, "An envelope missing \(missingField) should degrade to a message")
    }
  }

  func test_Subscribe_WithMalformedDataSyncEnvelope_ReceivesMessage() {
    let payload = generateMessage(with: .dataSync, payload: AnyJSON(["not": "a datasync envelope"]))
    XCTAssertNotNil(payload.asPubNubEvent().message)
  }

  func test_Subscribe_WithUnrecognizedDataSyncObjectType_ReceivesMessage() {
    XCTAssertNotNil(mockDataSyncPayload(type: "membership").asPubNubEvent().message)
  }

  func test_DataSyncAction_MapsToUnknownMessageType() {
    XCTAssertEqual(SubscribeMessagePayload.Action.dataSync.asPubNubMessageType, .unknown)
  }
}

// MARK: - DataSync Delivery Through The Subscribe Loop

extension SubscribeRouterTests {
  func test_Subscribe_WithDataSyncEntityCreateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncEntityCreate_success",
      channel: "__admin__hcn-patient-alice"
    )

    XCTAssertEqual(events.legacy.createdEntity?.id, "hcn-patient-alice")
    XCTAssertEqual(events.modern.createdEntity?.id, "hcn-patient-alice")
  }

  func test_Subscribe_WithDataSyncEntityUpdateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncEntityUpdate_success",
      channel: "__admin__hcn-patient-alice"
    )

    XCTAssertEqual(events.legacy.updatedEntity?.id, "hcn-patient-alice")
    XCTAssertEqual(events.modern.updatedEntity?.id, "hcn-patient-alice")
  }

  func test_Subscribe_WithDataSyncEntityDeleteEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncEntityDelete_success",
      channel: "__admin__hcn-patient-dubois"
    )

    XCTAssertEqual(events.legacy.deletedEntity?.id, "hcn-patient-dubois")
    XCTAssertEqual(events.modern.deletedEntity?.id, "hcn-patient-dubois")
  }

  func test_Subscribe_WithDataSyncRelationshipCreateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncRelationshipCreate_success",
      channel: "__admin__hcn-patient-alice"
    )

    XCTAssertEqual(events.legacy.createdRelationship?.id, "hcn-rel-attending-carter-alice")
    XCTAssertEqual(events.modern.createdRelationship?.id, "hcn-rel-attending-carter-alice")
  }

  func test_Subscribe_WithDataSyncRelationshipUpdateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncRelationshipUpdate_success",
      channel: "__admin__hcn-patient-alice"
    )

    XCTAssertEqual(events.legacy.updatedRelationship?.id, "hcn-rel-attending-carter-alice")
    XCTAssertEqual(events.modern.updatedRelationship?.id, "hcn-rel-attending-carter-alice")
  }

  func test_Subscribe_WithDataSyncRelationshipDeleteEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncRelationshipDelete_success",
      channel: "__admin__hcn-patient-dubois"
    )

    XCTAssertEqual(events.legacy.deletedRelationship?.id, "hcn-rel-attending-tanaka-dubois")
    XCTAssertEqual(events.modern.deletedRelationship?.id, "hcn-rel-attending-tanaka-dubois")
  }
}

// MARK: Helpers

private extension SubscribeRouterTests {
  struct EmittedDataSyncEvents {
    let legacy: PubNubDataSyncEvent
    let modern: PubNubDataSyncEvent
  }

  func emittedDataSyncEvents(fromFixture fixture: String, channel: String) throws -> EmittedDataSyncEvents {
    let container = DependencyContainer(configuration: config)

    let mockSession = try XCTUnwrap(MockURLSession.mockSession(for: ["subscription_handshake_success", fixture, "cancelled"]))
    let patchedHTTPSession = mockSession.session

    container.register(
      value: patchedHTTPSession,
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let session = container.subscriptionSession
    let listener = SubscriptionListener()

    session.add(listener)

    let pubnub = PubNub(configuration: config)
    let legacyExpect = expectation(description: "Legacy listener DataSync event")
    let modernExpect = expectation(description: "Modern listener DataSync event")

    var legacyEvent: PubNubDataSyncEvent?
    var modernEvent: PubNubDataSyncEvent?

    listener.didReceiveDataSyncEvent = { event in
      legacyEvent = event
      session.unsubscribeAll()
      legacyExpect.fulfill()
    }

    let subscription = pubnub
      .channel(channel)
      .subscription()

    subscription.onDataSync = { event in
      modernEvent = event
      modernExpect.fulfill()
    }

    session.subscribe(to: [subscription])
    defer { listener.cancel() }
    wait(for: [legacyExpect, modernExpect], timeout: 1.0)

    return EmittedDataSyncEvents(
      legacy: try XCTUnwrap(legacyEvent),
      modern: try XCTUnwrap(modernEvent)
    )
  }
}

private extension PubNubDataSyncEvent {

  var createdEntity: PubNubDataSyncEntity? {
    guard case let .entityCreated(e) = self else { return nil }
    return e
  }

  var updatedEntity: PubNubDataSyncEntity? {
    guard case let .entityUpdated(e) = self else { return nil }
    return e
  }

  var deletedEntity: PubNubDataSyncRemovedObject? {
    guard case let .entityDeleted(e) = self else { return nil }
    return e
  }

  var createdRelationship: PubNubDataSyncRelationship? {
    guard case let .relationshipCreated(r) = self else { return nil }
    return r
  }

  var updatedRelationship: PubNubDataSyncRelationship? {
    guard case let .relationshipUpdated(r) = self else { return nil }
    return r
  }

  var deletedRelationship: PubNubDataSyncRemovedObject? {
    guard case let .relationshipDeleted(r) = self else { return nil }
    return r
  }
}

// MARK: Helpers

private extension PubNubEvent {

  var createdDataSyncEntity: PubNubDataSyncEntity? {
    guard case let .dataSyncChanged(.entityCreated(e)) = self else { return nil }
    return e
  }

  var updatedDataSyncEntity: PubNubDataSyncEntity? {
    guard case let .dataSyncChanged(.entityUpdated(e)) = self else { return nil }
    return e
  }

  var deletedDataSyncEntity: PubNubDataSyncRemovedObject? {
    guard case let .dataSyncChanged(.entityDeleted(e)) = self else { return nil }
    return e
  }

  var createdDataSyncRelationship: PubNubDataSyncRelationship? {
    guard case let .dataSyncChanged(.relationshipCreated(r)) = self else { return nil }
    return r
  }

  var updatedDataSyncRelationship: PubNubDataSyncRelationship? {
    guard case let .dataSyncChanged(.relationshipUpdated(r)) = self else { return nil }
    return r
  }

  var deletedDataSyncRelationship: PubNubDataSyncRemovedObject? {
    guard case let .dataSyncChanged(.relationshipDeleted(r)) = self else { return nil }
    return r
  }
}
