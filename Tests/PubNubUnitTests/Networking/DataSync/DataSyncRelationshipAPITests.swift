//
//  DataSyncRelationshipAPITests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncRelationshipAPITests: DataSyncAPITestCase {
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
        XCTAssertPayload(relationship.payload, equals: RelationshipPayload(since: "2026-01-01"))
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
