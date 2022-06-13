//
//  Test+PubNubMembership.swift
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

class PubNubMembershipModelTests: XCTestCase {

  let testMembership = PubNubMembership(
    user: PubNubUser(id: "TestUserId"),
    space: PubNubSpace(id: "TestSpaceId"),
    status: "TestStatus",
    custom: MembershipCustom(value: "Tester"),
    updated: Date.distantPast,
    eTag: "TestETag"
  )
  
  let membershipJSON = """
{
  "uuid": {"id": "TestUserId"},
  "channel": {"id": "TestSpaceId"},
  "status": "TestStatus",
  "custom": {"value": "Tester"},
  "updated": "0001-01-01T00:00:00.000Z",
  "eTag": "TestETag"
}
"""
  
  func testPubNubMembership_Codable() throws {
    let data = try Constant.jsonEncoder.encode(testMembership)
    let userFromJSON = try Constant.jsonDecoder.decode(PubNubMembership.self, from: data)
    
    XCTAssertEqual(testMembership, userFromJSON)
  }
  
  func testPubNubMembership_FromJSON() throws {
    guard let data = membershipJSON.data(using: .utf8) else {
      XCTFail("Could not encode data")
      return
    }
    
    let userFromJSON = try Constant.jsonDecoder.decode(PubNubMembership.self, from: data)
    
    XCTAssertEqual(testMembership, userFromJSON)
  }
  
  func testPubNubMembership_Init() {
    let testMembership = PubNubMembership(
      user: PubNubUser(id: "TestUserId"),
      space: PubNubSpace(id: "TestSpaceId"),
      status: "TestStatus",
      custom: MembershipCustom(value: "Tester"),
      updated: Date.distantPast,
      eTag: "TestETag"
    )
    
    XCTAssertEqual("TestUserId", testMembership.user.id)
    XCTAssertEqual("TestSpaceId", testMembership.space.id)
    XCTAssertEqual("TestStatus", testMembership.status)
    XCTAssertTrue(MembershipCustom(value: "Tester").codableValue == testMembership.custom?.codableValue)
    XCTAssertEqual(Date.distantPast, testMembership.updated)
    XCTAssertEqual("TestETag", testMembership.eTag)
  }
  
  func testPubNubMembership_Hasher() {
    var hasher = Hasher()
    hasher.combine(testMembership.user)
    hasher.combine(testMembership.space)
    hasher.combine(testMembership.status)
    hasher.combine(testMembership.custom?.codableValue)
    hasher.combine(testMembership.updated)
    hasher.combine(testMembership.eTag)
    
    XCTAssertEqual(testMembership.hashValue, hasher.finalize())
  }
  
  func testPubNubMembership_Convert_MembershipMetadata() {
    let membershipMetadata = PubNubMembershipMetadataBase(
      uuidMetadataId: testMembership.user.id,
      channelMetadataId: testMembership.space.id,
      status: testMembership.status,
      custom: testMembership.custom?.flatJSON,
      updated: testMembership.updated,
      eTag: testMembership.eTag
    )
    
    XCTAssertEqual(testMembership, membershipMetadata.convert())
  }
  
  func testPubNubMembership_Convert_MembershipMetadata_nilCustom() {
    let membershipMetadata = PubNubMembershipMetadataBase(
      uuidMetadataId: testMembership.user.id,
      channelMetadataId: testMembership.space.id,
      status: testMembership.status,
      custom: nil,
      updated: testMembership.updated,
      eTag: testMembership.eTag
    )
    var testMembership = testMembership
    testMembership.custom = nil
    
    XCTAssertEqual(testMembership, membershipMetadata.convert())
  }

  // MARK: Partial User

  func testPubNubMembership_PartialUser_InitUser() {
    let partialUser = PubNubMembership.PartialUser(
      user: testMembership.user,
      status: testMembership.status,
      custom: testMembership.custom
    )

    XCTAssertEqual(partialUser.user, testMembership.user)
    XCTAssertEqual(partialUser.status, testMembership.status)
    XCTAssertEqual(partialUser.custom?.codableValue, testMembership.custom?.codableValue)
    XCTAssertNil(partialUser.updated)
    XCTAssertNil(partialUser.eTag)
  }

  func testPubNubMembership_PartialUser_InitUserId() {
    let partialUser = PubNubMembership.PartialUser(
      userId: testMembership.user.id,
      status: testMembership.status,
      custom: testMembership.custom
    )
    
    XCTAssertEqual(partialUser.user, testMembership.user)
    XCTAssertEqual(partialUser.status, testMembership.status)
    XCTAssertEqual(partialUser.custom?.codableValue, testMembership.custom?.codableValue)
    XCTAssertNil(partialUser.updated)
    XCTAssertNil(partialUser.eTag)
  }

  func testPubNubMembership_PartialUser_Codable() throws {
    let partialUser = PubNubMembership.PartialUser(
      user: testMembership.user,
      status: testMembership.status,
      custom: testMembership.custom,
      updated: testMembership.updated,
      eTag: testMembership.eTag
    )
    
    let data = try Constant.jsonEncoder.encode(partialUser)
    let decodedPartial = try Constant.jsonDecoder
      .decode(PubNubMembership.PartialUser.self, from: data)

    XCTAssertEqual(partialUser, decodedPartial)
  }

  func testPubNubMembership_PartialUser_Hasher() {
    let partialUser = PubNubMembership.PartialUser(
      user: testMembership.user,
      status: testMembership.status,
      custom: testMembership.custom,
      updated: testMembership.updated,
      eTag: testMembership.eTag
    )
    
    var hasher = Hasher()
    hasher.combine(partialUser.user)
    hasher.combine(partialUser.status)
    hasher.combine(partialUser.custom?.codableValue)
    hasher.combine(partialUser.updated)
    hasher.combine(partialUser.eTag)
    
    XCTAssertEqual(partialUser.hashValue, hasher.finalize())
  }

  func testPubNubMembership_Init_PartialUser() {
    let partialUser = PubNubMembership.PartialUser(
      user: testMembership.user,
      status: testMembership.status,
      custom: testMembership.custom,
      updated: testMembership.updated,
      eTag: testMembership.eTag
    )
    
    let membership = PubNubMembership(space: testMembership.space, user: partialUser)
    
    XCTAssertEqual(membership, testMembership)
  }

  // MARK: Partial Space

  func testPubNubMembership_PartialSpace_InitSpace() {
    let partialSpace = PubNubMembership.PartialSpace(
      space: testMembership.space,
      status: testMembership.status,
      custom: testMembership.custom
    )
    
    XCTAssertEqual(partialSpace.space, testMembership.space)
    XCTAssertEqual(partialSpace.status, testMembership.status)
    XCTAssertEqual(partialSpace.custom?.codableValue, testMembership.custom?.codableValue)
    XCTAssertNil(partialSpace.updated)
    XCTAssertNil(partialSpace.eTag)
  }
  
  func testPubNubMembership_PartialSpace_InitSpaceId() {
    let partialSpace = PubNubMembership.PartialSpace(
      spaceId: testMembership.space.id,
      status: testMembership.status,
      custom: testMembership.custom
    )
    
    XCTAssertEqual(partialSpace.space, testMembership.space)
    XCTAssertEqual(partialSpace.status, testMembership.status)
    XCTAssertEqual(partialSpace.custom?.codableValue, testMembership.custom?.codableValue)
    XCTAssertNil(partialSpace.updated)
    XCTAssertNil(partialSpace.eTag)
  }

  func testPubNubMembership_PartialSpace_Codable() throws {
    let partialSpace = PubNubMembership.PartialSpace(
      space: testMembership.space,
      status: testMembership.status,
      custom: testMembership.custom,
      updated: testMembership.updated,
      eTag: testMembership.eTag
    )
    
    let data = try Constant.jsonEncoder.encode(partialSpace)
    let decodedPartial = try Constant.jsonDecoder
      .decode(PubNubMembership.PartialSpace.self, from: data)
    
    XCTAssertEqual(partialSpace, decodedPartial)
  }
  
  func testPubNubMembership_PartialSpace_Hasher() {
    let partialSpace = PubNubMembership.PartialSpace(
      space: testMembership.space,
      status: testMembership.status,
      custom: testMembership.custom,
      updated: testMembership.updated,
      eTag: testMembership.eTag
    )
    
    var hasher = Hasher()
    hasher.combine(partialSpace.space)
    hasher.combine(partialSpace.status)
    hasher.combine(partialSpace.custom?.codableValue)
    hasher.combine(partialSpace.updated)
    hasher.combine(partialSpace.eTag)
    
    XCTAssertEqual(partialSpace.hashValue, hasher.finalize())
  }

  func testPubNubMembership_Init_PartialSpace() {
    let partialSpace = PubNubMembership.PartialSpace(
      space: testMembership.space,
      status: testMembership.status,
      custom: testMembership.custom,
      updated: testMembership.updated,
      eTag: testMembership.eTag
    )

    let membership = PubNubMembership(user: testMembership.user, space: partialSpace)

    XCTAssertEqual(membership, testMembership)
  }
}
