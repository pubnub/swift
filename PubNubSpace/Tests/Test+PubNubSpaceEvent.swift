//
//  Test+PubNubSpaceEvent.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
