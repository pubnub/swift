//
//  DataSyncRelationshipEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

/// Exercises the generic relationship endpoints against the healthcare classes registered on the keyset.
class DataSyncRelationshipEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: DataSyncRelationshipEndpointIntegrationTests.self)
  let attendingPhysicianClass = HealthcareClass.attendingPhysician
  let facilityAffiliationClass = HealthcareClass.facilityAffiliation

  func testCreateAndFetchRelationship() {
    let fetchExpect = expectation(description: "Fetch Relationship Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let patientId = randomString()
    let relationshipId = randomString()
    let payload = TestAttendingPhysicianPayload(role: "attending", since: "2024-01-15")

    createEntities(client: client, [.practitioner(id: practitionerId), .patient(id: patientId)])

    client.dataSync.createRelationship(
      relationshipClass: attendingPhysicianClass.name,
      entityAId: practitionerId,
      entityBId: patientId,
      relationshipClassVersion: attendingPhysicianClass.version,
      id: relationshipId,
      status: "active",
      payload: payload
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdRelationship):
        XCTAssertEqual(createdRelationship.id, relationshipId)
        XCTAssertFalse(createdRelationship.eTag.isEmpty)

        client.dataSync.getRelationship(relationshipId) { fetchResult in
          switch fetchResult {
          case let .success(relationship):
            XCTAssertEqual(relationship.id, relationshipId)
            XCTAssertEqual(relationship.className, self.attendingPhysicianClass.name)
            XCTAssertEqual(relationship.classVersion, self.attendingPhysicianClass.version)
            XCTAssertEqual(relationship.entityAId, practitionerId)
            XCTAssertEqual(relationship.entityBId, patientId)
            XCTAssertEqual(relationship.status, "active")
            XCTAssertEqual(relationship.eTag, createdRelationship.eTag)
            XCTAssertPayload(relationship.payload, equals: payload)
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
      removeRelationships(client: client, ids: [relationshipId])
      removeEntities(client: client, ids: [practitionerId, patientId])
    }

    wait(for: [fetchExpect], timeout: 15.0)
  }

  func testReplaceRelationshipReplacesPayloadWholesale() {
    let replaceExpect = expectation(description: "Replace Relationship Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let patientId = randomString()
    let relationshipId = randomString()

    createEntities(client: client, [.practitioner(id: practitionerId), .patient(id: patientId)])

    client.dataSync.createRelationship(
      relationshipClass: attendingPhysicianClass.name,
      entityAId: practitionerId,
      entityBId: patientId,
      relationshipClassVersion: attendingPhysicianClass.version,
      id: relationshipId,
      status: "active",
      payload: TestAttendingPhysicianPayload(role: "attending", since: "2024-01-15")
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdRelationship):
        // The replacement omits `since`, which must therefore be cleared rather than preserved
        let replacementPayload = TestAttendingPhysicianPayload(role: "consulting")

        client.dataSync.replaceRelationship(
          relationshipId,
          relationshipClassVersion: self.attendingPhysicianClass.version,
          status: "inactive",
          payload: replacementPayload
        ) { replaceResult in
          switch replaceResult {
          case let .success(replacedRelationship):
            XCTAssertEqual(replacedRelationship.id, relationshipId)
            XCTAssertEqual(replacedRelationship.entityAId, practitionerId)
            XCTAssertEqual(replacedRelationship.entityBId, patientId)
            XCTAssertEqual(replacedRelationship.status, "inactive")
            XCTAssertPayload(replacedRelationship.payload, equals: replacementPayload)
            XCTAssertNotEqual(replacedRelationship.eTag, createdRelationship.eTag)
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
      removeRelationships(client: client, ids: [relationshipId])
      removeEntities(client: client, ids: [practitionerId, patientId])
    }

    wait(for: [replaceExpect], timeout: 15.0)
  }

  func testPatchRelationshipAppliesOperationsAndKeepsUntouchedFields() {
    let patchExpect = expectation(description: "Patch Relationship Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let patientId = randomString()
    let relationshipId = randomString()

    createEntities(client: client, [.practitioner(id: practitionerId), .patient(id: patientId)])

    client.dataSync.createRelationship(
      relationshipClass: attendingPhysicianClass.name,
      entityAId: practitionerId,
      entityBId: patientId,
      relationshipClassVersion: attendingPhysicianClass.version,
      id: relationshipId,
      status: "active",
      payload: TestAttendingPhysicianPayload(role: "attending", since: "2024-01-15")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        let expectedPayload = TestAttendingPhysicianPayload(
          role: "consulting",
          since: "2024-01-15",
          reviewCadenceDays: 60
        )

        client.dataSync.patchRelationship(
          relationshipId,
          operations: [
            .replace(path: "/payload/role", value: "consulting"),
            .add(path: "/payload/reviewCadenceDays", value: 60)
          ]
        ) { patchResult in
          switch patchResult {
          case let .success(patchedRelationship):
            XCTAssertPayload(patchedRelationship.payload, equals: expectedPayload)
            XCTAssertEqual(patchedRelationship.status, "active")
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
      removeRelationships(client: client, ids: [relationshipId])
      removeEntities(client: client, ids: [practitionerId, patientId])
    }

    wait(for: [patchExpect], timeout: 15.0)
  }

  func testReplaceRelationshipWithStaleEtagFails() {
    let replaceExpect = expectation(description: "Replace Relationship Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let patientId = randomString()
    let relationshipId = randomString()

    createEntities(
      client: client,
      [.practitioner(id: practitionerId), .patient(id: patientId)]
    )
    createRelationships(
      client: client,
      [.attendingPhysician(id: relationshipId, practitionerId: practitionerId, patientId: patientId)]
    )

    client.dataSync.replaceRelationship(
      relationshipId,
      relationshipClassVersion: attendingPhysicianClass.version,
      status: "inactive",
      payload: TestAttendingPhysicianPayload(role: "consulting"),
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

    defer {
      removeRelationships(client: client, ids: [relationshipId])
      removeEntities(client: client, ids: [practitionerId, patientId])
    }

    wait(for: [replaceExpect], timeout: 15.0)
  }

  func testGetRelationshipsReturnsCreatedRelationships() {
    let listExpect = expectation(description: "List Relationships Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let patientIds = [randomString(), randomString()]
    let relationshipIds = [randomString(), randomString()]

    createEntities(
      client: client,
      [.practitioner(id: practitionerId)] + patientIds.map { .patient(id: $0) }
    )
    createRelationships(
      client: client,
      zip(relationshipIds, patientIds).map {
        .attendingPhysician(id: $0, practitionerId: practitionerId, patientId: $1)
      }
    )

    client.dataSync.getRelationships(relationshipClass: attendingPhysicianClass.name, limit: 100) { result in
      switch result {
      case let .success((relationships, _)):
        let fetchedIds = Set(relationships.map { $0.id })
        XCTAssertTrue(Set(relationshipIds).isSubset(of: fetchedIds))
        XCTAssertTrue(relationships.allSatisfy { $0.className == self.attendingPhysicianClass.name })
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      removeRelationships(client: client, ids: relationshipIds)
      removeEntities(client: client, ids: [practitionerId] + patientIds)
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testGetRelationshipsPagesWithCursor() {
    let listExpect = expectation(description: "List Relationships Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let patientIds = [randomString(), randomString()]
    let relationshipIds = [randomString(), randomString()]

    createEntities(
      client: client,
      [.practitioner(id: practitionerId)] + patientIds.map { .patient(id: $0) }
    )
    createRelationships(
      client: client,
      zip(relationshipIds, patientIds).map {
        .attendingPhysician(id: $0, practitionerId: practitionerId, patientId: $1)
      }
    )

    client.dataSync.getRelationships(
      relationshipClass: attendingPhysicianClass.name,
      limit: 1
    ) { firstResult in
      switch firstResult {
      case let .success((firstPage, next)):
        XCTAssertEqual(firstPage.count, 1)
        XCTAssertEqual(next?.limit, 1)
        XCTAssertNotNil(next?.cursor)
        XCTAssertTrue(next?.hasNext ?? false)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      removeRelationships(client: client, ids: relationshipIds)
      removeEntities(client: client, ids: [practitionerId] + patientIds)
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testGetRelationshipsForEntityAReturnsEveryPatientAttended() {
    let listExpect = expectation(description: "List Relationships Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let firstPatientId = randomString()
    let secondPatientId = randomString()
    let firstRelationshipId = randomString()
    let secondRelationshipId = randomString()

    createEntities(
      client: client,
      [.practitioner(id: practitionerId), .patient(id: firstPatientId), .patient(id: secondPatientId)]
    )
    createRelationships(client: client, [
      .attendingPhysician(id: firstRelationshipId, practitionerId: practitionerId, patientId: firstPatientId),
      .attendingPhysician(id: secondRelationshipId, practitionerId: practitionerId, patientId: secondPatientId)
    ])

    client.dataSync.getRelationships(
      relationshipClass: attendingPhysicianClass.name,
      entityAId: practitionerId
    ) { result in
      switch result {
      case let .success((relationships, _)):
        XCTAssertEqual(Set(relationships.map { $0.id }), [firstRelationshipId, secondRelationshipId])
        XCTAssertEqual(Set(relationships.map { $0.entityBId }), [firstPatientId, secondPatientId])
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      removeRelationships(client: client, ids: [firstRelationshipId, secondRelationshipId])
      removeEntities(client: client, ids: [practitionerId, firstPatientId, secondPatientId])
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testGetRelationshipsForEntityBReturnsOnlyThatPatientsPractitioner() {
    let listExpect = expectation(description: "List Relationships Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let patientId = randomString()
    let otherPatientId = randomString()
    let relationshipId = randomString()
    let otherRelationshipId = randomString()

    createEntities(
      client: client,
      [.practitioner(id: practitionerId), .patient(id: patientId), .patient(id: otherPatientId)]
    )
    // The practitioner attends both patients, so only side B distinguishes the two relationships
    createRelationships(client: client, [
      .attendingPhysician(id: relationshipId, practitionerId: practitionerId, patientId: patientId),
      .attendingPhysician(id: otherRelationshipId, practitionerId: practitionerId, patientId: otherPatientId)
    ])

    client.dataSync.getRelationships(
      relationshipClass: attendingPhysicianClass.name,
      entityBId: patientId
    ) { result in
      switch result {
      case let .success((relationships, _)):
        XCTAssertEqual(relationships.map { $0.id }, [relationshipId])
        XCTAssertEqual(relationships.first?.entityAId, practitionerId)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      removeRelationships(client: client, ids: [relationshipId, otherRelationshipId])
      removeEntities(client: client, ids: [practitionerId, patientId, otherPatientId])
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testManyToManyRelationshipConnectsOnePractitionerToSeveralFacilities() {
    let listExpect = expectation(description: "List Relationships Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let hospitalId = randomString()
    let clinicId = randomString()
    let hospitalAffiliationId = randomString()
    let clinicAffiliationId = randomString()

    createEntities(
      client: client,
      [.practitioner(id: practitionerId), .careFacility(id: hospitalId), .careFacility(id: clinicId)]
    )
    // `facility-affiliation` is many-to-many, so the same practitioner may sit on side B of both
    createRelationships(client: client, [
      .facilityAffiliation(id: hospitalAffiliationId, careFacilityId: hospitalId, practitionerId: practitionerId),
      .facilityAffiliation(id: clinicAffiliationId, careFacilityId: clinicId, practitionerId: practitionerId)
    ])

    client.dataSync.getRelationships(
      relationshipClass: facilityAffiliationClass.name,
      entityBId: practitionerId
    ) { result in
      switch result {
      case let .success((relationships, _)):
        XCTAssertEqual(Set(relationships.map { $0.id }), [hospitalAffiliationId, clinicAffiliationId])
        XCTAssertEqual(Set(relationships.map { $0.entityAId }), [hospitalId, clinicId])
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      removeRelationships(client: client, ids: [hospitalAffiliationId, clinicAffiliationId])
      removeEntities(client: client, ids: [practitionerId, hospitalId, clinicId])
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testRemoveRelationshipThenFetchFails() {
    let removeExpect = expectation(description: "Remove Relationship Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(bundle: testsBundle))
    let practitionerId = randomString()
    let patientId = randomString()
    let relationshipId = randomString()

    createEntities(
      client: client,
      [.practitioner(id: practitionerId), .patient(id: patientId)]
    )
    createRelationships(
      client: client,
      [.attendingPhysician(id: relationshipId, practitionerId: practitionerId, patientId: patientId)]
    )

    client.dataSync.removeRelationship(relationshipId) { [unowned client] removeResult in
      switch removeResult {
      case .success:
        client.dataSync.getRelationship(relationshipId) { fetchResult in
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

    // Only the entities need cleaning up: removing the relationship is the subject of this test
    defer {
      removeEntities(client: client, ids: [practitionerId, patientId])
    }

    wait(for: [removeExpect], timeout: 15.0)
  }
}
