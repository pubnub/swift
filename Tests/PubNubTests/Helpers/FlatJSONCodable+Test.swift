//
//  FlatJSONCodable+Test.swift
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

@testable import PubNub
import XCTest

class FlatJSONCodableTests: XCTestCase {
  struct Custom: FlatJSONCodable {
    var value: String?

    init(flatJSON: [String : JSONCodableScalar]) {
      value = flatJSON["value"]?.stringOptional
    }
  }

  func testFlatJSONCodable_init_optional() {
    let custom = Custom(flatJSON: ["value": "test"])
    let optionalCustom: [String: JSONCodableScalar]? = [
      "value": JSONCodableScalarType(stringValue: "test")
    ]

    XCTAssertEqual(custom.codableValue, Custom(flatJSON: optionalCustom).codableValue)
  }

  func testFlatJSONCodable_init_optionalEmpty() {
    let custom = Custom(flatJSON: [:])
    
    XCTAssertEqual(custom.codableValue, Custom(flatJSON: nil).codableValue)
  }

  func testFlatJSONCodable_flatJSON() {
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
  func testFlatJSON_init() {
    let custom = FlatJSON(flatJSON: ["value": "test"])
    let customDictionry = [
      "value": JSONCodableScalarType(stringValue: "test")
    ]
    
    XCTAssertEqual(
      custom.codableValue, FlatJSON(flatJSON: customDictionry).codableValue
    )
  }
  
  func testFlatJSON_flatJSON() {
    let custom: [String: JSONCodableScalar] = [
      "value": JSONCodableScalarType(stringValue: "test")
    ]
    
    XCTAssertEqual(
      custom["value"]?.stringOptional,
      FlatJSON(flatJSON: custom).flatJSON["value"]?.stringOptional
    )
  }

  func testFlatJSON_Codable() throws {
    let initialJSON = FlatJSON(flatJSON: ["value": "test"])

    let data = try Constant.jsonEncoder.encode(initialJSON)
    let output = try Constant.jsonDecoder.decode(FlatJSON.self, from: data)

    XCTAssertEqual(
      initialJSON, output
    )
  }
}
