//
//  Test+PubNubSpaceEvent.swift
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

class PubNubSpaceEventTests: XCTestCase {
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

  var listener = PubNubSpaceListener()

  func testSpaceListener_Emit_UpdateEvent() {
    let expectation = XCTestExpectation(description: "Space Update Event")
    expectation.expectedFulfillmentCount = 2

    let patchedSpace = PubNubSpace(
      id: "TestSpaceId",
      name: "NewName",
      type: testSpace.type,
      status: testSpace.status,
      spaceDescription: "TestDescription",
      custom: testSpace.custom,
      updated: Date.distantFuture,
      eTag: "NewETag"
    )

    let entityEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .updated,
      type: .space,
      data: [
        "id": patchedSpace.id,
        "name": patchedSpace.name,
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": patchedSpace.eTag
      ]
    )

    let malformedEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .updated,
      type: .space,
      data: AnyJSON("")
    )

    listener.didReceiveSpaceEvents = { [unowned self] events in
      for event in events {
        switch event {
        case let .spaceUpdated(patch):
          XCTAssertEqual(patchedSpace, self.testSpace.apply(patch))
        case .spaceRemoved:
          XCTFail("Space Removed Event should not fire")
        }
      }
      expectation.fulfill()
    }

    listener.didReceiveSpaceEvent = { [unowned self] event in
      switch event {
      case let .spaceUpdated(patch):
        XCTAssertEqual(patchedSpace, self.testSpace.apply(patch))
      case .spaceRemoved:
        XCTFail("Space Removed Event should not fire")
      }
      expectation.fulfill()
    }

    listener.emit(entity: [malformedEvent, entityEvent])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSpaceListener_Emit_RemoveEvent() {
    let expectation = XCTestExpectation(description: "Space Update Event")
    expectation.expectedFulfillmentCount = 2

    let entityEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .removed,
      type: .space,
      data: [
        "id": testSpace.id
      ]
    )

    let malformedEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .removed,
      type: .space,
      data: AnyJSON("")
    )

    listener.didReceiveSpaceEvents = { [unowned self] events in
      for event in events {
        switch event {
        case let .spaceRemoved(space):
          XCTAssertEqual(self.testSpace.id, space.id)
        case .spaceUpdated:
          XCTFail("Space Updated Event should not fire")
        }
      }
      expectation.fulfill()
    }

    listener.didReceiveSpaceEvent = { [unowned self] event in
      switch event {
      case let .spaceRemoved(space):
        XCTAssertEqual(self.testSpace.id, space.id)
      case .spaceUpdated:
        XCTFail("Space Updated Event should not fire")
      }
      expectation.fulfill()
    }

    listener.emit(entity: [malformedEvent, entityEvent])

    wait(for: [expectation], timeout: 1.0)
  }
}
