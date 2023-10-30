//
//  Test+PubNubSpaceInterface.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
@testable import PubNubSpace

import XCTest

class PubNubSpaceInterfaceTests: XCTestCase {
  let testSpace = PubNubSpace(
    id: "TestSpaceId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    spaceDescription: "TestDescription",
    custom: nil,
    updated: Date.distantPast,
    eTag: "TestETag"
  )

  var mockSession = MockSession()

  lazy var pubnub = PubNub(
    configuration: .init(publishKey: "mock-pub", subscribeKey: "mock-sub", userId: "TestSpaceId"),
    session: mockSession
  )

  let singleValueJSON = """
  {
  "status": 200,
  "data": {
      "id": "TestSpaceId",
      "name": "TestName",
      "type": "TestType",
      "status": "TestStatus",
      "description": "TestDescription",
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
      "id": "TestSpaceId",
      "name": "TestName",
      "type": "TestType",
      "status": "TestStatus",
      "description": "TestDescription",
      "custom": null,
      "updated": "0001-01-01T00:00:00.000Z",
      "eTag": "TestETag"
    }]
  }
  """

  func testSpaceSort_RawValue() {
    XCTAssertEqual(PubNub.SpaceSort.id(ascending: true).rawValue, "id")
    XCTAssertEqual(PubNub.SpaceSort.name(ascending: true).rawValue, "name")
    XCTAssertEqual(PubNub.SpaceSort.type(ascending: true).rawValue, "type")
    XCTAssertEqual(PubNub.SpaceSort.status(ascending: true).rawValue, "status")
    XCTAssertEqual(PubNub.SpaceSort.updated(ascending: true).rawValue, "updated")
  }

  func testSpaceSort_Ascending() {
    XCTAssertEqual(PubNub.SpaceSort.id(ascending: true).ascending, true)
    XCTAssertEqual(PubNub.SpaceSort.name(ascending: true).ascending, true)
    XCTAssertEqual(PubNub.SpaceSort.type(ascending: false).ascending, false)
    XCTAssertEqual(PubNub.SpaceSort.status(ascending: false).ascending, false)
    XCTAssertEqual(PubNub.SpaceSort.updated(ascending: true).ascending, true)
  }

  func testSpaceSort_RouterParameter_Ascending() {
    XCTAssertEqual(
      PubNub.SpaceSort.id(ascending: true).routerParameter, "id"
    )
  }

  func testSpaceSort_RouterParameter_Descending() {
    XCTAssertEqual(
      PubNub.SpaceSort.type(ascending: false).routerParameter, "type:desc"
    )
  }

  func testSpace_FetchSpaces() {
    let expectation = XCTestExpectation(description: "Fetch Spaces API")

    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.all(
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
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      .success(.init(
        data: multiValueJSON.data(using: .utf8)
      ))
    }

    // Validate Outputs
    pubnub.fetchSpaces(sort: [.id(ascending: true)]) { [weak self] result in
      switch result {
      case let .success((spaces, next)):
        XCTAssertEqual(spaces.first, self?.testSpace)
        XCTAssertEqual(next as? PubNub.Page, PubNub.Page())
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testSpace_FetchSpace_ConfigSpaceId() {
    let expectation = XCTestExpectation(description: "Fetch Space API")

    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.fetch(
      metadataId: testSpace.id,
      customFields: true
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      .success(.init(data: singleValueJSON.data(using: .utf8)))
    }

    // Validate Outputs
    pubnub.fetchSpace(spaceId: testSpace.id) { [weak self] result in
      switch result {
      case let .success(space):
        XCTAssertEqual(space, self?.testSpace)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testSpace_CreateSpace() {
    let expectation = XCTestExpectation(description: "Fetch Space API")

    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.set(
      metadata: PubNubChannelMetadataBase(
        metadataId: testSpace.id,
        name: testSpace.name,
        type: testSpace.type,
        status: testSpace.status,
        channelDescription: testSpace.spaceDescription,
        custom: testSpace.custom?.flatJSON,
        updated: nil,
        eTag: nil
      ),
      customFields: true
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in

      .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }

    // Validate Outputs
    pubnub.createSpace(
      spaceId: testSpace.id,
      name: testSpace.name,
      type: testSpace.type,
      status: testSpace.status,
      description: testSpace.spaceDescription,
      custom: testSpace.custom
    ) { [weak self] result in
      switch result {
      case let .success(space):
        XCTAssertEqual(space, self?.testSpace)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testSpace_UpdateSpace() {
    let expectation = XCTestExpectation(description: "Fetch Space API")

    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.set(
      metadata: PubNubChannelMetadataBase(
        metadataId: testSpace.id,
        name: testSpace.name,
        type: testSpace.type,
        status: testSpace.status,
        channelDescription: testSpace.spaceDescription,
        custom: testSpace.custom?.flatJSON,
        updated: nil,
        eTag: nil
      ),
      customFields: true
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in

      .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }

    // Validate Outputs
    pubnub.updateSpace(
      spaceId: testSpace.id,
      name: testSpace.name,
      type: testSpace.type,
      status: testSpace.status,
      description: testSpace.spaceDescription,
      custom: testSpace.custom
    ) { [weak self] result in
      switch result {
      case let .success(space):
        XCTAssertEqual(space, self?.testSpace)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testSpace_RemoveSpace() {
    let expectation = XCTestExpectation(description: "Fetch Space API")

    let testRouterEndpoint = ObjectsChannelRouter.Endpoint.remove(
      metadataId: pubnub.configuration.uuid
    )

    // Validate Inputs
    mockSession.validateRouter = { router in
      XCTAssertEqual(testRouterEndpoint, (router as? ObjectsChannelRouter)?.endpoint)
    }

    // Provide Output
    mockSession.provideResponse = { [unowned self] in
      .success(.init(
        data: singleValueJSON.data(using: .utf8)
      ))
    }

    // Validate Outputs
    pubnub.removeSpace(spaceId: testSpace.id) { result in
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
