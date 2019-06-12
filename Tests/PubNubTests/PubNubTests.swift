//
//  PubNubTests.swift
//  PubNubTests
//
//  Created by Craig Lane on 6/12/19.
//  Copyright © 2019 PubNub. All rights reserved.
//

@testable import PubNub
import XCTest

final class PubNubTests: XCTestCase {
  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    XCTAssertEqual(PubNub().text, "Hello, World!")
  }

  static var allTests = [
    ("testExample", testExample)
  ]
}
