//
//  Test+PubNubMembershipPatcher.swift
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

@testable import PubNubMembership
import PubNub
import PubNubUser
import PubNubSpace

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
    user:  PubNubUser(id: "TestUserId"),
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
