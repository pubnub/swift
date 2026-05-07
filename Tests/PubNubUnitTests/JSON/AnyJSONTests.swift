//
//  AnyJSONTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

struct SomeCodable: Codable, Equatable {
  var value: String
}

class AnyJSONTests: XCTestCase {
  struct NonHashable: Codable {
    var value: String
  }

  struct NonHashableStringConvertible: Codable, CustomStringConvertible, CustomDebugStringConvertible {
    var value: String

    var description: String {
      return value
    }
    var debugDescription: String {
      return value.debugDescription
    }
  }

  // MARK: Hashable

  func test_AnyJSON_CompareCodableArrays_ReturnsEqual() {
    let nonHashable = NonHashable(value: "value")
    let json = AnyJSON([nonHashable])

    XCTAssertEqual(json, AnyJSON([nonHashable]))
  }

  func test_AnyJSON_ArrayWithMismatchedTypes_ReturnsNotEqual() {
    let json = AnyJSON([1, 2, 3])
    let otherJson = AnyJSON([1, 2, "3"])

    XCTAssertNotEqual(json, otherJson)
  }

  func test_AnyJSON_ArrayWithMismatchedSizes_ReturnsNotEqual() {
    let json = AnyJSON([1, 2, 3])
    let otherJson = AnyJSON([1, 2])

    XCTAssertNotEqual(json, otherJson)
  }

  func test_AnyJSON_DictionaryWithMismatchedTypes_ReturnsNotEqual() {
    let json = AnyJSON(["one": 1, "two": 2, "three": 3])
    let otherJson = AnyJSON(["one": 1, "two": 2, "three": "3"])

    XCTAssertNotEqual(json, otherJson)
  }

  func test_AnyJSON_DictionaryWithMismatchedSizes_ReturnsNotEqual() {
    let json = AnyJSON(["one": 1, "two": 2, "three": 3])
    let otherJson = AnyJSON(["one": 1, "two": 2])

    XCTAssertNotEqual(json, otherJson)
  }

  // MARK: ExpressibleBy...

  func test_AnyJSON_ExpressibleByArrayLiteral_MatchesArrayInit() {
    let literal: [Any] = ["One", 2, true, 3.0]
    let json: AnyJSON = ["One", 2, true, 3.0]

    XCTAssertEqual(json, AnyJSON(literal))
    XCTAssertNotNil(json.arrayOptional)
  }

  func test_AnyJSON_ExpressibleByDictionaryLiteral_MatchesDictionaryInit() {
    let literal: [String: Any] = [
      "String": "One",
      "Int": 2,
      "Bool": true,
      "Float": 3.0
    ]

    let json: AnyJSON = [
      "String": "One",
      "Int": 2,
      "Bool": true,
      "Float": 3.0
    ]

    XCTAssertEqual(json, AnyJSON(literal))
    XCTAssertNotNil(json.dictionaryOptional)
  }

  // MARK: Stringify

  func test_AnyJSON_StringifyRecodeBool_ReturnsOriginalValue() throws {
    let testValue = true
    let valueString = try XCTUnwrap(AnyJSON(testValue).jsonStringify)
    let valueRecoded = try XCTUnwrap(AnyJSON(reverse: valueString).boolOptional)

    XCTAssertEqual(testValue, valueRecoded)
  }

  func test_AnyJSON_StringifyRecodeInt_ReturnsOriginalValue() throws {
    let testValue = 10
    let valueString = try XCTUnwrap(AnyJSON(testValue).jsonStringify)
    let valueRecoded = try XCTUnwrap(AnyJSON(reverse: valueString).intOptional)

    XCTAssertEqual(testValue, valueRecoded)
  }

  func test_AnyJSON_StringifyRecodeDouble_ReturnsOriginalValue() throws {
    let testValue = 145.502
    let valueString = try XCTUnwrap(AnyJSON(testValue).jsonStringify)
    let valueRecoded = try XCTUnwrap(AnyJSON(reverse: valueString).doubleOptional)

    XCTAssertEqual(testValue, valueRecoded)
  }

  func test_AnyJSON_StringifyRecodeNil_ReturnsEmptyAndNil() throws {
    let testValue = NSNull()
    let valueString = try XCTUnwrap(AnyJSON(testValue).jsonStringify)
    let valueRecoded = AnyJSON(reverse: valueString)

    XCTAssertTrue(valueRecoded.isEmpty && valueRecoded.isNil)
  }

  func test_AnyJSON_StringifyRecodeArray_ReturnsOriginalValue() throws {
    let testValue = [10, 22, 34]
    let valueString = try XCTUnwrap(AnyJSON(testValue).jsonStringify)
    let valueRecoded = try XCTUnwrap(AnyJSON(reverse: valueString).arrayOptional)

    XCTAssertEqual(testValue.description, valueRecoded.description)
  }

  func test_AnyJSON_StringifyRecodeDictionary_ReturnsOriginalValue() throws {
    let testValue = ["TestKey": "TestValue"]
    let valueString = try XCTUnwrap(AnyJSON(testValue).jsonStringify)
    let valueRecoded = try XCTUnwrap(AnyJSON(reverse: valueString).dictionaryOptional)

    XCTAssertEqual(testValue.description, valueRecoded.description)
  }

  func test_AnyJSON_StringifyRecodeCodable_ReturnsOriginalValue() throws {
    let testValue = SomeCodable(value: "Hello")
    let valueString = try XCTUnwrap(AnyJSON(testValue).jsonStringify)
    let valueRecoded = try AnyJSON(reverse: valueString).decode(SomeCodable.self)

    XCTAssertEqual(testValue, valueRecoded)
  }

  func test_AnyJSON_StringifyRecodeString_ReturnsOriginalValue() throws {
    let testValue = "TestString"
    let valueString = try XCTUnwrap(AnyJSON(testValue).jsonStringify)
    let valueRecoded = try XCTUnwrap(AnyJSON(reverse: valueString).stringOptional)

    XCTAssertEqual(testValue, valueRecoded)
  }

  // MARK: - Convertible

  func test_AnyJSON_DescriptionWithString_ReturnsJSONString() {
    let testString = "String Describing This Object"
    let testStringDescription = "[\"\(testString)\"]"
    let stringJSON = AnyJSON([testString])

    XCTAssertEqual(stringJSON.description, testStringDescription)
  }

  func test_AnyJSON_DescriptionWithForwardSlashes_PreservesSlashes() {
    let testString = "String/containing/Slashes"
    let testStringDescription = "[\"\(testString)\"]"
    let stringJSON = AnyJSON([testString])

    XCTAssertEqual(stringJSON.description, testStringDescription)
  }

  func test_AnyJSON_DescriptionWithNonHashableDescribable_ReturnsEncodedJSON() {
    let testString = "String Describing This Object"
    let test = NonHashableStringConvertible(value: testString)
    let stringJSON = AnyJSON([test])

    XCTAssertEqual(stringJSON.description, "[{\"value\":\"\(testString)\"}]")
  }

  func test_AnyJSON_DescriptionWithNonHashableNonDescribable_ReturnsEncodedJSON() {
    let testString = "String Describing This Object"
    let test = NonHashable(value: testString)
    let json = AnyJSON([test])

    XCTAssertEqual(json.description, "[{\"value\":\"\(testString)\"}]")
  }

  func test_AnyJSON_DebugDescriptionWithString_ReturnsJSONString() {
    let testString = "String Describing This Object"
    let testStringDescription = "[\"\(testString)\"]"
    let stringJSON = AnyJSON([testString])

    XCTAssertEqual(stringJSON.debugDescription, testStringDescription)
  }

  func test_AnyJSON_DebugDescriptionWithForwardSlashes_PreservesSlashes() {
    let testString = "String/containing/Slashes"
    let testStringDescription = "[\"\(testString)\"]"
    let stringJSON = AnyJSON([testString])

    XCTAssertEqual(stringJSON.debugDescription, testStringDescription)
  }

  func test_AnyJSON_DebugDescriptionWithNonHashableDescribable_ReturnsArrayDescription() {
    let testString = "String Describing This Object"
    let test = NonHashableStringConvertible(value: testString)
    let stringJSON = AnyJSON([test])

    XCTAssertEqual(stringJSON.debugDescription, [test].description)
  }

  func test_AnyJSON_DebugDescriptionWithNonHashableNonDescribable_ReturnsArrayDescription() {
    let testString = "String Describing This Object"
    let test = NonHashable(value: testString)
    let json = AnyJSON([test])

    XCTAssertEqual(json.debugDescription, [test].description)
  }

  // MARK: - subscript

  func test_AnyJSON_SubscriptRawValueDictionary_ReturnsValue() {
    let testValue = "Hello"
    let testDict = ["messageText": testValue]
    let json = AnyJSON(testDict)

    XCTAssertEqual(json.dictionaryOptional as? [String: String], testDict)
    XCTAssertEqual(json[rawValue: "messageText"] as? String, testValue)
  }
}
