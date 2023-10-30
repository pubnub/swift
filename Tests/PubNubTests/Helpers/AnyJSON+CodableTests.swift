//
//  AnyJSON+CodableTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

// swiftlint:disable:next type_body_length
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
    Float(1.348),
    //    Double(2.34892),
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
    "Float": Float(1.348),
    //    "Double": Double(2.34892),
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

    exampleList.append(exampleDict)
    XCTAssertNotNil(exampleList.last as? [String: Any])

    exampleList.append(exampleList)
    XCTAssertNotNil(exampleList.last as? [Any])

    exampleDict["Dictionary"] = exampleDict
    exampleDict["Array"] = exampleList
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
      let data = try json.jsonDataResult.get()
      let jsonDecoder = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
      XCTAssertEqual(json, jsonDecoder)
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
      let data = try json.jsonDataResult.get()
      let jsonDecoder = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
      XCTAssertEqual(json, jsonDecoder)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }
  }

  func testCompare_Single_String() {
    let testMessage = "abcdefg HIJKLMNO 123456789 !@#$%^&*()"
    let jsonString = AnyJSON(testMessage)
    let jsonStringLiteral = AnyJSON("abcdefg HIJKLMNO 123456789 !@#$%^&*()")

    XCTAssertEqual(jsonString, jsonStringLiteral)
    XCTAssertNotNil(try? jsonString.jsonStringifyResult.get())
    XCTAssertEqual(try? jsonString.jsonStringifyResult.get(), try? jsonString.jsonStringifyResult.get())
    XCTAssertEqual(jsonString.debugDescription, testMessage)
  }

  func testEncode_Single_String() {
    let testValue = "abcdefg HIJKLMNO 123456789 !@#$%^&*()"
    let json = AnyJSON(testValue)
    let jsonFromLiteral = AnyJSON("abcdefg HIJKLMNO 123456789 !@#$%^&*()")

    guard let jsonLiteralData = jsonFromLiteral.jsonData,
          let jsonData = json.jsonData
    else {
      return XCTFail("Couldn't create json data")
    }

    XCTAssertEqual(jsonLiteralData, jsonData)

    let valueLiteral = String(bytes: jsonLiteralData, encoding: .utf8)
    let valueJson = String(bytes: jsonData, encoding: .utf8)

    XCTAssertNotNil(valueLiteral)
    XCTAssertNotNil(valueJson)

    XCTAssertEqual(valueLiteral, "\"\(testValue)\"")
    XCTAssertEqual(valueJson, "\"\(testValue)\"")
  }

  func testEncode_Single_Int() {
    let testValue = 11_123_123
    let json = AnyJSON(testValue)
    let jsonFromLiteral = AnyJSON(11_123_123)

    guard let jsonLiteralData = jsonFromLiteral.jsonData,
          let jsonData = json.jsonData
    else {
      return XCTFail("Couldn't create json data")
    }

    XCTAssertEqual(jsonLiteralData, jsonData)

    guard let valueStringLiteral = String(bytes: jsonLiteralData, encoding: .utf8),
          let valueStringJson = String(bytes: jsonData, encoding: .utf8)
    else {
      return XCTFail("Could not convert data back into string intermediary")
    }

    XCTAssertEqual(valueStringLiteral, valueStringJson)

    let valueLiteral = Int(valueStringLiteral)
    let valueJson = Int(valueStringJson)

    XCTAssertEqual(valueLiteral, testValue)
    XCTAssertEqual(valueJson, testValue)
  }

  func testEncode_Single_Double() {
    let testValue = 11123.2302342
    let json = AnyJSON(testValue)
    let jsonFromLiteral = AnyJSON(11123.2302342)

    guard let jsonLiteralData = jsonFromLiteral.jsonData,
          let jsonData = json.jsonData
    else {
      return XCTFail("Couldn't create json data")
    }

    XCTAssertEqual(jsonLiteralData, jsonData)

    guard let valueStringLiteral = String(bytes: jsonLiteralData, encoding: .utf8),
          let valueStringJson = String(bytes: jsonData, encoding: .utf8)
    else {
      return XCTFail("Could not convert data back into string intermediary")
    }

    XCTAssertEqual(valueStringLiteral, valueStringJson)

    let valueLiteral = Double(valueStringLiteral)
    let valueJson = Double(valueStringJson)

    XCTAssertEqual(valueLiteral, testValue)
    XCTAssertEqual(valueJson, testValue)
  }

  func testEncode_Single_Bool() {
    let testValue = true
    let json = AnyJSON(testValue)
    let jsonFromLiteral = AnyJSON(true)

    guard let jsonLiteralData = jsonFromLiteral.jsonData,
          let jsonData = json.jsonData
    else {
      return XCTFail("Couldn't create json data")
    }

    XCTAssertEqual(jsonLiteralData, jsonData)

    guard let valueStringLiteral = String(bytes: jsonLiteralData, encoding: .utf8),
          let valueStringJson = String(bytes: jsonData, encoding: .utf8)
    else {
      return XCTFail("Could not convert data back into string intermediary")
    }

    XCTAssertEqual(valueStringLiteral, valueStringJson)

    let valueLiteral = Bool(valueStringLiteral)
    let valueJson = Bool(valueStringJson)

    XCTAssertEqual(valueLiteral, testValue)
    XCTAssertEqual(valueJson, testValue)
  }

  func testEncode_Array() {
    let json = AnyJSON(exampleList)
    do {
      let data = try Constant.jsonEncoder.encode(json)
      let anyJSONDecode = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
      XCTAssertEqual(json, anyJSONDecode)
    } catch {
      XCTFail("Exception thrown: \(error)")
    }

    do {
      let data = try Constant.jsonEncoder.encode(json)
      let jsonDecoder = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
      XCTAssertEqual(json, jsonDecoder)
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
      let data = try json.jsonDataResult.get()
      let jsonDecoder = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
      XCTAssertEqual(json, jsonDecoder)
    } catch {
      XCTFail("Exception thrown: \(error.localizedDescription)")
    }
  }

  // MARK: - Failed Coding

  func testFailedEncoding_UnkeyedContainer() {
    let nonCodable = NonCodable(value: "Test")
    let json = AnyJSON([nonCodable])

    XCTAssertThrowsError(
      try json.jsonDataResult.get(),
      "Should throw EncodingError"
    ) { error in
      guard let encodingError = error as? EncodingError else {
        return XCTFail("Error was not the correct type of EncodingError")
      }

      switch encodingError {
      case let .invalidValue(value, context):
        XCTAssertEqual(nonCodable, (value as? AnyJSONType)?.rawValue as? NonCodable)
        XCTAssertEqual(context.codingPath.count, 1)
        XCTAssertNil(context.underlyingError)
        XCTAssertEqual(
          context.debugDescription,
          "AnyJSON could not encode invalid root-level JSON object"
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
      try json.jsonDataResult.get(),
      "Should throw EncodingError"
    ) { error in
      guard let encodingError = error as? EncodingError else {
        return XCTFail("Error was not the correct type of EncodingError")
      }

      switch encodingError {
      case let .invalidValue(value, context):
        XCTAssertEqual(nonCodable, (value as? AnyJSONType)?.rawValue as? NonCodable)
        XCTAssertEqual(context.codingPath.count, 1)
        XCTAssertNil(context.underlyingError)
        XCTAssertEqual(
          context.debugDescription,
          "AnyJSON could not encode invalid root-level JSON object"
        )
      @unknown default:
        XCTFail("New errors types were added that need to be accounted for")
      }
    }
  }

  // MARK: - AnyJSONCodingKey

  func testCodingKeys_IntValue() {
    let intValue = 1
    let keys = AnyJSONType.AnyJSONTypeCodingKey(intValue: intValue)
    XCTAssertNil(keys?.intValue)
    XCTAssertEqual(keys?.stringValue, intValue.description)
  }
}
