//
//  JSONPatchOperationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class JSONPatchOperationTests: XCTestCase {
  private func encode(_ operation: JSONPatchOperation) throws -> AnyJSON {
    let data = try Constant.jsonEncoder.encode([operation])
    let array = try Constant.jsonDecoder.decode([AnyJSON].self, from: data)

    return try XCTUnwrap(array.first)
  }

  private func decode(_ json: String) throws -> JSONPatchOperation {
    try Constant.jsonDecoder.decode(JSONPatchOperation.self, from: try XCTUnwrap(json.data(using: .utf8)))
  }

  private func roundTrip(_ operation: JSONPatchOperation) throws -> JSONPatchOperation {
    try Constant.jsonDecoder.decode(
      JSONPatchOperation.self,
      from: try Constant.jsonEncoder.encode(operation)
    )
  }
}

// MARK: - Encoding

extension JSONPatchOperationTests {
  func test_Encode_AddEmitsOpPathAndValue() throws {
    let json = try encode(.add(path: "/payload/a", value: 1))

    XCTAssertEqual(json["op"]?.stringOptional, "add")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["value"]?.intOptional, 1)
    XCTAssertNil(json["from"])
  }

  func test_Encode_RemoveOmitsValueAndFrom() throws {
    let json = try encode(.remove(path: "/payload/a"))

    XCTAssertEqual(json["op"]?.stringOptional, "remove")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/a")
    XCTAssertNil(json["value"])
    XCTAssertNil(json["from"])
  }

  func test_Encode_ReplaceEmitsOpPathAndValue() throws {
    let json = try encode(.replace(path: "/payload/a", value: "x"))

    XCTAssertEqual(json["op"]?.stringOptional, "replace")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["value"]?.stringOptional, "x")
    XCTAssertNil(json["from"])
  }

  func test_Encode_MoveEmitsFromAndOmitsValue() throws {
    let json = try encode(.move(from: "/payload/a", path: "/payload/b"))

    XCTAssertEqual(json["op"]?.stringOptional, "move")
    XCTAssertEqual(json["from"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/b")
    XCTAssertNil(json["value"])
  }

  func test_Encode_CopyEmitsFromAndOmitsValue() throws {
    let json = try encode(.copy(from: "/payload/a", path: "/payload/b"))

    XCTAssertEqual(json["op"]?.stringOptional, "copy")
    XCTAssertEqual(json["from"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/b")
    XCTAssertNil(json["value"])
  }

  func test_Encode_TestEmitsOpPathAndValue() throws {
    let json = try encode(.test(path: "/payload/a", value: true))

    XCTAssertEqual(json["op"]?.stringOptional, "test")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["value"]?.boolOptional, true)
    XCTAssertNil(json["from"])
  }

  func test_Encode_NullValueIsPreserved() throws {
    let json = try encode(.replace(path: "/payload/a", value: AnyJSON(nil as String? as Any)))

    XCTAssertEqual(json["op"]?.stringOptional, "replace")
    XCTAssertEqual(json["value"]?.isNil, true)
  }
}

// MARK: - Decoding

extension JSONPatchOperationTests {
  func test_Decode_Add() throws {
    let operation = try decode(#"{"op":"add","path":"/payload/a","value":1}"#)

    XCTAssertEqual(operation, .add(path: "/payload/a", value: 1))
  }

  func test_Decode_Remove() throws {
    let operation = try decode(#"{"op":"remove","path":"/payload/a"}"#)

    XCTAssertEqual(operation, .remove(path: "/payload/a"))
  }

  func test_Decode_Move() throws {
    let operation = try decode(#"{"op":"move","from":"/payload/a","path":"/payload/b"}"#)

    XCTAssertEqual(operation, .move(from: "/payload/a", path: "/payload/b"))
  }

  func test_Decode_UnknownOpThrows() {
    XCTAssertThrowsError(try decode(#"{"op":"increment","path":"/payload/a"}"#))
  }

  func test_Decode_MissingValueForAddThrows() {
    XCTAssertThrowsError(try decode(#"{"op":"add","path":"/payload/a"}"#))
  }

  func test_Decode_MissingFromForMoveThrows() {
    XCTAssertThrowsError(try decode(#"{"op":"move","path":"/payload/b"}"#))
  }

  func test_Decode_MissingPathThrows() {
    XCTAssertThrowsError(try decode(#"{"op":"remove"}"#))
  }
}

// MARK: - Round trip

extension JSONPatchOperationTests {
  func test_RoundTrip_PreservesEveryOperation() throws {
    let operations: [JSONPatchOperation] = [
      .add(path: "/payload/a", value: ["nested": 1]),
      .remove(path: "/payload/a"),
      .replace(path: "/payload/a", value: "x"),
      .move(from: "/payload/a", path: "/payload/b"),
      .copy(from: "/payload/a", path: "/payload/b"),
      .test(path: "/payload/a", value: true)
    ]

    for operation in operations {
      XCTAssertEqual(try roundTrip(operation), operation)
    }
  }
}

// MARK: - Accessors

extension JSONPatchOperationTests {
  func test_Accessors_ExposeOpPathFromAndValue() {
    let operation = JSONPatchOperation.copy(from: "/payload/a", path: "/payload/b")

    XCTAssertEqual(operation.op, .copy)
    XCTAssertEqual(operation.path, "/payload/b")
    XCTAssertEqual(operation.from, "/payload/a")
    XCTAssertNil(operation.value)
  }

  func test_Accessors_ValueOnlyPresentForValueOperations() {
    XCTAssertEqual(JSONPatchOperation.add(path: "/a", value: 1).value, 1)
    XCTAssertEqual(JSONPatchOperation.replace(path: "/a", value: 1).value, 1)
    XCTAssertEqual(JSONPatchOperation.test(path: "/a", value: 1).value, 1)
    XCTAssertNil(JSONPatchOperation.remove(path: "/a").value)
    XCTAssertNil(JSONPatchOperation.move(from: "/a", path: "/b").value)
    XCTAssertNil(JSONPatchOperation.copy(from: "/a", path: "/b").value)
  }

  func test_Accessors_FromOnlyPresentForMoveAndCopy() {
    XCTAssertEqual(JSONPatchOperation.move(from: "/a", path: "/b").from, "/a")
    XCTAssertEqual(JSONPatchOperation.copy(from: "/a", path: "/b").from, "/a")
    XCTAssertNil(JSONPatchOperation.add(path: "/a", value: 1).from)
    XCTAssertNil(JSONPatchOperation.remove(path: "/a").from)
    XCTAssertNil(JSONPatchOperation.replace(path: "/a", value: 1).from)
    XCTAssertNil(JSONPatchOperation.test(path: "/a", value: 1).from)
  }
}
