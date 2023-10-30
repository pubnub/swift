//
//  EventStreamTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

class EventStreamTests: XCTestCase {
  struct NewStream: EventStreamReceiver, Hashable {
    var uuid = UUID()
  }

  func testDefaultProtocol() {
    let newstream = NewStream()
    XCTAssertEqual(newstream.queue, .main)

    let otherStream = NewStream(uuid: newstream.uuid)
    XCTAssertEqual(newstream.hashValue, otherStream.hashValue)
  }

  func testListenerToken_Fire_Deinit() {
    let expectation = self.expectation(description: "Listener Token")

    DispatchQueue.main.async {
      let token = ListenerToken {
        expectation.fulfill()
      }

      XCTAssertEqual(token.description, "ListenerToken: \(token.tokenId)")
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testListenerToken_Fire_Cancel() {
    let expectation = self.expectation(description: "Listener Token")

    let token = ListenerToken {
      expectation.fulfill()
    }

    token.cancel()

    XCTAssertEqual(token.isCancelled, true)

    wait(for: [expectation], timeout: 1.0)
  }
}
