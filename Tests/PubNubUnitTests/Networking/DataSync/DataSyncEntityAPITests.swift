//
//  DataSyncEntityAPITests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncEntityAPITests: DataSyncAPITestCase {
  func test_GetEntities_DecodesItemsAndNextPage() throws {
    let expectation = self.expectation(description: "getEntities")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(entityClass: "patient", limit: 20) { result in
      switch result {
      case let .success((entities, next)):
        XCTAssertEqual(entities.count, 2)

        let first = entities[0]
        XCTAssertEqual(first.id, "hcn-patient-alice")
        XCTAssertEqual(first.className, "patient")
        XCTAssertEqual(first.classLevel, .subKey)
        XCTAssertEqual(first.classVersion, 1)
        XCTAssertPayload(first.payload, equals: PatientPayload(mrn: "MRN-100001", fullName: "Alice Summers"))

        let second = entities[1]
        XCTAssertEqual(second.id, "hcn-patient-bob")
        XCTAssertEqual(second.className, "inpatient")
        XCTAssertEqual(second.classLevel, .global)
        XCTAssertEqual(second.classVersion, 2)
        XCTAssertPayload(second.payload, equals: EmptyPayload())

        XCTAssertEqual(next?.cursor, "TjIw")
        XCTAssertEqual(next?.hasNext, true)
        XCTAssertEqual(next?.limit, 20)
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GetEntities_WithoutStatus_DecodesNilStatusAndEmptyPayload() throws {
    let expectation = self.expectation(description: "getEntities without status")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(entityClass: "patient") { result in
      switch result {
      case let .success((entities, _)):
        let second = entities[1]
        XCTAssertNil(second.status)
        XCTAssertPayload(second.payload, equals: EmptyPayload())
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GetEntities_OnLastPage_ReportsNoNext() throws {
    let expectation = self.expectation(description: "getEntities last page")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_last_page"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(entityClass: "patient", limit: 20) { result in
      switch result {
      case let .success((_, next)):
        XCTAssertNil(next?.cursor)
        XCTAssertEqual(next?.hasNext, false)
        XCTAssertEqual(next?.limit, 20)
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GetEntity_DecodesAllFields() throws {
    let expectation = self.expectation(description: "getEntity")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntity("hcn-patient-alice") { [self] result in
      switch result {
      case let .success(entity):
        XCTAssertEqual(entity.id, "hcn-patient-alice")
        XCTAssertEqual(entity.className, "patient")
        XCTAssertEqual(entity.classLevel, .subKey)
        XCTAssertEqual(entity.classVersion, 1)
        XCTAssertEqual(entity.createdAt, createdAt)
        XCTAssertEqual(entity.updatedAt, updatedAt)
        XCTAssertEqual(entity.eTag, "3w5e111uk7djz")
        XCTAssertEqual(entity.expiresAt, expiresAt)
        XCTAssertEqual(entity.status, "active")
        XCTAssertPayload(
          entity.payload,
          equals: PatientPayload(
            mrn: "MRN-100001",
            fullName: "Alice Summers",
            diagnosis: "Type 2 diabetes",
            dateOfBirth: "1985-04-12"
          )
        )
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_CreateEntity_DecodesCreatedEntity() throws {
    let expectation = self.expectation(description: "createEntity")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.createEntity(
      entityClass: "patient",
      entityClassVersion: 1,
      id: "hcn-patient-alice",
      payload: PatientPayload(mrn: "MRN-100001")
    ) { result in
      switch result {
      case let .success(entity):
        XCTAssertEqual(entity.id, "hcn-patient-alice")
        XCTAssertEqual(entity.className, "patient")
        XCTAssertEqual(entity.classVersion, 1)
        XCTAssertEqual(entity.eTag, "3w5e111uk7djz")
        XCTAssertEqual(entity.status, "active")
        XCTAssertPayload(
          entity.payload,
          equals: PatientPayload(
            mrn: "MRN-100001",
            fullName: "Alice Summers",
            diagnosis: "Type 2 diabetes",
            dateOfBirth: "1985-04-12"
          )
        )
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_CreateEntity_WithEntityClassLevel_SendsItInBody() throws {
    let expectation = self.expectation(description: "createEntity class level")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.createEntity(
      entityClass: "patient",
      entityClassVersion: 1,
      entityClassLevel: .subKey,
      id: "hcn-patient-alice"
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    let body = try requestBody(sessions.mockSession)

    XCTAssertEqual(body["entityClass"]?.stringOptional, "patient")
    XCTAssertEqual(body["entityClassLevel"]?.stringOptional, "SubKey")
  }

  func test_SetEntity_DecodesEntity() throws {
    let expectation = self.expectation(description: "setEntity")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.setEntity(
      "hcn-patient-alice",
      entityClassVersion: 1,
      payload: PatientPayload(mrn: "MRN-100001"),
      ifMatchesEtag: "3w5e111uk7djz"
    ) { result in
      switch result {
      case let .success(entity):
        XCTAssertEqual(entity.id, "hcn-patient-alice")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_UpdateEntity_DecodesUpdatedEntity() throws {
    let expectation = self.expectation(description: "updateEntity")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.updateEntity(
      "hcn-patient-alice",
      operations: [.replace(path: "/payload/diagnosis", value: "Type 2 diabetes")]
    ) { result in
      switch result {
      case let .success(entity):
        XCTAssertEqual(entity.id, "hcn-patient-alice")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveEntity_SucceedsWithoutBody() throws {
    let expectation = self.expectation(description: "removeEntity")
    let sessions = try MockURLSession.mockSession(for: ["datasync_remove_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.removeEntity("hcn-patient-alice", ifMatchesEtag: "3w5e111uk7djz") { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GetEntities_WithEmptyClass_FailsValidation() throws {
    let expectation = self.expectation(description: "getEntities empty class")
    let pubnub = TestPubNubFactory.make()

    pubnub.dataSync.getEntities(entityClass: "") { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .missingRequiredParameter)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_UpdateEntity_WithNoOperations_FailsValidation() throws {
    let expectation = self.expectation(description: "updateEntity no operations")
    let pubnub = TestPubNubFactory.make()

    pubnub.dataSync.updateEntity("hcn-patient-alice", operations: []) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .missingRequiredParameter)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
