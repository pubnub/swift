//
//  Test+PubNubSpacePatcher.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
@testable import PubNubSpace

import XCTest

class PubNubSpacePatcherTests: XCTestCase {
  var testSpace = PubNubSpace(
    id: "TestSpaceId",
    name: "OldName",
    type: "OldType",
    status: "OldStatus",
    spaceDescription: "OldDescription",
    custom: SpaceCustom(value: "OldValue"),
    updated: .distantPast,
    eTag: "OldETag"
  )

  var patcher = PubNubSpace.Patcher(
    id: "TestSpaceId",
    updated: .distantFuture,
    eTag: "TestETag",
    name: .some("TestName"),
    type: .some("TestType"),
    status: .some("TestStatus"),
    spaceDescription: .some("TestDescription"),
    custom: .some(SpaceCustom(value: "Tester"))
  )

  let patchedSpace = PubNubSpace(
    id: "TestSpaceId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    spaceDescription: "TestDescription",
    custom: SpaceCustom(value: "Tester"),
    updated: .distantFuture,
    eTag: "TestETag"
  )

  func testPatcher_Init() {
    XCTAssertEqual(patcher.id, "TestSpaceId")
    XCTAssertEqual(patcher.updated, .distantFuture)
    XCTAssertEqual(patcher.eTag, "TestETag")
    XCTAssertEqual(patcher.name, .some("TestName"))
    XCTAssertEqual(patcher.type, .some("TestType"))
    XCTAssertEqual(patcher.status, .some("TestStatus"))
    XCTAssertEqual(patcher.spaceDescription, .some("TestDescription"))
    XCTAssertEqual(
      patcher.custom.underlying?.codableValue, SpaceCustom(value: "Tester").codableValue
    )
  }

  func testPatcher_Codable_AllNoChange() throws {
    let nonePatcher = PubNubSpace.Patcher(
      id: "TestSpaceId",
      updated: .distantFuture,
      eTag: "TestETag",
      name: .noChange,
      type: .noChange,
      status: .noChange,
      spaceDescription: .noChange,
      custom: .noChange
    )

    let data = try Constant.jsonEncoder.encode(nonePatcher)
    let spaceFromJSON = try Constant.jsonDecoder
      .decode(PubNubSpace.Patcher.self, from: data)

    XCTAssertEqual(nonePatcher, spaceFromJSON)
  }

  func testPatcher_Decode_AllNone() throws {
    let nonePatcher = PubNubSpace.Patcher(
      id: "TestSpaceId",
      updated: .distantFuture,
      eTag: "TestETag",
      name: .none,
      type: .none,
      status: .none,
      spaceDescription: .none,
      custom: .none
    )

    let data = try Constant.jsonEncoder.encode(nonePatcher)

    let spaceFromJSON = try Constant.jsonDecoder
      .decode(PubNubSpace.Patcher.self, from: data)

    XCTAssertEqual(nonePatcher, spaceFromJSON)
  }

  func testPatcher_Hasher() {
    var hasher = Hasher()
    hasher.combine(patcher.id)
    hasher.combine(patcher.name)
    hasher.combine(patcher.type)
    hasher.combine(patcher.status)
    hasher.combine(patcher.spaceDescription)
    hasher.combine(patcher.custom.underlying?.codableValue)
    hasher.combine(patcher.updated)
    hasher.combine(patcher.eTag)

    XCTAssertEqual(patcher.hashValue, hasher.finalize())
  }

  func testPatcher_ShouldUpdate_True() {
    let shouldUpdate = patcher.shouldUpdate(
      spaceId: patcher.id,
      eTag: UUID().uuidString,
      lastUpdated: .distantPast
    )

    XCTAssertTrue(shouldUpdate)
  }

  func testPatcher_ShouldUpdate_False_NilDate() {
    let shouldUpdate = patcher.shouldUpdate(
      spaceId: patcher.id,
      eTag: UUID().uuidString,
      lastUpdated: nil
    )

    XCTAssertTrue(shouldUpdate)
  }

  func testPatcher_Codable_AllSome() throws {
    let data = try Constant.jsonEncoder.encode(patcher)
    let spaceFromJSON = try? Constant.jsonDecoder
      .decode(PubNubSpace.Patcher.self, from: data)

    XCTAssertEqual(patcher, spaceFromJSON)
  }

  func testPatcher_apply_closure() {
    patcher.apply(
      name: { testSpace.name = $0 },
      type: { testSpace.type = $0 },
      status: { testSpace.status = $0 },
      description: { testSpace.spaceDescription = $0 },
      custom: { testSpace.custom = SpaceCustom(flatJSON: $0?.flatJSON) },
      updated: { testSpace.updated = $0 },
      eTag: { testSpace.eTag = $0 }
    )

    XCTAssertEqual(testSpace, patchedSpace)
  }

  func testPatcher_PubNubSpace_apply() {
    XCTAssertEqual(testSpace.apply(patcher), patchedSpace)
  }

  func testPatcher_PubNubSpace_applyNoUpdate() {
    let wrongSpace = PubNubSpace(id: "not-space")

    XCTAssertNotEqual(wrongSpace.id, patcher.id)
    XCTAssertEqual(wrongSpace.apply(patcher), wrongSpace)
  }
}
