//
//  XCTAssertPayload.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

func XCTAssertPayload<T: JSONCodable & Equatable>(
  _ payload: JSONCodable?,
  equals expected: T,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  let decoded = try? payload?.decode(T.self)

  XCTAssertEqual(decoded, expected, file: file, line: line)
}
