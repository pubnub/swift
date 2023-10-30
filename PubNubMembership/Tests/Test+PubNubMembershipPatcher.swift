//
//  Test+PubNubMembershipPatcher.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
@testable import PubNubMembership
import PubNubSpace
import PubNubUser

import XCTest

class PubNubMembershipPatcherTests: XCTestCase {
  var testMembership = PubNubMembership(
    user: PubNubUser(id: "TestUserId"),
    space: PubNubSpace(id: "TestSpaceId"),
    status: "OldStatus",
    custom: MembershipCustom(value: "OldValue"),
    updated: .distantPast,
    eTag: "OldETag"
  )

  var patcher = PubNubMembership.Patcher(
    userId: "TestUserId",
    spaceId: "TestSpaceId",
    updated: .distantFuture,
    eTag: "TestETag",
    status: .some("TestStatus"),
    custom: .some(MembershipCustom(value: "NewValue"))
  )

  let patchedMembership = PubNubMembership(
    user: PubNubUser(id: "TestUserId"),
    space: PubNubSpace(id: "TestSpaceId"),
    status: "TestStatus",
    custom: MembershipCustom(value: "NewValue"),
    updated: .distantFuture,
    eTag: "TestETag"
  )

  func testPatcher_Init() {
    XCTAssertEqual(patcher.userId, "TestUserId")
    XCTAssertEqual(patcher.spaceId, "TestSpaceId")
    XCTAssertEqual(patcher.updated, .distantFuture)
    XCTAssertEqual(patcher.eTag, "TestETag")
    XCTAssertEqual(patcher.status, .some("TestStatus"))
    XCTAssertEqual(
      patcher.custom.underlying?.codableValue, MembershipCustom(value: "NewValue").codableValue
    )
  }

  func testPatcher_Codable_AllNoChange() throws {
    let nonePatcher = PubNubMembership.Patcher(
      userId: "TestUserId",
      spaceId: "TestSpaceId",
      updated: .distantFuture,
      eTag: "TestETag",
      status: .noChange,
      custom: .noChange
    )

    let data = try Constant.jsonEncoder.encode(nonePatcher)
    let membershipFromJSON = try Constant.jsonDecoder
      .decode(PubNubMembership.Patcher.self, from: data)

    XCTAssertEqual(nonePatcher, membershipFromJSON)
  }

  func testPatcher_Decode_AllNone() throws {
    let nonePatcher = PubNubMembership.Patcher(
      userId: "TestUserId",
      spaceId: "TestSpaceId",
      updated: .distantFuture,
      eTag: "TestETag",
      status: .none,
      custom: .none
    )

    let data = try Constant.jsonEncoder.encode(nonePatcher)

    let membershipFromJSON = try Constant.jsonDecoder
      .decode(PubNubMembership.Patcher.self, from: data)

    XCTAssertEqual(nonePatcher, membershipFromJSON)
  }

  func testPatcher_Hasher() {
    var hasher = Hasher()
    hasher.combine(patcher.userId)
    hasher.combine(patcher.spaceId)
    hasher.combine(patcher.status)
    hasher.combine(patcher.custom.underlying?.codableValue)
    hasher.combine(patcher.updated)
    hasher.combine(patcher.eTag)

    XCTAssertEqual(patcher.hashValue, hasher.finalize())
  }

  func testPatcher_ShouldUpdate_True() {
    let shouldUpdate = patcher.shouldUpdate(
      userId: patcher.userId,
      spaceId: patcher.spaceId,
      eTag: UUID().uuidString,
      lastUpdated: .distantPast
    )

    XCTAssertTrue(shouldUpdate)
  }

  func testPatcher_ShouldUpdate_False_NilDate() {
    let shouldUpdate = patcher.shouldUpdate(
      userId: patcher.userId,
      spaceId: patcher.spaceId,
      eTag: UUID().uuidString,
      lastUpdated: nil
    )

    XCTAssertTrue(shouldUpdate)
  }

  func testPatcher_Codable_AllSome() throws {
    let data = try Constant.jsonEncoder.encode(patcher)
    let membershipFromJSON = try? Constant.jsonDecoder
      .decode(PubNubMembership.Patcher.self, from: data)

    XCTAssertEqual(patcher, membershipFromJSON)
  }

  func testPatcher_apply_closure() {
    patcher.apply(
      status: { testMembership.status = $0 },
      custom: { testMembership.custom = MembershipCustom(flatJSON: $0?.flatJSON) },
      updated: { testMembership.updated = $0 },
      eTag: { testMembership.eTag = $0 }
    )

    XCTAssertEqual(testMembership, patchedMembership)
  }

  func testPatcher_PubNubMembership_apply() {
    XCTAssertEqual(testMembership.apply(patcher), patchedMembership)
  }

  func testPatcher_PubNubMembership_applyNoUpdate_wrongUser() {
    let wrongMembership = PubNubMembership(
      user: PubNubUser(id: "not-user-id"),
      space: testMembership.space
    )

    XCTAssertNotEqual(wrongMembership.user.id, patcher.userId)
    XCTAssertEqual(wrongMembership.apply(patcher), wrongMembership)
  }

  func testPatcher_PubNubMembership_applyNoUpdate_wrongSpace() {
    let wrongMembership = PubNubMembership(
      user: testMembership.user,
      space: PubNubSpace(id: "not-space-id")
    )

    XCTAssertNotEqual(wrongMembership.space.id, patcher.spaceId)
    XCTAssertEqual(wrongMembership.apply(patcher), wrongMembership)
  }
}
