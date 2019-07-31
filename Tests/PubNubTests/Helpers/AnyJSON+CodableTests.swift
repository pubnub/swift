//
//  AnyJSON+CodableTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

class AnyJSONCodableTests: XCTestCase {
  struct NonCodable: Hashable {
    var value: String
  }

  struct CodableStruct: Codable, Hashable {
    var value: String
  }

  var exampleList: [Any] = [
    "String",
    true,
    Date(),
    Float(1.34892),
    Double(2.34892),
    Decimal(3.34892),
    Int.min,
    Int8.min,
    Int16.min,
    Int32.min,
    Int64.min,
    UInt.max,
    UInt8.max,
    UInt16.max,
    UInt32.max,
    UInt64.max
  ]
  let emptyList = [Any]()

  var exampleDict: [String: Any] = [
    "String": "String",
    "Bool": true,
    "Date": Date(),
    "Float": Float(1.34892),
    "Double": Double(2.34892),
    "Decimal": Decimal(3.34892),
    "Int": Int.min,
    "Int8": Int8.min,
    "Int16": Int16.min,
    "Int32": Int32.min,
    "Int64": Int64.min,
    "UInt": UInt.max,
    "UInt8": UInt8.max,
    "UInt16": UInt16.max,
    "UInt32": UInt32.max,
    "UInt64": UInt64.max
  ]
  let emptyDict = [String: Any]()

  override func setUp() {
    super.setUp()

    guard let data = "Big Data".data(using: .utf8) else {
      return XCTFail("Could not create data")
    }

    exampleList.append(data)
    XCTAssertNotNil(exampleList.last as? Data)

    exampleList.append(exampleDict)
    XCTAssertNotNil(exampleList.last as? [String: Any])

    exampleList.append(exampleList)
    XCTAssertNotNil(exampleList.last as? [Any])

    exampleDict["Data"] = data
    exampleDict["Dictionary"] = exampleDict
    exampleDict["Array"] = exampleList
    XCTAssertNotNil(exampleDict["Data"] as? Data)
    XCTAssertNotNil(exampleDict["Dictionary"] as? [String: Any])
    XCTAssertNotNil(exampleDict["Array"] as? [Any])
  }

  func testEncode_Dictionary() {
    let json = AnyJSON(exampleDict)

    do {
      let anyJSONDecode = try json.decode(AnyJSON.self)
      XCTAssertEqual(json, anyJSONDecode)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }

    do {
      let data = try json.jsonEncodedData()
      let jsonDecoder = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
      XCTAssertEqual(json, jsonDecoder)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }

    do {
      _ = try json.jsonString()
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }
  }

  func testEncode_Dictionary_Empty() {
    let json = AnyJSON(emptyDict)

    do {
      let anyJSONDecode = try json.decode(AnyJSON.self)
      XCTAssertEqual(json, anyJSONDecode)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }

    do {
      let data = try json.jsonEncodedData()
      let jsonDecoder = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
      XCTAssertEqual(json, jsonDecoder)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }

    do {
      _ = try json.jsonString()
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }
  }

  func testEncode_Array() {

    let json = AnyJSON(exampleList)

    do {
      let anyJSONDecode = try json.decode(AnyJSON.self)
      XCTAssertEqual(json, anyJSONDecode)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }

    do {
      let data = try json.jsonEncodedData()
      let jsonDecoder = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
      XCTAssertEqual(json, jsonDecoder)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }

    do {
      _ = try json.jsonString()
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }
  }

  func testEncode_Array_Empty() {
    let json = AnyJSON(emptyList)

    do {
      let anyJSONDecode = try json.decode(AnyJSON.self)
      XCTAssertEqual(json, anyJSONDecode)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }

    do {
      let data = try json.jsonEncodedData()
      let jsonDecoder = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
      XCTAssertEqual(json, jsonDecoder)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }

    do {
      _ = try json.jsonString()
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }
  }

  // MARK: - Failed Coding

  func testFailedEncoding_SingleValueContainer() {
    let nonCodable = NonCodable(value: "Test")
    let json = AnyJSON(nonCodable)

    XCTAssertThrowsError(
      try json.jsonEncodedData(),
      "Should throw EncodingError"
    ) { error in
      guard let encodingError = error as? EncodingError else {
        return XCTFail("Error was not the correct type of EncodingError")
      }

      switch encodingError {
      case let .invalidValue(value, context):

        XCTAssertEqual(nonCodable, value as? NonCodable)
        XCTAssertEqual(context.codingPath.count, 0)
        XCTAssertNil(context.underlyingError)
        XCTAssertEqual(
          context.debugDescription,
          ErrorDescription.EncodingError.invalidRootLevelErrorDescription
        )
      @unknown default:
        XCTFail("New errors types were added that need to be accounted for")
      }
    }
  }

  func testFailedEncoding_UnkeyedContainer() {
    let nonCodable = NonCodable(value: "Test")
    let json = AnyJSON([nonCodable])

    XCTAssertThrowsError(
      try json.jsonEncodedData(),
      "Should throw EncodingError"
    ) { error in
      guard let encodingError = error as? EncodingError else {
        return XCTFail("Error was not the correct type of EncodingError")
      }

      switch encodingError {
      case let .invalidValue(value, context):

        XCTAssertEqual(nonCodable, value as? NonCodable)
        XCTAssertEqual(context.codingPath.count, 0)
        XCTAssertNil(context.underlyingError)
        XCTAssertEqual(
          context.debugDescription,
          ErrorDescription.EncodingError.invalidUnkeyedContainerErrorDescription
        )
      @unknown default:
        XCTFail("New errors types were added that need to be accounted for")
      }
    }
  }

  func testFailedEncoding_KeyedContainer() {
    let codableKey = "NonCodable"
    let nonCodable = NonCodable(value: "Test")
    let json = AnyJSON([codableKey: nonCodable])

    XCTAssertThrowsError(
      try json.jsonEncodedData(),
      "Should throw EncodingError"
    ) { error in
      guard let encodingError = error as? EncodingError else {
        return XCTFail("Error was not the correct type of EncodingError")
      }

      switch encodingError {
      case let .invalidValue(value, context):
        XCTAssertEqual(nonCodable, value as? NonCodable)
        XCTAssertEqual(context.codingPath.count, 0)
        XCTAssertNil(context.underlyingError)
        XCTAssertEqual(
          context.debugDescription,
          ErrorDescription.EncodingError.invalidKeyedContainerErrorDescription
        )
      @unknown default:
        XCTFail("New errors types were added that need to be accounted for")
      }
    }
  }

  // MARK: - AnyJSONCodingKey

  func testCodingKeys_IntValue() {
    let intValue = 1
    let keys = AnyJSONCodingKey(intValue: intValue)
    XCTAssertNil(keys?.intValue)
    XCTAssertEqual(keys?.stringValue, intValue.description)
  }
}
