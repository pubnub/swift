//
//  Set+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class SetPubNubTests: XCTestCase {
  func testAllObjects() {
    let set = Set(["one", "two", "three"])

    XCTAssertEqual(set.allObjects, Array(set))
  }
}
