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
    let expectedPayload = PatientPayload(
      mrn: "MRN-100001",
      fullName: "Alice Summers",
      dateOfBirth: "1985-04-12",
      heightCm: 167,
      weightKg: 61.5,
      isSmoker: false,
      dischargedAt: JSONCodableScalarType(stringValue: nil),
      allergies: ["penicillin", "latex"],
      emergencyContact: EmergencyContact(name: "Mark Summers", phone: "+1-555-0142")
    )
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
      payload: expectedPayload
    )

    let event = try decodeEvent(from: "subscription_dataSyncEntityCreate_success")
    let entity = try XCTUnwrap(event.createdDataSyncEntity)

    XCTAssertEqual(entity.id, expectedEntity.id)
    XCTAssertEqual(entity.className, expectedEntity.className)
    XCTAssertEqual(entity.classLevel, expectedEntity.classLevel)
    XCTAssertEqual(entity.classVersion, expectedEntity.classVersion)
    XCTAssertEqual(entity.createdAt, expectedEntity.createdAt)
    XCTAssertEqual(entity.updatedAt, expectedEntity.updatedAt)
    XCTAssertEqual(entity.eTag, expectedEntity.eTag)
    XCTAssertEqual(entity.expiresAt, expectedEntity.expiresAt)
    XCTAssertEqual(entity.status, expectedEntity.status)

    XCTAssertPayload(
      entity.payload,
      equals: PatientPayload(
        mrn: "MRN-100001",
        fullName: "Alice Summers",
        dateOfBirth: "1985-04-12",
        heightCm: 167,
        weightKg: 61.5,
        isSmoker: false,
        allergies: ["penicillin", "latex"],
        emergencyContact: EmergencyContact(name: "Mark Summers", phone: "+1-555-0142")
      )
    )
  }

  func test_Subscribe_WithDataSyncEntityUpdateEvent_ReceivesProjectedPayload() throws {
    let expectedPayload = PatientPayload(
      diagnosis: "Essential hypertension (I10)",
      dateOfBirth: "1985-03-14",
      weightKg: 60.4,
      isSmoker: true
    )
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
      payload: expectedPayload
    )

    let event = try decodeEvent(from: "subscription_dataSyncEntityUpdate_success")
    let entity = try XCTUnwrap(event.updatedDataSyncEntity)

    XCTAssertEqual(entity.id, expectedEntity.id)
    XCTAssertEqual(entity.className, expectedEntity.className)
    XCTAssertEqual(entity.classLevel, expectedEntity.classLevel)
    XCTAssertEqual(entity.classVersion, expectedEntity.classVersion)
    XCTAssertEqual(entity.createdAt, expectedEntity.createdAt)
    XCTAssertEqual(entity.updatedAt, expectedEntity.updatedAt)
    XCTAssertEqual(entity.eTag, expectedEntity.eTag)
    XCTAssertEqual(entity.expiresAt, expectedEntity.expiresAt)
    XCTAssertEqual(entity.status, expectedEntity.status)
    XCTAssertPayload(entity.payload, equals: expectedPayload)
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
    let expectedPayload = RelationshipPayload(
      role: "attending",
      since: "2024-01-15",
      isPrimary: true,
      visitsPerMonth: 3
    )
    let expectedRelationship = PubNubDataSyncRelationship(
      id: "hcn-rel-attending-carter-alice",
      className: "attending-physician",
      classVersion: 1,
      entityAId: "hcn-practitioner-carter",
      entityBId: "hcn-patient-alice",
      createdAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:11:35.242585Z")),
      updatedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:11:35.242585Z")),
      eTag: "3w5e111hppyni",
      expiresAt: try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2027-07-29T00:00:00Z")),
      status: "active",
      payload: expectedPayload
    )

    let event = try decodeEvent(from: "subscription_dataSyncRelationshipCreate_success")
    let relationship = try XCTUnwrap(event.createdDataSyncRelationship)

    XCTAssertEqual(relationship.id, expectedRelationship.id)
    XCTAssertEqual(relationship.className, expectedRelationship.className)
    XCTAssertEqual(relationship.classVersion, expectedRelationship.classVersion)
    XCTAssertEqual(relationship.entityAId, expectedRelationship.entityAId)
    XCTAssertEqual(relationship.entityBId, expectedRelationship.entityBId)
    XCTAssertEqual(relationship.createdAt, expectedRelationship.createdAt)
    XCTAssertEqual(relationship.updatedAt, expectedRelationship.updatedAt)
    XCTAssertEqual(relationship.eTag, expectedRelationship.eTag)
    XCTAssertEqual(relationship.expiresAt, expectedRelationship.expiresAt)
    XCTAssertEqual(relationship.status, expectedRelationship.status)
    XCTAssertPayload(relationship.payload, equals: expectedPayload)
  }

  func test_Subscribe_WithDataSyncRelationshipUpdateEvent_ReceivesRelationship() throws {
    let expectedPayload = RelationshipPayload(
      role: "consulting",
      since: "2024-01-15",
      isPrimary: false,
      visitsPerMonth: 1
    )
    let expectedRelationship = PubNubDataSyncRelationship(
      id: "hcn-rel-attending-carter-alice",
      className: "attending-physician",
      classVersion: 1,
      entityAId: "hcn-practitioner-carter",
      entityBId: "hcn-patient-alice",
      createdAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:11:35.242585Z")),
      updatedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-07-28T09:24:50.283068Z")),
      eTag: "3w5e111hq6zil",
      expiresAt: try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2027-07-29T00:00:00Z")),
      status: "active",
      payload: expectedPayload
    )

    let event = try decodeEvent(from: "subscription_dataSyncRelationshipUpdate_success")
    let relationship = try XCTUnwrap(event.updatedDataSyncRelationship)

    XCTAssertEqual(relationship.id, expectedRelationship.id)
    XCTAssertEqual(relationship.className, expectedRelationship.className)
    XCTAssertEqual(relationship.classVersion, expectedRelationship.classVersion)
    XCTAssertEqual(relationship.entityAId, expectedRelationship.entityAId)
    XCTAssertEqual(relationship.entityBId, expectedRelationship.entityBId)
    XCTAssertEqual(relationship.createdAt, expectedRelationship.createdAt)
    XCTAssertEqual(relationship.updatedAt, expectedRelationship.updatedAt)
    XCTAssertEqual(relationship.eTag, expectedRelationship.eTag)
    XCTAssertEqual(relationship.expiresAt, expectedRelationship.expiresAt)
    XCTAssertEqual(relationship.status, expectedRelationship.status)
    XCTAssertPayload(relationship.payload, equals: expectedPayload)
  }

  func test_Subscribe_WithDataSyncRelationshipDeleteEvent_ReceivesRemovedRelationship() throws {
    let expectedRemoval = PubNubDataSyncRemovedRelationship(
      id: "hcn-rel-attending-tanaka-dubois",
      className: "attending-physician",
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
    for missingField in ["eTag"] {
      var data: [String: Any] = [
        "id": "hcn-patient-alice",
        "createdAt": "2026-07-28T09:11:17.077390Z",
        "updatedAt": "2026-07-28T09:11:17.077390Z",
        "eTag": "3w5e111hppk83"
      ]

      data.removeValue(forKey: missingField)

      let payload = mockDataSyncPayload(data: data)
      let event = payload.asPubNubEvent()

      XCTAssertNotNil(event.message, "An envelope missing \(missingField) should degrade to a message")
    }
  }

  func test_Subscribe_WithMalformedDataSyncEnvelope_ReceivesMessage() {
    let payload = generateMessage(with: .dataSync, payload: MalformedDataSyncPayload().codableValue)
    XCTAssertNotNil(payload.asPubNubEvent().message)
  }

  func test_Subscribe_WithUnrecognizedDataSyncObjectType_ReceivesMessage() {
    XCTAssertNotNil(mockDataSyncPayload(type: "membership").asPubNubEvent().message)
  }

  func test_DataSyncAction_MapsToUnknownMessageType() {
    XCTAssertEqual(SubscribeMessagePayload.Action.dataSync.asPubNubMessageType, .unknown)
  }
}

// MARK: - Built-In User And Channel Response

extension SubscribeRouterTests {
  func test_Subscribe_WithDataSyncUserCreateEvent_ReceivesEntity() throws {
    let event = try decodeEvent(from: "subscription_dataSyncUserCreate_success")
    let entity = try XCTUnwrap(event.createdDataSyncEntity)

    XCTAssertEqual(entity.id, "alice")
    XCTAssertEqual(entity.className, "User")
    XCTAssertEqual(entity.classLevel, .global)
    XCTAssertEqual(entity.classVersion, 1)
    XCTAssertEqual(entity.createdAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:04:09.341705Z")))
    XCTAssertEqual(entity.updatedAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:04:09.341705Z")))
    XCTAssertEqual(entity.eTag, "3w5e1124xczi3")
    XCTAssertEqual(entity.expiresAt, try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2026-09-13T00:00:00Z")))
    XCTAssertNil(entity.status)

    XCTAssertPayload(
      entity.payload,
      equals: UserPayload(
        name: "Alice Summers",
        email: "alice@example.com",
        type: "employee",
        profileUrl: "https://example.com/users/alice"
      )
    )
  }

  func test_Subscribe_WithDataSyncUserUpdateEvent_ReceivesEntity() throws {
    let event = try decodeEvent(from: "subscription_dataSyncUserUpdate_success")
    let entity = try XCTUnwrap(event.updatedDataSyncEntity)

    XCTAssertEqual(entity.id, "alice")
    XCTAssertEqual(entity.className, "User")
    XCTAssertEqual(entity.classLevel, .global)
    XCTAssertEqual(entity.classVersion, 1)
    XCTAssertEqual(entity.createdAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:04:09.341705Z")))
    XCTAssertEqual(entity.updatedAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:08:48.220914Z")))
    XCTAssertEqual(entity.eTag, "3w5e1124yb7pn")
    XCTAssertEqual(entity.status, "active")

    XCTAssertPayload(
      entity.payload,
      equals: UserPayload(
        name: "Alice Example-Summers",
        email: "alice.summers@example.com",
        type: "contractor",
        profileUrl: "https://example.com/users/alice"
      )
    )
  }

  func test_Subscribe_WithDataSyncUserDeleteEvent_ReceivesRemovedEntity() throws {
    let event = try decodeEvent(from: "subscription_dataSyncUserDelete_success")
    let removed = try XCTUnwrap(event.deletedDataSyncEntity)

    XCTAssertEqual(
      removed,
      PubNubDataSyncRemovedObject(
        id: "alice",
        className: "User",
        classLevel: .global,
        classVersion: 1,
        deletedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:11:41.577263Z"))
      )
    )
  }

  func test_Subscribe_WithDataSyncChannelCreateEvent_ReceivesEntity() throws {
    let event = try decodeEvent(from: "subscription_dataSyncChannelCreate_success")
    let entity = try XCTUnwrap(event.createdDataSyncEntity)

    XCTAssertEqual(entity.id, "general")
    XCTAssertEqual(entity.className, "Channel")
    XCTAssertEqual(entity.classLevel, .global)
    XCTAssertEqual(entity.classVersion, 1)
    XCTAssertEqual(entity.createdAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:04:31.205811Z")))
    XCTAssertEqual(entity.updatedAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:04:31.205811Z")))
    XCTAssertEqual(entity.eTag, "3w5e1124xkm7f")
    XCTAssertEqual(entity.expiresAt, try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2026-09-13T00:00:00Z")))
    XCTAssertNil(entity.status)
    XCTAssertPayload(entity.payload, equals: ChannelPayload(name: "General", description: "Company-wide announcements"))
  }

  func test_Subscribe_WithDataSyncChannelUpdateEvent_ReceivesEntity() throws {
    let event = try decodeEvent(from: "subscription_dataSyncChannelUpdate_success")
    let entity = try XCTUnwrap(event.updatedDataSyncEntity)

    XCTAssertEqual(entity.id, "general")
    XCTAssertEqual(entity.className, "Channel")
    XCTAssertEqual(entity.classLevel, .global)
    XCTAssertEqual(entity.classVersion, 1)
    XCTAssertEqual(entity.createdAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:04:31.205811Z")))
    XCTAssertEqual(entity.updatedAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:09:09.120477Z")))
    XCTAssertEqual(entity.eTag, "3w5e1124yh2ql")
    XCTAssertEqual(entity.status, "archived")

    XCTAssertPayload(
      entity.payload,
      equals: ChannelPayload(name: "General Announcements", description: "Company-wide announcements and updates")
    )
  }

  func test_Subscribe_WithDataSyncChannelDeleteEvent_ReceivesRemovedEntity() throws {
    let event = try decodeEvent(from: "subscription_dataSyncChannelDelete_success")
    let removed = try XCTUnwrap(event.deletedDataSyncEntity)

    XCTAssertEqual(
      removed,
      PubNubDataSyncRemovedObject(
        id: "general",
        className: "Channel",
        classLevel: .global,
        classVersion: 1,
        deletedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:12:02.731055Z"))
      )
    )
  }
}

// MARK: - Built-In Membership Response

extension SubscribeRouterTests {
  func test_Subscribe_WithDataSyncMembershipCreateEvent_ReceivesRelationship() throws {
    let event = try decodeEvent(from: "subscription_dataSyncMembershipCreate_success")
    let relationship = try XCTUnwrap(event.createdDataSyncRelationship)

    XCTAssertEqual(relationship.id, "general__alice")
    XCTAssertEqual(relationship.className, "Membership")
    XCTAssertEqual(relationship.classVersion, 1)
    XCTAssertEqual(relationship.entityAId, "general")
    XCTAssertEqual(relationship.entityBId, "alice")
    XCTAssertEqual(relationship.createdAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:59:28.334186Z")))
    XCTAssertEqual(relationship.updatedAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:59:28.334186Z")))
    XCTAssertEqual(relationship.eTag, "3w5e1124zc4ve")
    XCTAssertEqual(relationship.expiresAt, try XCTUnwrap(DateFormatter.iso8601_noMilliseconds.date(from: "2026-09-13T00:00:00Z")))
    XCTAssertNil(relationship.status)

    XCTAssertPayload(
      relationship.payload,
      equals: MembershipPayload(
        role: "member",
        joinedVia: "invite-link",
        notifications: "all"
      )
    )
  }

  func test_Subscribe_WithDataSyncMembershipUpdateEvent_ReceivesRelationship() throws {
    let event = try decodeEvent(from: "subscription_dataSyncMembershipUpdate_success")
    let relationship = try XCTUnwrap(event.updatedDataSyncRelationship)

    XCTAssertEqual(relationship.id, "general__alice")
    XCTAssertEqual(relationship.className, "Membership")
    XCTAssertEqual(relationship.classVersion, 1)
    XCTAssertEqual(relationship.entityAId, "general")
    XCTAssertEqual(relationship.entityBId, "alice")
    XCTAssertEqual(relationship.createdAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T15:59:28.334186Z")))
    XCTAssertEqual( relationship.updatedAt, try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T16:02:21.882304Z")))
    XCTAssertEqual(relationship.eTag, "3w5e1124zn8qm")
    XCTAssertEqual(relationship.status, "active")

    XCTAssertPayload(
      relationship.payload,
      equals: MembershipPayload(role: "moderator", joinedVia: "invite-link", notifications: "mentions")
    )
  }

  func test_Subscribe_WithDataSyncMembershipDeleteEvent_ReceivesRemovedRelationship() throws {
    let event = try decodeEvent(from: "subscription_dataSyncMembershipDelete_success")
    let removed = try XCTUnwrap(event.deletedDataSyncRelationship)

    XCTAssertEqual(
      removed,
      PubNubDataSyncRemovedRelationship(
        id: "general__alice",
        className: "Membership",
        classVersion: 1,
        deletedAt: try XCTUnwrap(DateFormatter.iso8601.date(from: "2026-08-13T16:05:15.029431Z"))
      )
    )
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

// MARK: - Built-In User And Channel Delivery Through The Subscribe Loop

extension SubscribeRouterTests {
  func test_Subscribe_WithDataSyncUserCreateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncUserCreate_success",
      channel: "alice"
    )

    XCTAssertEqual(events.legacy.createdEntity?.id, "alice")
    XCTAssertEqual(events.legacy.createdEntity?.className, "User")
    XCTAssertEqual(events.legacy.createdEntity?.classLevel, .global)
    XCTAssertEqual(events.modern.createdEntity?.id, "alice")
    XCTAssertEqual(events.modern.createdEntity?.className, "User")
    XCTAssertEqual(events.modern.createdEntity?.classLevel, .global)
  }

  func test_Subscribe_WithDataSyncUserUpdateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncUserUpdate_success",
      channel: "alice"
    )

    XCTAssertEqual(events.legacy.updatedEntity?.id, "alice")
    XCTAssertEqual(events.legacy.updatedEntity?.className, "User")
    XCTAssertEqual(events.legacy.updatedEntity?.classLevel, .global)
    XCTAssertEqual(events.modern.updatedEntity?.id, "alice")
    XCTAssertEqual(events.modern.updatedEntity?.className, "User")
    XCTAssertEqual(events.modern.updatedEntity?.classLevel, .global)
  }

  func test_Subscribe_WithDataSyncUserDeleteEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncUserDelete_success",
      channel: "alice"
    )

    XCTAssertEqual(events.legacy.deletedEntity?.id, "alice")
    XCTAssertEqual(events.legacy.deletedEntity?.className, "User")
    XCTAssertEqual(events.legacy.deletedEntity?.classLevel, .global)
    XCTAssertEqual(events.modern.deletedEntity?.id, "alice")
    XCTAssertEqual(events.modern.deletedEntity?.className, "User")
    XCTAssertEqual(events.modern.deletedEntity?.classLevel, .global)
  }

  func test_Subscribe_WithDataSyncChannelCreateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncChannelCreate_success",
      channel: "general"
    )

    XCTAssertEqual(events.legacy.createdEntity?.id, "general")
    XCTAssertEqual(events.legacy.createdEntity?.className, "Channel")
    XCTAssertEqual(events.legacy.createdEntity?.classLevel, .global)
    XCTAssertEqual(events.modern.createdEntity?.id, "general")
    XCTAssertEqual(events.modern.createdEntity?.className, "Channel")
    XCTAssertEqual(events.modern.createdEntity?.classLevel, .global)
  }

  func test_Subscribe_WithDataSyncChannelUpdateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncChannelUpdate_success",
      channel: "general"
    )

    XCTAssertEqual(events.legacy.updatedEntity?.id, "general")
    XCTAssertEqual(events.legacy.updatedEntity?.className, "Channel")
    XCTAssertEqual(events.legacy.updatedEntity?.classLevel, .global)
    XCTAssertEqual(events.modern.updatedEntity?.id, "general")
    XCTAssertEqual(events.modern.updatedEntity?.className, "Channel")
    XCTAssertEqual(events.modern.updatedEntity?.classLevel, .global)
  }

  func test_Subscribe_WithDataSyncChannelDeleteEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncChannelDelete_success",
      channel: "general"
    )

    XCTAssertEqual(events.legacy.deletedEntity?.id, "general")
    XCTAssertEqual(events.legacy.deletedEntity?.className, "Channel")
    XCTAssertEqual(events.legacy.deletedEntity?.classLevel, .global)
    XCTAssertEqual(events.modern.deletedEntity?.id, "general")
    XCTAssertEqual(events.modern.deletedEntity?.className, "Channel")
    XCTAssertEqual(events.modern.deletedEntity?.classLevel, .global)
  }
}

// MARK: - Built-In Membership Delivery Through The Subscribe Loop

extension SubscribeRouterTests {
  func test_Subscribe_WithDataSyncMembershipCreateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncMembershipCreate_success",
      channel: "alice"
    )

    XCTAssertEqual(events.legacy.createdRelationship?.id, "general__alice")
    XCTAssertEqual(events.legacy.createdRelationship?.className, "Membership")
    XCTAssertEqual(events.legacy.createdRelationship?.entityAId, "general")
    XCTAssertEqual(events.legacy.createdRelationship?.entityBId, "alice")
    XCTAssertEqual(events.modern.createdRelationship?.id, "general__alice")
    XCTAssertEqual(events.modern.createdRelationship?.className, "Membership")
    XCTAssertEqual(events.modern.createdRelationship?.entityAId, "general")
    XCTAssertEqual(events.modern.createdRelationship?.entityBId, "alice")
  }

  func test_Subscribe_WithDataSyncMembershipUpdateEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncMembershipUpdate_success",
      channel: "alice"
    )

    XCTAssertEqual(events.legacy.updatedRelationship?.id, "general__alice")
    XCTAssertEqual(events.legacy.updatedRelationship?.className, "Membership")
    XCTAssertEqual(events.legacy.updatedRelationship?.entityAId, "general")
    XCTAssertEqual(events.legacy.updatedRelationship?.entityBId, "alice")
    XCTAssertEqual(events.modern.updatedRelationship?.id, "general__alice")
    XCTAssertEqual(events.modern.updatedRelationship?.className, "Membership")
    XCTAssertEqual(events.modern.updatedRelationship?.entityAId, "general")
    XCTAssertEqual(events.modern.updatedRelationship?.entityBId, "alice")
  }

  func test_Subscribe_WithDataSyncMembershipDeleteEvent_EmitsToListeners() throws {
    let events = try emittedDataSyncEvents(
      fromFixture: "subscription_dataSyncMembershipDelete_success",
      channel: "alice"
    )

    XCTAssertEqual(events.legacy.deletedRelationship?.id, "general__alice")
    XCTAssertEqual(events.legacy.deletedRelationship?.className, "Membership")
    XCTAssertEqual(events.legacy.deletedRelationship?.classVersion, 1)
    XCTAssertEqual(events.modern.deletedRelationship?.id, "general__alice")
    XCTAssertEqual(events.modern.deletedRelationship?.className, "Membership")
    XCTAssertEqual(events.modern.deletedRelationship?.classVersion, 1)
  }
}

// MARK: Helpers

private extension SubscribeRouterTests {
  struct MalformedDataSyncPayload: JSONCodable, Equatable {
    let not: String

    init(not: String = "a datasync envelope") {
      self.not = not
    }
  }

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

  var deletedRelationship: PubNubDataSyncRemovedRelationship? {
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

  var deletedDataSyncRelationship: PubNubDataSyncRemovedRelationship? {
    guard case let .dataSyncChanged(.relationshipDeleted(r)) = self else { return nil }
    return r
  }
}
