//
//  DataSyncAPITests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncAPITests: XCTestCase {
  let createdAt = Date.dataSyncTestDate(from: "2026-08-06T08:58:09.720323Z")
  let updatedAt = Date.dataSyncTestDate(from: "2026-08-06T08:58:10.329598Z")
  let expiresAt = Date.dataSyncTestDate(from: "2027-08-07T00:00:00Z")
}

// MARK: - Entities

extension DataSyncAPITests {
  func test_GetEntities_DecodesItemsAndNextPage() throws {
    let expectation = self.expectation(description: "getEntities")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(entityClass: "patient", limit: 20) { [self] result in
      switch result {
      case let .success((entities, next)):
        XCTAssertEqual(entities.count, 2)

        let first = entities[0]
        XCTAssertEqual(first.id, "hcn-patient-alice")
        XCTAssertEqual(first.className, "patient")
        XCTAssertEqual(first.classLevel, .subKey)
        XCTAssertEqual(first.classVersion, 1)
        XCTAssertEqual(first.createdAt, createdAt)
        XCTAssertEqual(first.updatedAt, updatedAt)
        XCTAssertEqual(first.eTag, "3w5e111uk7djz")
        XCTAssertEqual(first.expiresAt, expiresAt)
        XCTAssertEqual(first.status, "active")
        XCTAssertEqual(first.payload?.codableValue["fullName"]?.stringOptional, "Alice Summers")

        XCTAssertEqual(entities[1].className, "inpatient")
        XCTAssertEqual(entities[1].classLevel, .global)
        XCTAssertEqual(entities[1].classVersion, 2)

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

  func test_GetEntities_WithoutExpiresAt_DecodesNilExpiry() throws {
    let expectation = self.expectation(description: "getEntities TTL-less")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(entityClass: "patient") { result in
      switch result {
      case let .success((entities, _)):
        XCTAssertNil(entities[1].expiresAt)
        XCTAssertNil(entities[1].status)
        XCTAssertNil(entities[1].payload)
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
        XCTAssertEqual(entity.expiresAt, expiresAt)
        XCTAssertEqual(entity.payload?.codableValue["diagnosis"]?.stringOptional, "Type 2 diabetes")
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
      payload: ["mrn": "MRN-100001"]
    ) { result in
      switch result {
      case let .success(entity):
        XCTAssertEqual(entity.id, "hcn-patient-alice")
        XCTAssertEqual(entity.eTag, "3w5e111uk7djz")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_ReplaceEntity_DecodesReplacedEntity() throws {
    let expectation = self.expectation(description: "replaceEntity")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.replaceEntity(
      "hcn-patient-alice",
      entityClassVersion: 1,
      payload: ["mrn": "MRN-100001"],
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

  func test_PatchEntity_DecodesPatchedEntity() throws {
    let expectation = self.expectation(description: "patchEntity")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.patchEntity(
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
}

// MARK: - Users

extension DataSyncAPITests {
  func test_GetUsers_IgnoresEntityClassOnTheWire() throws {
    let expectation = self.expectation(description: "getUsers")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getUsers(limit: 20) { [self] result in
      switch result {
      case let .success((users, next)):
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users[0].id, "alice")
        XCTAssertEqual(users[0].classLevel, .subKey)
        XCTAssertEqual(users[0].classVersion, 1)
        XCTAssertEqual(users[0].createdAt, createdAt)
        XCTAssertEqual(users[0].updatedAt, updatedAt)
        XCTAssertEqual(users[0].status, "active")
        XCTAssertNil(users[0].expiresAt)
        XCTAssertEqual(users[0].payload?.codableValue["name"]?.stringOptional, "Alice Summers")
        XCTAssertEqual(next?.hasNext, false)
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GetUser_DecodesAllFields() throws {
    let expectation = self.expectation(description: "getUser")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getUser("alice") { [self] result in
      switch result {
      case let .success(user):
        XCTAssertEqual(user.id, "alice")
        XCTAssertEqual(user.eTag, "3w5e111uk7djz")
        XCTAssertEqual(user.expiresAt, expiresAt)
        XCTAssertEqual(user.payload?.codableValue["email"]?.stringOptional, "alice@example.com")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_CreateUser_DecodesCreatedUser() throws {
    let expectation = self.expectation(description: "createUser")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.createUser(classVersion: 1, id: "alice", payload: ["name": "Alice Summers"]) { result in
      switch result {
      case let .success(user):
        XCTAssertEqual(user.id, "alice")
        XCTAssertEqual(user.classVersion, 1)
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveUser_SucceedsWithoutBody() throws {
    let expectation = self.expectation(description: "removeUser")
    let sessions = try MockURLSession.mockSession(for: ["datasync_remove_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.removeUser("alice") { result in
      if case let .failure(error) = result {
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Channels

extension DataSyncAPITests {
  func test_GetChannel_IgnoresEntityClassOnTheWire() throws {
    let expectation = self.expectation(description: "getChannel")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getChannel("general") { [self] result in
      switch result {
      case let .success(channel):
        XCTAssertEqual(channel.id, "general")
        XCTAssertEqual(channel.classLevel, .subKey)
        XCTAssertEqual(channel.classVersion, 1)
        XCTAssertEqual(channel.createdAt, createdAt)
        XCTAssertNil(channel.expiresAt)
        XCTAssertEqual(channel.payload?.codableValue["name"]?.stringOptional, "General")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_PatchChannel_DecodesPatchedChannel() throws {
    let expectation = self.expectation(description: "patchChannel")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.patchChannel(
      "general",
      operations: [.replace(path: "/payload/name", value: "General")],
      ifMatchesEtag: "3w5e111uk7djz"
    ) { result in
      switch result {
      case let .success(channel):
        XCTAssertEqual(channel.id, "general")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Memberships

extension DataSyncAPITests {
  func test_GetMemberships_DecodesChannelAndUserIds() throws {
    let expectation = self.expectation(description: "getMemberships")
    let sessions = try MockURLSession.mockSession(for: ["datasync_membership_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getMemberships(channelId: "general", limit: 5) { [self] result in
      switch result {
      case let .success((memberships, next)):
        XCTAssertEqual(memberships.count, 1)
        XCTAssertEqual(memberships[0].id, "general__alice")
        XCTAssertEqual(memberships[0].channelId, "general")
        XCTAssertEqual(memberships[0].userId, "alice")
        XCTAssertEqual(memberships[0].classVersion, 1)
        XCTAssertEqual(memberships[0].createdAt, createdAt)
        XCTAssertEqual(memberships[0].updatedAt, updatedAt)
        XCTAssertEqual(memberships[0].status, "active")
        XCTAssertNil(memberships[0].expiresAt)
        XCTAssertEqual(memberships[0].payload?.codableValue["role"]?.stringOptional, "admin")

        XCTAssertEqual(next?.cursor, "TjQw")
        XCTAssertEqual(next?.hasNext, true)
        XCTAssertEqual(next?.limit, 5)
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_CreateMembership_DecodesCreatedMembership() throws {
    let expectation = self.expectation(description: "createMembership")
    let sessions = try MockURLSession.mockSession(for: ["datasync_membership_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.createMembership(
      channelId: "general",
      userId: "alice",
      classVersion: 1,
      payload: ["role": "admin"]
    ) { result in
      switch result {
      case let .success(membership):
        XCTAssertEqual(membership.channelId, "general")
        XCTAssertEqual(membership.userId, "alice")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveMembership_SucceedsWithoutBody() throws {
    let expectation = self.expectation(description: "removeMembership")
    let sessions = try MockURLSession.mockSession(for: ["datasync_remove_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.removeMembership("general__alice") { result in
      if case let .failure(error) = result {
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Relationships

extension DataSyncAPITests {
  /// Relationship lists carry no `meta`, so there is no page to report
  func test_GetRelationships_WithoutMeta_ReportsNilPage() throws {
    let expectation = self.expectation(description: "getRelationships")
    let sessions = try MockURLSession.mockSession(for: ["datasync_relationship_all_no_meta"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getRelationships(relationshipClass: "Treats", limit: 20) { [self] result in
      switch result {
      case let .success((relationships, next)):
        XCTAssertNil(next)
        XCTAssertEqual(relationships.count, 1)
        XCTAssertEqual(relationships[0].id, "rel-alice-treats-bob")
        XCTAssertEqual(relationships[0].className, "Treats")
        XCTAssertEqual(relationships[0].classVersion, 1)
        XCTAssertEqual(relationships[0].entityAId, "hcn-doctor-alice")
        XCTAssertEqual(relationships[0].entityBId, "hcn-patient-bob")
        XCTAssertEqual(relationships[0].createdAt, createdAt)
        XCTAssertNil(relationships[0].expiresAt)
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GetRelationship_DecodesAllFields() throws {
    let expectation = self.expectation(description: "getRelationship")
    let sessions = try MockURLSession.mockSession(for: ["datasync_relationship_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getRelationship("rel-alice-treats-bob") { [self] result in
      switch result {
      case let .success(relationship):
        XCTAssertEqual(relationship.className, "Treats")
        XCTAssertEqual(relationship.expiresAt, expiresAt)
        XCTAssertEqual(relationship.payload?.codableValue["since"]?.stringOptional, "2026-01-01")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_CreateRelationship_DecodesCreatedRelationship() throws {
    let expectation = self.expectation(description: "createRelationship")
    let sessions = try MockURLSession.mockSession(for: ["datasync_relationship_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.createRelationship(
      relationshipClass: "Treats",
      entityAId: "hcn-doctor-alice",
      entityBId: "hcn-patient-bob",
      relationshipClassVersion: 1
    ) { result in
      switch result {
      case let .success(relationship):
        XCTAssertEqual(relationship.id, "rel-alice-treats-bob")
      case let .failure(error):
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveRelationship_SucceedsWithoutBody() throws {
    let expectation = self.expectation(description: "removeRelationship")
    let sessions = try MockURLSession.mockSession(for: ["datasync_remove_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.removeRelationship("rel-alice-treats-bob") { result in
      if case let .failure(error) = result {
        XCTFail("Request failed with \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Error envelope

extension DataSyncAPITests {
  /// A resource-level failure carries no `path`, which must not prevent the code from surfacing
  func test_CreateEntity_WhenDuplicate_SurfacesConflictWithoutPath() throws {
    let expectation = self.expectation(description: "createEntity conflict")
    let sessions = try MockURLSession.mockSession(for: ["datasync_error_409"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.createEntity(entityClass: "patient", entityClassVersion: 1) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        let pubnubError = try? XCTUnwrap(error.pubNubError)
        XCTAssertEqual(pubnubError?.reason, .conflict)
        XCTAssertTrue(
          pubnubError?.details.contains(where: {
            $0.contains("already exists in this keyset")
          }) ?? false
        )
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  /// A field-level failure carries a JSON Pointer, which must survive into the error details
  func test_GetEntities_WhenLimitInvalid_SurfacesBadRequestWithPath() throws {
    let expectation = self.expectation(description: "getEntities bad request")
    let sessions = try MockURLSession.mockSession(for: ["datasync_error_400"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(entityClass: "patient", limit: 0) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .badRequest)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_ReplaceEntity_WhenEtagStale_SurfacesPreconditionFailed() throws {
    let expectation = self.expectation(description: "replaceEntity stale eTag")
    let sessions = try MockURLSession.mockSession(for: ["datasync_error_412"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.replaceEntity(
      "hcn-patient-alice",
      entityClassVersion: 1,
      ifMatchesEtag: "stale-etag"
    ) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .preconditionFailed)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GetEntity_WhenMissing_SurfacesResourceNotFound() throws {
    let expectation = self.expectation(description: "getEntity not found")
    let sessions = try MockURLSession.mockSession(for: ["datasync_error_404"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntity("missing-entity") { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .resourceNotFound)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_RemoveEntity_WhenMissing_SurfacesResourceNotFound() throws {
    let expectation = self.expectation(description: "removeEntity not found")
    let sessions = try MockURLSession.mockSession(for: ["datasync_error_404"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.removeEntity("missing-entity") { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason, .resourceNotFound)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  /// The v4 envelope decodes to `errorCode` and `path`, which are carried as `ErrorDetail`
  func test_DataSyncErrorPayload_DecodesBothShapes() throws {
    let withPath = try XCTUnwrap(ImportTestResource.testResource("datasync_error_400") as EndpointResource?)
    let withoutPath = try XCTUnwrap(ImportTestResource.testResource("datasync_error_409") as EndpointResource?)

    let fieldLevel = try Constant.jsonDecoder.decode(
      DataSyncErrorPayload.self, from: try withPath.body.jsonDataResult.get()
    )

    XCTAssertEqual(fieldLevel.errors.first?.errorCode, "SYN-0004")
    XCTAssertEqual(fieldLevel.errors.first?.path, "limit")

    let resourceLevel = try Constant.jsonDecoder.decode(
      DataSyncErrorPayload.self, from: try withoutPath.body.jsonDataResult.get()
    )

    XCTAssertEqual(resourceLevel.errors.first?.errorCode, "SYN-0301")
    XCTAssertNil(resourceLevel.errors.first?.path)
  }
}

// MARK: - Validation

extension DataSyncAPITests {
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

  func test_PatchEntity_WithNoOperations_FailsValidation() throws {
    let expectation = self.expectation(description: "patchEntity no operations")
    let pubnub = TestPubNubFactory.make()

    pubnub.dataSync.patchEntity("hcn-patient-alice", operations: []) { result in
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

// MARK: - Sorting

extension DataSyncAPITests {
  private func sortQueryValue(_ session: MockURLSession) throws -> String? {
    let request = try XCTUnwrap(session.tasks.first?.originalRequest)
    let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))

    return components.queryItems?.first { $0.name == "sort" }?.value
  }

  func test_DataSyncSortField_DefaultsToAscending() {
    XCTAssertTrue(PubNub.DataSyncSortField(property: "name").ascending)
  }

  func test_DataSyncSortField_AscendingOmitsDirectionSuffix() {
    XCTAssertEqual(PubNub.DataSyncSortField(property: "name").description, "name")
  }

  func test_DataSyncSortField_DescendingAppendsDirectionSuffix() {
    XCTAssertEqual(PubNub.DataSyncSortField(property: "name", ascending: false).description, "name:desc")
  }

  func test_DataSyncSortFields_WhenEmpty_ProduceNoQueryValue() {
    XCTAssertNil([PubNub.DataSyncSortField]().urlValue)
  }

  func test_DataSyncSortFields_JoinIntoCommaSeparatedQueryValue() {
    let sort = [
      PubNub.DataSyncSortField(property: "name", ascending: false),
      PubNub.DataSyncSortField(property: "type")
    ]

    XCTAssertEqual(sort.urlValue, "name:desc,type")
  }

  func test_GetEntities_WithSortFields_SendsSortQueryItem() throws {
    let expectation = self.expectation(description: "getEntities sorted")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(
      entityClass: "patient",
      sort: [.init(property: "fullName", ascending: false), .init(property: "mrn")]
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try sortQueryValue(sessions.mockSession), "fullName:desc,mrn")
  }

  func test_GetEntities_WithoutSortFields_OmitsSortQueryItem() throws {
    let expectation = self.expectation(description: "getEntities unsorted")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(entityClass: "patient") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertNil(try sortQueryValue(sessions.mockSession))
  }

  func test_GetUsers_WithSortFields_SendsSortQueryItem() throws {
    let expectation = self.expectation(description: "getUsers sorted")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getUsers(sort: [.init(property: "name")]) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try sortQueryValue(sessions.mockSession), "name")
  }

  func test_GetChannels_WithSortFields_SendsSortQueryItem() throws {
    let expectation = self.expectation(description: "getChannels sorted")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getChannels(sort: [.init(property: "name", ascending: false)]) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try sortQueryValue(sessions.mockSession), "name:desc")
  }

  func test_GetMemberships_WithSortFields_SendsSortQueryItem() throws {
    let expectation = self.expectation(description: "getMemberships sorted")
    let sessions = try MockURLSession.mockSession(for: ["datasync_membership_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getMemberships(channelId: "general", sort: [.init(property: "role")]) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try sortQueryValue(sessions.mockSession), "role")
  }

  func test_GetRelationships_WithSortFields_SendsSortQueryItem() throws {
    let expectation = self.expectation(description: "getRelationships sorted")
    let sessions = try MockURLSession.mockSession(for: ["datasync_relationship_all_no_meta"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getRelationships(
      relationshipClass: "attending-physician",
      sort: [.init(property: "since", ascending: false)]
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try sortQueryValue(sessions.mockSession), "since:desc")
  }
}

// MARK: - Helpers

private extension Date {
  /// Parses a service timestamp through the same strategy the SDK decodes responses with
  static func dataSyncTestDate(from string: String) -> Date? {
    try? Constant.jsonDecoder.decode(Date.self, from: Data("\"\(string)\"".utf8))
  }
}
