//
//  DataSyncErrorAPITests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncErrorAPITests: DataSyncAPITestCase {
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

  func test_SetEntity_WhenEtagStale_SurfacesPreconditionFailed() throws {
    let expectation = self.expectation(description: "setEntity stale eTag")
    let sessions = try MockURLSession.mockSession(for: ["datasync_error_412"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.setEntity(
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
}
