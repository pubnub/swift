//
//  SmokeTest+PubNubSpace.swift
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

class PubNubSpaceInterfaceITests: XCTestCase {
  let testSpace = PubNubSpace(
    id: "TestSpaceId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    spaceDescription: "TestDescription",
    custom: SpaceCustom(value: "TestValue")
  )

  let testUpdatedSpace = PubNubSpace(
    id: "TestSpaceId",
    name: "UpdatedName",
    type: "UpdatedType",
    status: "UpdatedStatus",
    spaceDescription: "UpdatedDescription",
    custom: SpaceCustom(value: "UpdatedValue")
  )
  var createdSpace: PubNubSpace?
  var updatedSpace: PubNubSpace?

  let config = PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "itest-swift-spaceId"
  )

  func testSpace_Smoke() throws {
    let expectation = XCTestExpectation(description: "Smoke Test Space APIs")

    let createdEventExpectation = XCTestExpectation(description: "Created Event Listener")
    let updatedEventExpectation = XCTestExpectation(description: "Updated Event Listener")
    let removedEventExpectation = XCTestExpectation(description: "Removed Event Listener")
    let pubnub = PubNub(configuration: config)

    pubnub.subscribe(to: [testSpace.id])

    // Smoke Test Events
    let listener = eventListener_Spaces(
      createdEventExpectation,
      updatedEventExpectation,
      removedEventExpectation
    )

    pubnub.add(listener)

    // Validate Outputs
    pubnub.createSpace(
      spaceId: testSpace.id,
      name: testSpace.name,
      type: testSpace.type,
      status: testSpace.status,
      description: testSpace.spaceDescription,
      custom: testSpace.custom
    ) { [unowned self] result in
      do {
        switch result {
        case let .success(space):
          // Sync Server Set Fields
          createdSpace = testSpace
          createdSpace?.updated = space.updated
          createdSpace?.eTag = space.eTag

          XCTAssertEqual(space, createdSpace)

          self.fetchSpaces_Smoke(pubnub, space, expectation)

        case let .failure(error):
          XCTFail("Failed due to error \(error)")
          expectation.fulfill()
        }
      }
    }

    wait(
      for: [
        createdEventExpectation,
        updatedEventExpectation,
        expectation,
        removedEventExpectation
      ],
      timeout: 10.0
    )
  }

  func eventListener_Spaces(
    _ createdEventExpectation: XCTestExpectation,
    _ updatedEventExpectation: XCTestExpectation,
    _ removedEventExpectation: XCTestExpectation
  ) -> PubNubSpaceListener {
    let listener = PubNubSpaceListener()

    listener.didReceiveSpaceEvent = { [unowned self] event in
      switch event {
      case let .spaceUpdated(patcher):
        if let updatedSpace = updatedSpace {
          XCTAssertEqual(updatedSpace, createdSpace?.apply(patcher))
          updatedEventExpectation.fulfill()
        } else {
          XCTAssertEqual(testSpace.apply(patcher), createdSpace)
          createdEventExpectation.fulfill()
        }
      case let .spaceRemoved(space):
        XCTAssertEqual(space.id, testSpace.id)
        removedEventExpectation.fulfill()
      }
    }

    return listener
  }

  func fetchSpaces_Smoke(
    _ pubnub: PubNub,
    _ testSpace: PubNubSpace,
    _ expectation: XCTestExpectation
  ) {
    pubnub.fetchSpaces { [unowned self] result in
      switch result {
      case let .success((spaces, next)):
        XCTAssertTrue(spaces.contains(testSpace))
        XCTAssertNotNil(next)

        updateSpace_Smoke(pubnub, expectation)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }

  func updateSpace_Smoke(
    _ pubnub: PubNub,
    _ expectation: XCTestExpectation
  ) {
    pubnub.updateSpace(
      spaceId: testUpdatedSpace.id,
      name: testUpdatedSpace.name,
      type: testUpdatedSpace.type,
      status: testUpdatedSpace.status,
      description: testUpdatedSpace.spaceDescription,
      custom: testUpdatedSpace.custom
    ) { [unowned self] result in
      switch result {
      case let .success(space):
        // Sync Server Set Fields
        updatedSpace = testUpdatedSpace
        updatedSpace?.updated = space.updated
        updatedSpace?.eTag = space.eTag

        XCTAssertEqual(space, updatedSpace)

        self.fetchSpace_Smoke(pubnub, space, expectation)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }

  func fetchSpace_Smoke(
    _ pubnub: PubNub,
    _ fetchedSpace: PubNubSpace,
    _ expectation: XCTestExpectation
  ) {
    pubnub.fetchSpace(spaceId: fetchedSpace.id) { [unowned self] result in
      switch result {
      case let .success(space):
        XCTAssertEqual(space, fetchedSpace)

        self.removeSpace_Smoke(pubnub, expectation)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }

  func removeSpace_Smoke(
    _ pubnub: PubNub,
    _ expectation: XCTestExpectation
  ) {
    pubnub.removeSpace(spaceId: testSpace.id) { [unowned self] result in
      switch result {
      case .success:
        pubnub.fetchSpace(spaceId: testSpace.id) { result in
          switch result {
          case .success:
            XCTFail("Space was not successfully removed")
          case let .failure(error):
            XCTAssertEqual(error.pubNubError?.reason, .resourceNotFound)
            expectation.fulfill()
          }
        }
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }
}
