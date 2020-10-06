//
//  AnyJSONTests.swift
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

  func testbyteSize() {
    let config = PubNubConfiguration(publishKey: "pub-c-ea156c6c-c5cb-4870-b264-499afff37cac",
                                     subscribeKey: "sub-c-2e2b364a-856e-11ea-885f-2621b2dc68c7")
    let message: JSONCodable = ["$": "35.75", "HI": "b62", "t": "BO"]
    let channel = "AuctioniPhone11ProSimRider"
    guard let messageJSONString = message.jsonStringify,
      let pubKey = config.publishKey
    else {
      return
    }

    var urlComponents = URLComponents()
    urlComponents.scheme = config.urlScheme
    urlComponents.host = config.origin

    urlComponents.path = "/signal/\(pubKey)/\(config.subscribeKey)/0/\(channel.urlEncodeSlash)/0/\(messageJSONString)"
    // URL will double encode our attempts to sanitize '/' inside path inputs
    urlComponents.percentEncodedPath = urlComponents.percentEncodedPath.decodeDoubleEncodedSlash

    guard let url = urlComponents.url,
      let urlData = url.description.split(separator: "/").last?.data(using: .utf8)
    else {
      return
    }

    let byteCount = ByteCountFormatter().string(fromByteCount: Int64(urlData.count))

    print("The payload size is roughly \(byteCount)")
  }

  // MARK: Hashable

  func testCompare_Codable() {
    let nonHashable = NonHashable(value: "value")

    let json = AnyJSON([nonHashable])

    XCTAssertEqual(json, AnyJSON([nonHashable]))
  }

  func testArrayEquatible_Mismatch() {
    let json = AnyJSON([1, 2, 3])
    let otherJson = AnyJSON([1, 2, "3"])

    XCTAssertNotEqual(json, otherJson)
  }

  func testArrayEquatible_MismatchSizes() {
    let json = AnyJSON([1, 2, 3])
    let otherJson = AnyJSON([1, 2])

    XCTAssertNotEqual(json, otherJson)
  }

  func testDictionaryEquatible_Mismatch() {
    let json = AnyJSON(["one": 1, "two": 2, "three": 3])
    let otherJson = AnyJSON(["one": 1, "two": 2, "three": "3"])

    XCTAssertNotEqual(json, otherJson)
  }

  func testDictionaryEquatible_MismatchSizes() {
    let json = AnyJSON(["one": 1, "two": 2, "three": 3])
    let otherJson = AnyJSON(["one": 1, "two": 2])

    XCTAssertNotEqual(json, otherJson)
  }

  // MARK: ExpressibleBy...

  func testExpressible_Array() {
    let literal: [Any] = ["One", 2, true, 3.0]

    let json: AnyJSON = ["One", 2, true, 3.0]

    XCTAssertEqual(json, AnyJSON(literal))
    XCTAssertNotNil(json.arrayOptional)
  }

  func testExpressible_Dictionary() {
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

  func testStringifyRecode_Bool() {
    let testValue = true
    guard let valueString = AnyJSON(testValue).jsonStringify else {
      return XCTFail("Couldn't stringify value")
    }
    guard let valueRecoded = AnyJSON(reverse: valueString).boolOptional else {
      return XCTFail("Couldn't stringify value")
    }
    XCTAssertEqual(testValue, valueRecoded)
  }

  func testStringifyRecode_Int() {
    let testValue = 10
    guard let valueString = AnyJSON(testValue).jsonStringify else {
      return XCTFail("Couldn't stringify value")
    }
    guard let valueRecoded = AnyJSON(reverse: valueString).intOptional else {
      return XCTFail("Couldn't stringify value")
    }
    XCTAssertEqual(testValue, valueRecoded)
  }

  func testStringifyRecode_Double() {
    let testValue = 145.502
    guard let valueString = AnyJSON(testValue).jsonStringify else {
      return XCTFail("Couldn't stringify value")
    }
    guard let valueRecoded = AnyJSON(reverse: valueString).doubleOptional else {
      return XCTFail("Couldn't stringify value")
    }
    XCTAssertEqual(testValue, valueRecoded)
  }

  func testStringifyRecode_nil() {
    let testValue = NSNull()
    guard let valueString = AnyJSON(testValue).jsonStringify else {
      return XCTFail("Couldn't stringify value")
    }
    let valueRecoded = AnyJSON(reverse: valueString)
    XCTAssertTrue(valueRecoded.isEmpty && valueRecoded.isNil)
  }

  func testStringifyRecode_Array() {
    let testValue = [10, 22, 34]
    guard let valueString = AnyJSON(testValue).jsonStringify else {
      return XCTFail("Couldn't stringify value")
    }
    guard let valueRecoded = AnyJSON(reverse: valueString).arrayOptional else {
      return XCTFail("Couldn't stringify value")
    }
    XCTAssertEqual(testValue.description, valueRecoded.description)
  }

  func testStringifyRecode_Dictionary() {
    let testValue = ["TestKey": "TestValue"]
    guard let valueString = AnyJSON(testValue).jsonStringify else {
      return XCTFail("Couldn't stringify value")
    }
    guard let valueRecoded = AnyJSON(reverse: valueString).dictionaryOptional else {
      return XCTFail("Couldn't stringify value")
    }
    XCTAssertEqual(testValue.description, valueRecoded.description)
  }

  func testStringifyRecode_Codable() {
    let testValue = SomeCodable(value: "Hello")
    guard let valueString = AnyJSON(testValue).jsonStringify else {
      return XCTFail("Couldn't stringify value")
    }
    guard let valueRecoded = try? AnyJSON(reverse: valueString).decode(SomeCodable.self) else {
      return XCTFail("Couldn't stringify value")
    }
    XCTAssertEqual(testValue, valueRecoded)
  }

  func testStringifyRecode_String() {
    let testValue = "TestString"
    guard let valueString = AnyJSON(testValue).jsonStringify else {
      return XCTFail("Couldn't stringify value")
    }
    guard let valueRecoded = AnyJSON(reverse: valueString).stringOptional else {
      return XCTFail("Couldn't stringify value")
    }
    XCTAssertEqual(testValue, valueRecoded)
  }

  // MARK: - Convertible

  func testCustomStringConvertible_JSONString() {
    let testString = "String Describing This Object"
    let testStringDescription = "[\"\(testString)\"]"

    let stringJSON = AnyJSON([testString])
    XCTAssertEqual(stringJSON.description, testStringDescription)
  }

  func testCustomStringConvertible_JSONString_WithForwardSlashe() {
    let testString = "String/containing/Slashes"
    let testStringDescription = "[\"\(testString)\"]"

    let stringJSON = AnyJSON([testString])
    XCTAssertEqual(stringJSON.description, testStringDescription)
  }

  func testCustomStringConvertible_NonHashable_Description() {
    let testString = "String Describing This Object"

    let test = NonHashableStringConvertible(value: testString)

    let stringJSON = AnyJSON([test])
    XCTAssertEqual(stringJSON.description, "[{\"value\":\"\(testString)\"}]")
  }

  func testCustomStringConvertible_NonHashable_NoDescription() {
    let testString = "String Describing This Object"

    let test = NonHashable(value: testString)

    let json = AnyJSON([test])
    XCTAssertEqual(json.description, "[{\"value\":\"\(testString)\"}]")
  }

  func testCustomDebugStringConvertible_JSONString() {
    let testString = "String Describing This Object"
    let testStringDescription = "[\"\(testString)\"]"

    let stringJSON = AnyJSON([testString])
    XCTAssertEqual(stringJSON.debugDescription, testStringDescription)
  }

  func testCustomDebugStringConvertible_JSONString_WithForwardSlashe() {
    let testString = "String/containing/Slashes"
    let testStringDescription = "[\"\(testString)\"]"

    let stringJSON = AnyJSON([testString])
    XCTAssertEqual(stringJSON.debugDescription, testStringDescription)
  }

  func testCustomDebugStringConvertible_NonHashable_Description() {
    let testString = "String Describing This Object"

    let test = NonHashableStringConvertible(value: testString)

    let stringJSON = AnyJSON([test])
    XCTAssertEqual(stringJSON.debugDescription, [test].description)
  }

  func testCustomDebugStringConvertible_NonHashable_NoDescription() {
    let testString = "String Describing This Object"

    let test = NonHashable(value: testString)

    let json = AnyJSON([test])
    XCTAssertEqual(json.debugDescription, [test].description)
  }

  // MARK: - subscript

  func testAnyJSON_subscript_rawValue_dictionary() {
    let testValue = "Hello"

    let testDict = ["messageText": testValue]

    let json = AnyJSON(testDict)

    XCTAssertEqual(json.dictionaryOptional as? [String: String], testDict)
    XCTAssertEqual(json[rawValue: "messageText"] as? String, testValue)
  }
}
