//
//  Set+PubNubTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class SetPubNubTests: XCTestCase {
  func test_AllObjects_WithPopulatedSet_ReturnsArrayOfElements() {
    let set = Set(["one", "two", "three"])

    XCTAssertEqual(set.allObjects, Array(set))
  }
}
