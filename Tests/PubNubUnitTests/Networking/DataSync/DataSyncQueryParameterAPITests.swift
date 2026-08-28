//
//  DataSyncQueryParameterAPITests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncQueryParameterAPITests: DataSyncAPITestCase {
  func test_GetEntities_WithListQueryItems_SendsExpectedQueryItems() throws {
    let expectation = self.expectation(description: "getEntities query items")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(
      className: "patient",
      classVersion: 2,
      classLevel: .account,
      cursor: "TjIw",
      limit: 25
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class"), "patient")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class_version"), "2")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class_level"), "Account")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "cursor"), "TjIw")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "limit"), "25")
  }

  func test_GetUsers_WithListQueryItems_SendsExpectedQueryItems() throws {
    let expectation = self.expectation(description: "getUsers query items")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getUsers(classVersion: 2, cursor: "TjIw", limit: 25) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertNil(try queryValue(sessions.mockSession, named: "entity_class"))
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class_version"), "2")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "cursor"), "TjIw")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "limit"), "25")
  }

  func test_GetUsers_WithClassNameAndLevel_SendsExpectedQueryItems() throws {
    let expectation = self.expectation(description: "getUsers class query items")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getUsers(className: "Admin", classVersion: 2, classLevel: .subKey) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class"), "Admin")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class_version"), "2")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class_level"), "SubKey")
  }

  func test_GetChannels_WithListQueryItems_SendsExpectedQueryItems() throws {
    let expectation = self.expectation(description: "getChannels query items")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getChannels(classVersion: 2, cursor: "TjIw", limit: 25) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertNil(try queryValue(sessions.mockSession, named: "entity_class"))
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class_version"), "2")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "cursor"), "TjIw")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "limit"), "25")
  }

  func test_GetChannels_WithClassNameAndLevel_SendsExpectedQueryItems() throws {
    let expectation = self.expectation(description: "getChannels class query items")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getChannels(className: "PrivateChannel", classVersion: 2, classLevel: .subKey) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class"), "PrivateChannel")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class_version"), "2")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_class_level"), "SubKey")
  }

  func test_GetMemberships_WithListQueryItems_SendsExpectedQueryItems() throws {
    let expectation = self.expectation(description: "getMemberships query items")
    let sessions = try MockURLSession.mockSession(for: ["datasync_membership_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getMemberships(
      channelId: "general",
      userId: "alice",
      classVersion: 2,
      cursor: "TjIw",
      limit: 25
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "channel_id"), "general")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "user_id"), "alice")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "relationship_class_version"), "2")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "cursor"), "TjIw")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "limit"), "25")
  }

  func test_GetRelationships_WithListQueryItems_SendsExpectedQueryItems() throws {
    let expectation = self.expectation(description: "getRelationships query items")
    let sessions = try MockURLSession.mockSession(for: ["datasync_relationship_all_no_meta"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getRelationships(
      className: "attending-physician",
      classVersion: 2,
      entityAId: "hcn-doctor-alice",
      entityBId: "hcn-patient-bob",
      cursor: "TjIw",
      limit: 25
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "relationship_class"), "attending-physician")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_a_id"), "hcn-doctor-alice")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "entity_b_id"), "hcn-patient-bob")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "relationship_class_version"), "2")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "cursor"), "TjIw")
    XCTAssertEqual(try queryValue(sessions.mockSession, named: "limit"), "25")
  }

  func test_GetEntities_WithFilter_SendsFilterQueryItem() throws {
    let expectation = self.expectation(description: "getEntities filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(className: "patient", filter: "status=='active'") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try filterQueryValue(sessions.mockSession), "status=='active'")
  }

  func test_GetEntities_WithAdvancedFilter_SendsAdvancedFilterQueryItem() throws {
    let expectation = self.expectation(description: "getEntities advanced filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(className: "patient", filterAdvanced: "a AND b") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try advancedFilterQueryValue(sessions.mockSession), "a AND b")
  }

  func test_GetEntities_WithoutFilter_OmitsFilterQueryItems() throws {
    let expectation = self.expectation(description: "getEntities unfiltered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_entity_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getEntities(className: "patient") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertNil(try filterQueryValue(sessions.mockSession))
    XCTAssertNil(try advancedFilterQueryValue(sessions.mockSession))
  }

  func test_GetUsers_WithFilter_SendsFilterQueryItem() throws {
    let expectation = self.expectation(description: "getUsers filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getUsers(filter: "name=='Alice'") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try filterQueryValue(sessions.mockSession), "name=='Alice'")
  }

  func test_GetUsers_WithAdvancedFilter_SendsAdvancedFilterQueryItem() throws {
    let expectation = self.expectation(description: "getUsers advanced filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_user_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getUsers(filterAdvanced: "a AND b") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try advancedFilterQueryValue(sessions.mockSession), "a AND b")
  }

  func test_GetChannels_WithFilter_SendsFilterQueryItem() throws {
    let expectation = self.expectation(description: "getChannels filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getChannels(filter: "name=='general'") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try filterQueryValue(sessions.mockSession), "name=='general'")
  }

  func test_GetChannels_WithAdvancedFilter_SendsAdvancedFilterQueryItem() throws {
    let expectation = self.expectation(description: "getChannels advanced filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_channel_fetch_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getChannels(filterAdvanced: "a AND b") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try advancedFilterQueryValue(sessions.mockSession), "a AND b")
  }

  func test_GetMemberships_WithFilter_SendsFilterQueryItem() throws {
    let expectation = self.expectation(description: "getMemberships filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_membership_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getMemberships(channelId: "general", filter: "role=='admin'") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try filterQueryValue(sessions.mockSession), "role=='admin'")
  }

  func test_GetMemberships_WithAdvancedFilter_SendsAdvancedFilterQueryItem() throws {
    let expectation = self.expectation(description: "getMemberships advanced filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_membership_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getMemberships(channelId: "general", filterAdvanced: "a AND b") { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try advancedFilterQueryValue(sessions.mockSession), "a AND b")
  }

  func test_GetRelationships_WithFilter_SendsFilterQueryItem() throws {
    let expectation = self.expectation(description: "getRelationships filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_relationship_all_no_meta"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getRelationships(
      className: "attending-physician",
      filter: "status=='active'"
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try filterQueryValue(sessions.mockSession), "status=='active'")
  }

  func test_GetRelationships_WithAdvancedFilter_SendsAdvancedFilterQueryItem() throws {
    let expectation = self.expectation(description: "getRelationships advanced filtered")
    let sessions = try MockURLSession.mockSession(for: ["datasync_relationship_all_no_meta"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.dataSync.getRelationships(
      className: "attending-physician",
      filterAdvanced: "a AND b"
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try advancedFilterQueryValue(sessions.mockSession), "a AND b")
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
      className: "patient",
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

    pubnub.dataSync.getEntities(className: "patient") { _ in
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
      className: "attending-physician",
      sort: [.init(property: "since", ascending: false)]
    ) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(try sortQueryValue(sessions.mockSession), "since:desc")
  }
}
