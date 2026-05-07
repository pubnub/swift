//
//  FlatJSONCodable+Test.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

class FlatJSONCodableTests: XCTestCase {
  struct Custom: FlatJSONCodable {
    var value: String?

    init(flatJSON: [String: JSONCodableScalar]) {
      value = flatJSON["value"]?.stringOptional
    }
  }

  func test_FlatJSONCodable_InitWithOptionalDictionary_MatchesDirectInit() {
    let custom = Custom(flatJSON: ["value": "test"])
    let optionalCustom: [String: JSONCodableScalar]? = [
      "value": JSONCodableScalarType(stringValue: "test")
    ]

    XCTAssertEqual(custom.codableValue, Custom(flatJSON: optionalCustom).codableValue)
  }

  func test_FlatJSONCodable_InitWithNilOptional_MatchesEmptyDictInit() {
    let custom = Custom(flatJSON: [:])

    XCTAssertEqual(custom.codableValue, Custom(flatJSON: nil).codableValue)
  }

  func test_FlatJSONCodable_FlatJSONProperty_ReturnsOriginalValue() {
    let custom: [String: JSONCodableScalar] = [
      "value": JSONCodableScalarType(stringValue: "test")
    ]

    XCTAssertEqual(
      custom["value"]?.stringOptional,
      Custom(flatJSON: custom).flatJSON["value"]?.stringOptional
    )
  }
}

// MARK: Concrete Type Tests

class FlatJSONTests: XCTestCase {
  func test_FlatJSON_InitWithDictionary_MatchesTypedInit() {
    let custom = FlatJSON(flatJSON: ["value": "test"])
    let customDictionry = [
      "value": JSONCodableScalarType(stringValue: "test")
    ]

    XCTAssertEqual(
      custom.codableValue, FlatJSON(flatJSON: customDictionry).codableValue
    )
  }

  func test_FlatJSON_FlatJSONProperty_ReturnsOriginalValue() {
    let custom: [String: JSONCodableScalar] = [
      "value": JSONCodableScalarType(stringValue: "test")
    ]

    XCTAssertEqual(
      custom["value"]?.stringOptional,
      FlatJSON(flatJSON: custom).flatJSON["value"]?.stringOptional
    )
  }

  func test_FlatJSON_EncodeDecode_RoundTripsSuccessfully() throws {
    let initialJSON = FlatJSON(flatJSON: ["value": "test"])

    let data = try Constant.jsonEncoder.encode(initialJSON)
    let output = try Constant.jsonDecoder.decode(FlatJSON.self, from: data)

    XCTAssertEqual(
      initialJSON, output
    )
  }
}
