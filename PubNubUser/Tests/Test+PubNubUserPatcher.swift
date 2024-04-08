//
//  Test+PubNubUserPatcher.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
@testable import PubNubUser

import XCTest

class PubNubUserPatcherTests: XCTestCase {
  var testUser = PubNubUser(
    id: "TestUserId",
    name: "OldName",
    type: "OldType",
    status: "OldStatus",
    externalId: "OldExternalID",
    profileURL: URL(string: "http://old.example.com"),
    email: "OldEmail",
    custom: UserCustom(value: "OldValue"),
    updated: .distantPast,
    eTag: "OldETag"
  )

  var patcher = PubNubUser.Patcher(
    id: "TestUserId",
    updated: .distantFuture,
    eTag: "TestETag",
    name: .some("TestName"),
    type: .some("TestType"),
    status: .some("TestStatus"),
    externalId: .some("TestExternalId"),
    // swiftlint:disable:next force_unwrapping
    profileURL: .some(URL(string: "http://example.com")!),
    email: .some("TestEmail"),
    custom: .some(UserCustom(value: "Tester"))
  )

  let patchedUser = PubNubUser(
    id: "TestUserId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    externalId: "TestExternalId",
    profileURL: URL(string: "http://example.com"),
    email: "TestEmail",
    custom: UserCustom(value: "Tester"),
    updated: .distantFuture,
    eTag: "TestETag"
  )

  func testPatcher_Init() {
    XCTAssertEqual(patcher.id, "TestUserId")
    XCTAssertEqual(patcher.updated, .distantFuture)
    XCTAssertEqual(patcher.eTag, "TestETag")
    XCTAssertEqual(patcher.name, .some("TestName"))
    XCTAssertEqual(patcher.type, .some("TestType"))
    XCTAssertEqual(patcher.status, .some("TestStatus"))
    XCTAssertEqual(patcher.externalId, .some("TestExternalId"))
    // swiftlint:disable:next force_unwrapping
    XCTAssertEqual(patcher.profileURL, .some(URL(string: "http://example.com")!))
    XCTAssertEqual(patcher.email, .some("TestEmail"))
    XCTAssertEqual(
      patcher.custom.underlying?.codableValue, UserCustom(value: "Tester").codableValue
    )
  }

  func testPatcher_Codable_InvalidURLString() {
    let jsonString = """
    {
      "id": "TestUserId",
      "profileUrl": "",
      "updated": "0001-01-01T00:00:00.000Z",
      "eTag": "TestETag"
    }
    """

    guard let data = jsonString.data(using: .utf8) else {
      XCTFail("Could not encode data")
      return
    }

    XCTAssertThrowsError(
      try Constant.jsonDecoder.decode(PubNubUser.Patcher.self, from: data)
    )
  }

  func testPatcher_Codable_AllNoChange() throws {
    let nonePatcher = PubNubUser.Patcher(
      id: "TestUserId",
      updated: .distantFuture,
      eTag: "TestETag",
      name: .noChange,
      type: .noChange,
      status: .noChange,
      externalId: .noChange,
      profileURL: .noChange,
      email: .noChange,
      custom: .noChange
    )

    let data = try Constant.jsonEncoder.encode(nonePatcher)
    let userFromJSON = try Constant.jsonDecoder
      .decode(PubNubUser.Patcher.self, from: data)

    XCTAssertEqual(nonePatcher, userFromJSON)
  }

  func testPatcher_Decode_AllNone() throws {
    let nonePatcher = PubNubUser.Patcher(
      id: "TestUserId",
      updated: .distantFuture,
      eTag: "TestETag",
      name: .none,
      type: .none,
      status: .none,
      externalId: .none,
      profileURL: .none,
      email: .none,
      custom: .none
    )

    let data = try Constant.jsonEncoder.encode(nonePatcher)

    let userFromJSON = try Constant.jsonDecoder
      .decode(PubNubUser.Patcher.self, from: data)

    XCTAssertEqual(nonePatcher, userFromJSON)
  }

  func testPatcher_Hasher() {
    var hasher = Hasher()
    hasher.combine(patcher.id)
    hasher.combine(patcher.name)
    hasher.combine(patcher.type)
    hasher.combine(patcher.status)
    hasher.combine(patcher.externalId)
    hasher.combine(patcher.profileURL)
    hasher.combine(patcher.email)
    hasher.combine(patcher.custom.underlying?.codableValue)
    hasher.combine(patcher.updated)
    hasher.combine(patcher.eTag)

    XCTAssertEqual(patcher.hashValue, hasher.finalize())
  }

  func testPatcher_ShouldUpdate_True() {
    let shouldUpdate = patcher.shouldUpdate(
      userId: patcher.id,
      eTag: UUID().uuidString,
      lastUpdated: .distantPast
    )

    XCTAssertTrue(shouldUpdate)
  }

  func testPatcher_ShouldUpdate_False_NilDate() {
    let shouldUpdate = patcher.shouldUpdate(
      userId: patcher.id,
      eTag: UUID().uuidString,
      lastUpdated: nil
    )

    XCTAssertTrue(shouldUpdate)
  }

  func testPatcher_Codable_AllSome() throws {
    let data = try Constant.jsonEncoder.encode(patcher)
    let userFromJSON = try? Constant.jsonDecoder
      .decode(PubNubUser.Patcher.self, from: data)

    XCTAssertEqual(patcher, userFromJSON)
  }

  func testPatcher_apply_closure() {
    patcher.apply(
      name: { testUser.name = $0 },
      type: { testUser.type = $0 },
      status: { testUser.status = $0 },
      externalId: { testUser.externalId = $0 },
      profileURL: { testUser.profileURL = $0 },
      email: { testUser.email = $0 },
      custom: { testUser.custom = UserCustom(flatJSON: $0?.flatJSON) },
      updated: { testUser.updated = $0 },
      eTag: { testUser.eTag = $0 }
    )

    XCTAssertEqual(testUser, patchedUser)
  }

  func testPatcher_PubNubUser_apply() {
    XCTAssertEqual(testUser.apply(patcher), patchedUser)
  }

  func testPatcher_PubNubUser_applyNoUpdate() {
    let wrongUser = PubNubUser(id: "not-user")

    XCTAssertNotEqual(wrongUser.id, patcher.id)
    XCTAssertEqual(wrongUser.apply(patcher), wrongUser)
  }
}
