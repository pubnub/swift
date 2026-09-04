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
  let patientV2Class = HealthcareClass.patientV2
  let practitionerClass = HealthcareClass.practitioner

  func testCreateAndFetchEntity() throws {
    let fetchExpect = expectation(description: "Fetch Entity Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()
    let payload = TestPatientPayload.standard(mrn: "MRN-100001")

    client.dataSync.createEntity(
      className: patientClass.name,
      classVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: payload
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdEntity):
        XCTAssertEqual(createdEntity.id, patientId)
        XCTAssertFalse(createdEntity.eTag.isEmpty)

        client.dataSync.getEntity(id: patientId) { fetchResult in
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

  func testSetEntityReplacesPayloadWholesale() throws {
    let replaceExpect = expectation(description: "Replace Entity Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    client.dataSync.createEntity(
      className: patientClass.name,
      classVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: TestPatientPayload.standard(mrn: "MRN-100003")
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdEntity):
        // The replacement omits every field but `fullName`, which must therefore be cleared rather than preserved
        let replacementPayload = TestPatientPayload(fullName: "Swift ITest Patient Renamed")

        client.dataSync.setEntity(
          id: patientId,
          classVersion: self.patientClass.version,
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

  func testUpdateEntityAppliesOperationsAndKeepsUntouchedFields() throws {
    let patchExpect = expectation(description: "Patch Entity Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    client.dataSync.createEntity(
      className: patientClass.name,
      classVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: TestPatientPayload.standard(mrn: "MRN-100004")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        // `mrn` and `dateOfBirth` go untouched by the operations below and must survive them
        let expectedPayload = TestPatientPayload(
          mrn: "MRN-100004",
          fullName: "Swift ITest Patient Renamed",
          dateOfBirth: "1985-04-12",
          diagnosis: nil
        )

        client.dataSync.updateEntity(
          id: patientId,
          operations: [
            .replace(path: "/payload/fullName", value: "Swift ITest Patient Renamed"),
            .remove(path: "/payload/diagnosis")
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

  func testSetEntityWithStaleEtagFails() throws {
    let replaceExpect = expectation(description: "Replace Entity Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    client.dataSync.createEntity(
      className: patientClass.name,
      classVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: TestPatientPayload.standard(mrn: "MRN-100005")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.setEntity(
          id: patientId,
          classVersion: self.patientClass.version,
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

  func testCreateEntityWithDuplicateIdFails() throws {
    let duplicateExpect = expectation(description: "Duplicate Entity Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    createEntities(client: client, [.patient(id: patientId)])

    // The conflict is keyed on the identifier alone, so a wholly different payload still collides
    client.dataSync.createEntity(
      className: patientClass.name,
      classVersion: patientClass.version,
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

  func testGetEntitiesReturnsCreatedEntities() throws {
    let listExpect = expectation(description: "List Entities Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientIds = [randomString(), randomString(), randomString()]

    createEntities(client: client, patientIds.map { .patient(id: $0) })

    client.dataSync.getEntities(className: patientClass.name) { result in
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

  func testGetEntitiesReturnsOnlyEntitiesOfTheRequestedClass() throws {
    let listExpect = expectation(description: "List Entities Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()
    let practitionerId = randomString()

    createEntities(client: client, [.patient(id: patientId), .practitioner(id: practitionerId)])

    client.dataSync.getEntities(className: practitionerClass.name, limit: 100) { result in
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

  func testGetEntitiesPinnedToAClassVersionReturnsOnlyThatVersion() throws {
    let listExpect = expectation(description: "List Entities Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientV1Id = randomString()
    let patientV2Id = randomString()
    let ownEntitiesOnly = "mrn LIKE '\(Constants.prefix)*'"

    createEntities(client: client, [.patient(id: patientV1Id), .patientV2(id: patientV2Id)])

    client.dataSync.getEntities(
      className: patientClass.name,
      classVersion: patientClass.version,
      filterFast: ownEntitiesOnly
    ) { result in
      switch result {
      case let .success((v1Entities, _)):
        let v1Ids = Set(v1Entities.map { $0.id })
        XCTAssertTrue(v1Ids.contains(patientV1Id))
        XCTAssertFalse(v1Ids.contains(patientV2Id))
        XCTAssertTrue(v1Entities.allSatisfy { $0.className == self.patientClass.name })
        XCTAssertTrue(v1Entities.allSatisfy { $0.classVersion == self.patientClass.version })
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      removeEntities(client: client, ids: [patientV1Id, patientV2Id])
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testGetEntitiesWithoutAClassVersionReturnsEveryVersion() throws {
    let listExpect = expectation(description: "List Entities Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientV1Id = randomString()
    let patientV2Id = randomString()

    createEntities(client: client, [.patient(id: patientV1Id), .patientV2(id: patientV2Id)])

    client.dataSync.getEntities(
      className: patientClass.name,
      limit: 100,
      filterFast: "mrn LIKE '\(Constants.prefix)*'"
    ) { result in
      switch result {
      case let .success((entities, _)):
        let fetchedIds = Set(entities.map { $0.id })
        XCTAssertTrue(Set([patientV1Id, patientV2Id]).isSubset(of: fetchedIds))
        XCTAssertEqual(entities.first { $0.id == patientV1Id }?.classVersion, self.patientClass.version)
        XCTAssertEqual(entities.first { $0.id == patientV2Id }?.classVersion, self.patientV2Class.version)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      removeEntities(client: client, ids: [patientV1Id, patientV2Id])
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testGetEntitiesPagesWithCursor() throws {
    let listExpect = expectation(description: "List Entities Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientIds = [randomString(), randomString()]

    createEntities(client: client, patientIds.map { .patient(id: $0) })

    client.dataSync.getEntities(className: patientClass.name, limit: 1) { firstResult in
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

  func testGetEntitiesFollowsCursorToSecondPage() throws {
    let listExpect = expectation(description: "List Entities Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientIds = [randomString(), randomString()]
    let ownEntitiesOnly = "mrn LIKE '\(Constants.prefix)*'"

    createEntities(client: client, patientIds.map { .patient(id: $0) })

    client.dataSync.getEntities(
      className: patientClass.name,
      limit: 1,
      filterFast: ownEntitiesOnly
    ) { [unowned client] firstResult in
      switch firstResult {
      case let .success((firstPage, next)):
        XCTAssertEqual(firstPage.count, 1)
        XCTAssertEqual(next?.hasNext, true)

        // Omitting `limit` lets the service apply its own default, which the second page reports back
        client.dataSync.getEntities(
          className: self.patientClass.name,
          cursor: next?.cursor,
          filterFast: ownEntitiesOnly
        ) { secondResult in
          switch secondResult {
          case let .success((secondPage, secondNext)):
            XCTAssertEqual(secondPage.count, 1)
            XCTAssertEqual(secondNext?.hasNext, false)
            XCTAssertEqual(Set(firstPage.map { $0.id } + secondPage.map { $0.id }), Set(patientIds))
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          listExpect.fulfill()
        }
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

  func testUpdateEntityAppliesTestCopyMoveAndAddOperations() throws {
    let patchExpect = expectation(description: "Patch Entity Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    createEntities(client: client, [.patient(id: patientId)])

    client.dataSync.updateEntity(
      id: patientId,
      operations: [
        .test(path: "/payload/mrn", value: patientId),
        .copy(from: "/payload/dateOfBirth", path: "/payload/fullName"),
        .move(from: "/payload/diagnosis", path: "/payload/mrn"),
        .add(path: "/payload/diagnosis", value: "Hypertension")
      ]
    ) { patchResult in
      switch patchResult {
      case let .success(patchedEntity):
        XCTAssertEqual(patchedEntity.status, "active")
        XCTAssertPayload(
          patchedEntity.payload,
          equals: TestPatientPayload(
            mrn: "Type 2 diabetes",
            fullName: "1985-04-12",
            dateOfBirth: "1985-04-12",
            diagnosis: "Hypertension"
          )
        )
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      patchExpect.fulfill()
    }

    defer {
      removeEntities(client: client, ids: [patientId])
    }

    wait(for: [patchExpect], timeout: 15.0)
  }

  func testUpdateEntityWithFailingTestOperationLeavesEntityUntouched() throws {
    let patchExpect = expectation(description: "Patch Entity Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()
    let payload = TestPatientPayload.standard(mrn: patientId)

    createEntities(client: client, [.patient(id: patientId)])

    client.dataSync.updateEntity(
      id: patientId,
      operations: [
        .test(path: "/payload/mrn", value: "MRN-NEVER-ASSIGNED"),
        .replace(path: "/payload/fullName", value: "Should Not Persist")
      ]
    ) { [unowned client] patchResult in
      switch patchResult {
      case .success:
        XCTFail("Test should fail")
        patchExpect.fulfill()
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError?.reason, .badRequest)

        client.dataSync.getEntity(id: patientId) { fetchResult in
          switch fetchResult {
          case let .success(entity):
            XCTAssertPayload(entity.payload, equals: payload)
            XCTAssertEqual(entity.status, "active")
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          patchExpect.fulfill()
        }
      }
    }

    defer {
      removeEntities(client: client, ids: [patientId])
    }

    wait(for: [patchExpect], timeout: 15.0)
  }

  func testGetEntityUnderDefaultProjectionOmitsRestrictedFields() throws {
    let fetchExpect = expectation(description: "Fetch Entity Expectation")
    let adminClient = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let defaultClient = PubNub(configuration: try dataSyncHealthcareDefaultProjectionConfiguration(from: testsBundle))
    let patientId = randomString()

    // Written under the admin projection, which is the only one able to set every field of `patient`
    createEntities(client: adminClient, [.patient(id: patientId)])

    defaultClient.dataSync.getEntity(id: patientId) { fetchResult in
      switch fetchResult {
      case let .success(entity):
        XCTAssertPayload(
          entity.payload,
          equals: TestPatientPayload(
            mrn: patientId,
            fullName: "Swift ITest Patient"
          )
        )
        // `status` is a system field rather than a projected property, so it stays visible under any projection
        XCTAssertEqual(entity.status, "active")
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchExpect.fulfill()
    }

    defer {
      removeEntities(client: adminClient, ids: [patientId])
    }

    wait(for: [fetchExpect], timeout: 15.0)
  }

  func testUpdateEntityUnderDefaultProjectionPreservesRestrictedFields() throws {
    let patchExpect = expectation(description: "Patch Entity Expectation")
    let adminClient = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let defaultClient = PubNub(configuration: try dataSyncHealthcareDefaultProjectionConfiguration(from: testsBundle))
    let patientId = randomString()

    createEntities(client: adminClient, [.patient(id: patientId)])

    // Patching a field the token can see must not disturb the ones it cannot
    defaultClient.dataSync.updateEntity(
      id: patientId,
      operations: [.replace(path: "/payload/fullName", value: "Swift ITest Patient Renamed")]
    ) { [unowned adminClient] patchResult in
      switch patchResult {
      case let .success(patchedEntity):
        XCTAssertPayload(
          patchedEntity.payload,
          equals: TestPatientPayload(
            mrn: patientId,
            fullName: "Swift ITest Patient Renamed"
          )
        )

        // Only the admin projection can confirm the clinical fields survived the patch above
        adminClient.dataSync.getEntity(id: patientId) { fetchResult in
          switch fetchResult {
          case let .success(entity):
            XCTAssertPayload(
              entity.payload, equals: TestPatientPayload(
                mrn: patientId,
                fullName: "Swift ITest Patient Renamed",
                dateOfBirth: "1985-04-12",
                diagnosis: "Type 2 diabetes"
              )
            )
            XCTAssertEqual(entity.status, "active")
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
      removeEntities(client: adminClient, ids: [patientId])
    }

    wait(for: [patchExpect], timeout: 20.0)
  }

  func testRemoveEntityThenFetchFails() throws {
    let removeExpect = expectation(description: "Remove Entity Expectation")
    let client = PubNub(configuration: try dataSyncHealthcareConfiguration(from: testsBundle))
    let patientId = randomString()

    client.dataSync.createEntity(
      className: patientClass.name,
      classVersion: patientClass.version,
      id: patientId,
      status: "active",
      payload: TestPatientPayload.standard(mrn: "MRN-100006")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.removeEntity(id: patientId) { removeResult in
          switch removeResult {
          case .success:
            client.dataSync.getEntity(id: patientId) { fetchResult in
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
