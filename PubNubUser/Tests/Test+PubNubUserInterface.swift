//
//  Test+PubNubUserInterface.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
@testable import PubNubUser

import XCTest

class PubNubUserInterfaceTests: XCTestCase {
  let testUser = PubNubUser(
    id: "TestUserId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    externalId: "TestExternalID",
    profileURL: URL(string: "http://example.com"),
    email: "TestEmail",
    custom: nil,
    updated: Date.distantPast,
    eTag: "TestETag"
  )

  var mockSession = MockSession()

  lazy var pubnub = PubNub(
    configuration: .init(publishKey: "mock-pub", subscribeKey: "mock-sub", userId: "TestUserId"),
    session: mockSession
  )

  let singleValueJSON = """
  {
  "status": 200,
  "data": {
      "id": "TestUserId",
      "name": "TestName",
      "type": "TestType",
      "status": "TestStatus",
      "externalId": "TestExternalID",
      "profileUrl": "http://example.com",
      "email": "TestEmail",
      "custom": null,
      "updated": "0001-01-01T00:00:00.000Z",
      "eTag": "TestETag"
    }
  }
  """

  let multiValueJSON = """
  {
  "status": 200,
  "data": [{
      "id": "TestUserId",
      "name": "TestName",
      "type": "TestType",
      "status": "TestStatus",
      "externalId": "TestExternalID",
      "profileUrl": "http://example.com",
      "email": "TestEmail",
      "custom": null,
      "updated": "0001-01-01T00:00:00.000Z",
      "eTag": "TestETag"
    }]
  }
  """

  func testUserSort_RawValue() {
    XCTAssertEqual(PubNub.UserSort.id(ascending: true).rawValue, "id")
    XCTAssertEqual(PubNub.UserSort.name(ascending: true).rawValue, "name")
    XCTAssertEqual(PubNub.UserSort.type(ascending: true).rawValue, "type")
    XCTAssertEqual(PubNub.UserSort.status(ascending: true).rawValue, "status")
    XCTAssertEqual(PubNub.UserSort.updated(ascending: true).rawValue, "updated")
  }

  func testUserSort_Ascending() {
    XCTAssertEqual(PubNub.UserSort.id(ascending: true).ascending, true)
    XCTAssertEqual(PubNub.UserSort.name(ascending: true).ascending, true)
    XCTAssertEqual(PubNub.UserSort.type(ascending: false).ascending, false)
    XCTAssertEqual(PubNub.UserSort.status(ascending: false).ascending, false)
    XCTAssertEqual(PubNub.UserSort.updated(ascending: true).ascending, true)
  }

  func testUserSort_RouterParameter_Ascending() {
    XCTAssertEqual(
      PubNub.UserSort.id(ascending: true).routerParameter, "id"
    )
  }

  func testUserSort_RouterParameter_Descending() {
    XCTAssertEqual(
      PubNub.UserSort.type(ascending: false).routerParameter, "type:desc"
    )
  }

  func testUser_FetchUsers() {
    let expectation = XCTestExpectation(description: "Fetch Users API")

    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.all(
      customFields: true,
      totalCount: true,
      filter: nil,
      sort: ["id"],
      limit: 100,
      start: nil,
      end: nil
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }

    // Validate Outputs
    pubnub.fetchUsers(sort: [.id(ascending: true)]) { [weak self] result in
      switch result {
      case let .success((users, next)):
        XCTAssertEqual(users.first, self?.testUser)
        XCTAssertEqual(next as? PubNub.Page, PubNub.Page())
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUser_FetchUser_ConfigUserId() {
    let expectation = XCTestExpectation(description: "Fetch User API")

    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.fetch(
      metadataId: pubnub.configuration.userId,
      customFields: true
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      .success(.init(data: singleValueJSON.data(using: .utf8)))
    }

    // Validate Outputs
    pubnub.fetchUser { [weak self] result in
      switch result {
      case let .success(user):
        XCTAssertEqual(user, self?.testUser)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUser_CreateUser() {
    let expectation = XCTestExpectation(description: "Fetch User API")

    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.set(
      metadata: PubNubUUIDMetadataBase(
        metadataId: pubnub.configuration.userId,
        name: testUser.name,
        type: testUser.type,
        status: testUser.status,
        externalId: testUser.externalId,
        profileURL: testUser.profileURL?.absoluteString,
        email: testUser.email,
        custom: testUser.custom?.flatJSON,
        updated: nil,
        eTag: nil
      ),
      customFields: true
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in

      .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }

    // Validate Outputs
    pubnub.createUser(
      name: testUser.name,
      type: testUser.type,
      status: testUser.status,
      externalId: testUser.externalId,
      profileUrl: testUser.profileURL,
      email: testUser.email,
      custom: testUser.custom
    ) { [weak self] result in
      switch result {
      case let .success(user):
        XCTAssertEqual(user, self?.testUser)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUser_UpdateUser() {
    let expectation = XCTestExpectation(description: "Fetch User API")

    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.set(
      metadata: PubNubUUIDMetadataBase(
        metadataId: pubnub.configuration.userId,
        name: testUser.name,
        type: testUser.type,
        status: testUser.status,
        externalId: testUser.externalId,
        profileURL: testUser.profileURL?.absoluteString,
        email: testUser.email,
        custom: testUser.custom?.flatJSON,
        updated: nil,
        eTag: nil
      ),
      customFields: true
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in

      .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }

    // Validate Outputs
    pubnub.updateUser(
      name: testUser.name,
      type: testUser.type,
      status: testUser.status,
      externalId: testUser.externalId,
      profileUrl: testUser.profileURL,
      email: testUser.email,
      custom: testUser.custom
    ) { [weak self] result in
      switch result {
      case let .success(user):
        XCTAssertEqual(user, self?.testUser)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUser_RemoveUser() {
    let expectation = XCTestExpectation(description: "Fetch User API")

    let testRouterEndpoint = ObjectsUUIDRouter.Endpoint.remove(
      metadataId: pubnub.configuration.uuid
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsUUIDRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }

    // Validate Outputs
    pubnub.removeUser { result in
      switch result {
      case .success:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
