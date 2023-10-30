//
//  Test+PubNubUser.swift
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

class PubNubUserModelTests: XCTestCase {
  let testUser = PubNubUser(
    id: "TestUserId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    externalId: "TestExternalID",
    profileURL: URL(string: "http://example.com"),
    email: "TestEmail",
    custom: UserCustom(value: "Tester"),
    updated: Date.distantPast,
    eTag: "TestETag"
  )

  let userJSON = """
  {
    "id": "TestUserId",
    "name": "TestName",
    "type": "TestType",
    "status": "TestStatus",
    "externalId": "TestExternalID",
    "profileUrl": "http://example.com",
    "email": "TestEmail",
    "custom": {"value": "Tester"},
    "updated": "0001-01-01T00:00:00.000Z",
    "eTag": "TestETag"
  }
  """

  func testPubNubUser_Codable() throws {
    let data = try Constant.jsonEncoder.encode(testUser)
    let userFromJSON = try Constant.jsonDecoder.decode(PubNubUser.self, from: data)

    XCTAssertEqual(testUser, userFromJSON)
  }

  func testPubNubUser_FromJSON() throws {
    guard let data = userJSON.data(using: .utf8) else {
      XCTFail("Could not encode data")
      return
    }

    let userFromJSON = try Constant.jsonDecoder.decode(PubNubUser.self, from: data)

    XCTAssertEqual(testUser, userFromJSON)
  }

  func testPubNubUser_Init() {
    let testUser = PubNubUser(
      id: "TestUserId",
      name: "TestName",
      type: "TestType",
      status: "TestStatus",
      externalId: "TestExternalID",
      profileURL: URL(string: "http://example.com"),
      email: "TestEmail",
      custom: UserCustom(value: "Tester"),
      updated: Date.distantPast,
      eTag: "TestETag"
    )

    XCTAssertEqual("TestUserId", testUser.id)
    XCTAssertEqual("TestName", testUser.name)
    XCTAssertEqual("TestType", testUser.type)
    XCTAssertEqual("TestStatus", testUser.status)
    XCTAssertEqual("TestExternalID", testUser.externalId)
    XCTAssertEqual(URL(string: "http://example.com"), testUser.profileURL)
    XCTAssertEqual("TestEmail", testUser.email)
    XCTAssertTrue(UserCustom(value: "Tester").codableValue == testUser.custom?.codableValue)
    XCTAssertEqual(Date.distantPast, testUser.updated)
    XCTAssertEqual("TestETag", testUser.eTag)
  }

  func testPubNubUser_Hasher() {
    var hasher = Hasher()
    hasher.combine(testUser.id)
    hasher.combine(testUser.name)
    hasher.combine(testUser.type)
    hasher.combine(testUser.status)
    hasher.combine(testUser.externalId)
    hasher.combine(testUser.profileURL)
    hasher.combine(testUser.email)
    hasher.combine(testUser.custom?.codableValue)
    hasher.combine(testUser.updated)
    hasher.combine(testUser.eTag)

    XCTAssertEqual(testUser.hashValue, hasher.finalize())
  }

  func testPubNubUser_Convert_UUIDMetadata() {
    let userMetadata = PubNubUUIDMetadataBase(
      metadataId: testUser.id,
      name: testUser.name,
      type: testUser.type,
      status: testUser.status,
      externalId: testUser.externalId,
      profileURL: testUser.profileURL?.absoluteString,
      email: testUser.email,
      custom: testUser.custom?.flatJSON,
      updated: testUser.updated,
      eTag: testUser.eTag
    )

    XCTAssertEqual(testUser, userMetadata.convert())
  }

  func testPubNubUser_Convert_UUIDMetadata_nilProfileUrl() {
    let userMetadata = PubNubUUIDMetadataBase(
      metadataId: testUser.id,
      name: testUser.name,
      type: testUser.type,
      status: testUser.status,
      externalId: testUser.externalId,
      profileURL: nil,
      email: testUser.email,
      custom: testUser.custom?.flatJSON,
      updated: testUser.updated,
      eTag: testUser.eTag
    )

    var testUser = testUser
    testUser.profileURL = nil

    XCTAssertEqual(testUser, userMetadata.convert())
  }

  func testPubNubUser_Convert_UUIDMetadata_nilCustom() {
    let userMetadata = PubNubUUIDMetadataBase(
      metadataId: testUser.id,
      name: testUser.name,
      type: testUser.type,
      status: testUser.status,
      externalId: testUser.externalId,
      profileURL: testUser.profileURL?.absoluteString,
      email: testUser.email,
      custom: nil,
      updated: testUser.updated,
      eTag: testUser.eTag
    )
    var testUser = testUser
    testUser.custom = nil

    XCTAssertEqual(testUser, userMetadata.convert())
  }
}
