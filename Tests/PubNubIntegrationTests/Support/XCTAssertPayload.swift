//
//  XCTAssertPayload.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

/// Asserts that `payload` matches `expected` exactly, including its set of keys.
func XCTAssertPayload<T: JSONCodable>(
  _ payload: JSONCodable?,
  equals expected: T,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  guard let actualJSON = normalizedJSON(payload) else {
    XCTFail("Received payload could not be encoded as JSON", file: file, line: line)
    return
  }
  guard let expectedJSON = normalizedJSON(expected) else {
    XCTFail("Expected payload could not be encoded as JSON", file: file, line: line)
    return
  }

  XCTAssertEqual(actualJSON, expectedJSON, file: file, line: line)
}

/// Encodes `payload` and decodes it back into `AnyJSON`.
private func normalizedJSON(_ payload: JSONCodable?) -> AnyJSON? {
  guard let data = payload?.jsonData else {
    return nil
  }
  return try? JSONDecoder().decode(AnyJSON.self, from: data)
}
