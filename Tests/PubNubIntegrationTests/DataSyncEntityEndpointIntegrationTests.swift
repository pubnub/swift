//
//  DataSyncEntityEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

class DataSyncEntityEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: DataSyncEntityEndpointIntegrationTests.self)
  let patientClass = HealthcareClass.patient
  let practitionerClass = HealthcareClass.practitioner

  func testCreateAndFetchEntity() {
    let fetchExpect = expectation(description: "Fetch Entity Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()
    let payload = TestPatientPayload.standard(mrn: "MRN-100001")

    client.dataSync.createEntity(
      entityClass: patientClass.name,
      entityClassVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: payload
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdEntity):
        XCTAssertEqual(createdEntity.id, patientId)
        XCTAssertFalse(createdEntity.eTag.isEmpty)

        client.dataSync.getEntity(patientId) { fetchResult in
          switch fetchResult {
          case let .success(entity):
            XCTAssertEqual(entity.id, patientId)
            XCTAssertEqual(entity.className, self.patientClass.name)
            XCTAssertEqual(entity.classVersion, self.patientClass.version)
            XCTAssertEqual(entity.status, "active")
            XCTAssertEqual(entity.eTag, createdEntity.eTag)
            XCTAssertPayload(entity.payload, equals: payload)
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
      removeEntities(client: client, ids: [patientId])
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testReplaceEntityReplacesPayloadWholesale() {
    let replaceExpect = expectation(description: "Replace Entity Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    client.dataSync.createEntity(
      entityClass: patientClass.name,
      entityClassVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: TestPatientPayload.standard(mrn: "MRN-100003")
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdEntity):
        // The replacement omits every field but `fullName`, which must therefore be cleared rather than preserved
        let replacementPayload = TestPatientPayload(fullName: "Swift ITest Patient Renamed")

        client.dataSync.replaceEntity(
          patientId,
          entityClassVersion: self.patientClass.version,
          status: "inactive",
          payload: replacementPayload
        ) { replaceResult in
          switch replaceResult {
          case let .success(replacedEntity):
            XCTAssertEqual(replacedEntity.id, patientId)
            XCTAssertEqual(replacedEntity.status, "inactive")
            XCTAssertPayload(replacedEntity.payload, equals: replacementPayload)
            XCTAssertNotEqual(replacedEntity.eTag, createdEntity.eTag)
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
      removeEntities(client: client, ids: [patientId])
    }

    wait(for: [replaceExpect], timeout: 10.0)
  }

  func testPatchEntityAppliesOperationsAndKeepsUntouchedFields() {
    let patchExpect = expectation(description: "Patch Entity Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    client.dataSync.createEntity(
      entityClass: patientClass.name,
      entityClassVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: TestPatientPayload.standard(mrn: "MRN-100004")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        // `mrn`, `dateOfBirth`, and `diagnosis` go untouched by the operations below and must survive them
        let expectedPayload = TestPatientPayload(
          mrn: "MRN-100004",
          fullName: "Swift ITest Patient Renamed",
          dateOfBirth: "1985-04-12",
          diagnosis: "Type 2 diabetes",
          preferredLanguage: "en"
        )

        client.dataSync.patchEntity(
          patientId,
          operations: [
            .replace(path: "/payload/fullName", value: "Swift ITest Patient Renamed"),
            .add(path: "/payload/preferredLanguage", value: "en")
          ]
        ) { patchResult in
          switch patchResult {
          case let .success(patchedEntity):
            XCTAssertPayload(patchedEntity.payload, equals: expectedPayload)
            XCTAssertEqual(patchedEntity.status, "active")
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
      removeEntities(client: client, ids: [patientId])
    }

    wait(for: [patchExpect], timeout: 10.0)
  }

  func testReplaceEntityWithStaleEtagFails() {
    let replaceExpect = expectation(description: "Replace Entity Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    client.dataSync.createEntity(
      entityClass: patientClass.name,
      entityClassVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: TestPatientPayload.standard(mrn: "MRN-100005")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.replaceEntity(
          patientId,
          entityClassVersion: self.patientClass.version,
          status: "inactive",
          payload: TestPatientPayload(fullName: "Swift ITest Patient Renamed"),
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
      removeEntities(client: client, ids: [patientId])
    }

    wait(for: [replaceExpect], timeout: 10.0)
  }

  func testCreateEntityWithDuplicateIdFails() {
    let duplicateExpect = expectation(description: "Duplicate Entity Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    createEntities(client: client, [.patient(id: patientId)])

    // The conflict is keyed on the identifier alone, so a wholly different payload still collides
    client.dataSync.createEntity(
      entityClass: patientClass.name,
      entityClassVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: TestPatientPayload(mrn: "MRN-999999", fullName: "Someone Else Entirely", diagnosis: "Migraine")
    ) { createResult in
      switch createResult {
      case .success:
        XCTFail("Test should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError?.reason, .conflict)
      }
      duplicateExpect.fulfill()
    }

    defer {
      removeEntities(client: client, ids: [patientId])
    }

    wait(for: [duplicateExpect], timeout: 15.0)
  }

  func testGetEntitiesReturnsCreatedEntities() {
    let listExpect = expectation(description: "List Entities Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(from: testsBundle))
    let patientIds = [randomString(), randomString(), randomString()]

    createEntities(client: client, patientIds.map { .patient(id: $0) })

    client.dataSync.getEntities(entityClass: patientClass.name) { result in
      switch result {
      case let .success((entities, _)):
        let fetchedIds = Set(entities.map { $0.id })
        XCTAssertTrue(Set(patientIds).isSubset(of: fetchedIds))
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      removeEntities(client: client, ids: patientIds)
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testGetEntitiesReturnsOnlyEntitiesOfTheRequestedClass() {
    let listExpect = expectation(description: "List Entities Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()
    let practitionerId = randomString()

    createEntities(client: client, [.patient(id: patientId), .practitioner(id: practitionerId)])

    client.dataSync.getEntities(entityClass: practitionerClass.name, limit: 100) { result in
      switch result {
      case let .success((entities, _)):
        let fetchedIds = Set(entities.map { $0.id })
        XCTAssertTrue(fetchedIds.contains(practitionerId))
        XCTAssertFalse(fetchedIds.contains(patientId))
        XCTAssertTrue(entities.allSatisfy { $0.className == self.practitionerClass.name })
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      removeEntities(client: client, ids: [patientId, practitionerId])
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testGetEntitiesPagesWithCursor() {
    let listExpect = expectation(description: "List Entities Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(from: testsBundle))
    let patientIds = [randomString(), randomString()]

    createEntities(client: client, patientIds.map { .patient(id: $0) })

    client.dataSync.getEntities(entityClass: patientClass.name, limit: 1) { firstResult in
      switch firstResult {
      case let .success((firstPage, next)):
        XCTAssertEqual(firstPage.count, 1)
        XCTAssertEqual(next?.limit, 1)
        XCTAssertTrue(next?.hasNext ?? false)
        listExpect.fulfill()
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        listExpect.fulfill()
      }
    }

    defer {
      removeEntities(client: client, ids: patientIds)
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testRemoveEntityThenFetchFails() {
    let removeExpect = expectation(description: "Remove Entity Expectation")
    let client = PubNub(configuration: dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    client.dataSync.createEntity(
      entityClass: patientClass.name,
      entityClassVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: TestPatientPayload.standard(mrn: "MRN-100006")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.removeEntity(patientId) { removeResult in
          switch removeResult {
          case .success:
            client.dataSync.getEntity(patientId) { fetchResult in
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

    // No cleanup: removing the entity is the subject of this test
    wait(for: [removeExpect], timeout: 10.0)
  }
}
