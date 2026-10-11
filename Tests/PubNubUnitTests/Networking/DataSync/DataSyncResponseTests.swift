//
//  DataSyncResponseTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncResponseTests: XCTestCase {
  private static func entityJSON(className: String) -> String {
    """
    {
      "id": "alice", "status": "active",
      "entityClass": "\(className)", "entityClassLevel": "SubKey", "entityClassVersion": 1,
      "createdAt": "2021-01-01T00:00:00.000Z", "updatedAt": "2021-01-01T00:00:00.000Z",
      "eTag": "1", "expiresAt": "2027-08-07T00:00:00Z",
      "payload": { "name": "Alice" }
    }
    """
  }

  func test_DecodeSingleResourceEnvelope() throws {
    let json = """
    {
      "data": {
        "id": "alice", "status": "active", "entityClassVersion": 1,
        "createdAt": "2021-01-01T00:00:00.000Z", "updatedAt": "2021-01-01T00:00:00.000Z",
        "eTag": "1", "expiresAt": "2027-08-07T00:00:00Z",
        "payload": { "name": "Alice", "email": "alice@example.com" }
      }
    }
    """

    let response = try Constant.jsonDecoder.decode(
      DataSyncSingleResponse<DataSyncResource>.self,
      from: XCTUnwrap(json.data(using: .utf8))
    )

    XCTAssertEqual(response.data.id, "alice")
    XCTAssertEqual(response.data.status, "active")
    XCTAssertEqual(response.data.entityClassVersion, 1)
    XCTAssertEqual(response.data.eTag, "1")
    XCTAssertEqual(response.data.expiresAt, "2027-08-07T00:00:00Z")
  }

  func test_DecodeListEnvelopeWithMeta() throws {
    let json = """
    {
      "data": [
        { "id": "alice", "entityClassVersion": 1, "eTag": "1", "expiresAt": "2027-08-07T00:00:00Z" }
      ],
      "links": { "self": "/users?limit=20", "next": "/users?cursor=TjIw" },
      "meta": { "has_next": true, "next_cursor": "TjIw", "limit": 20 }
    }
    """

    let response = try Constant.jsonDecoder.decode(
      DataSyncListResponse<DataSyncResource>.self,
      from: XCTUnwrap(json.data(using: .utf8))
    )

    XCTAssertEqual(response.data.count, 1)
    XCTAssertEqual(response.data.first?.id, "alice")
    XCTAssertEqual(response.meta?.nextCursor, "TjIw")
    XCTAssertEqual(response.meta?.hasNext, true)
    XCTAssertEqual(response.meta?.limit, 20)
    XCTAssertEqual(response.links?.next, "/users?cursor=TjIw")
  }

  func test_Page_WithoutMeta_ReportsNilPage() {
    XCTAssertNil(PubNubDataSyncPage(from: nil, requestedLimit: 20))
  }

  func test_Page_WithoutMetaLimit_FallsBackToRequestedLimit() throws {
    let page = try XCTUnwrap(PubNubDataSyncPage(
      from: DataSyncPageMeta(nextCursor: "TjIw", hasNext: true, limit: nil),
      requestedLimit: 50
    ))

    XCTAssertEqual(page.cursor, "TjIw")
    XCTAssertTrue(page.hasNext)
    XCTAssertEqual(page.limit, 50)
  }

  func test_Page_WithoutMetaOrRequestedLimit_KeepsCursorAtTheDefaultLimit() throws {
    let page = try XCTUnwrap(PubNubDataSyncPage(
      from: DataSyncPageMeta(nextCursor: "TjIw", hasNext: true, limit: nil),
      requestedLimit: nil
    ))

    XCTAssertEqual(page.cursor, "TjIw")
    XCTAssertTrue(page.hasNext)
    XCTAssertEqual(page.limit, 20)
  }

  func test_DecodeRelationshipResourceFields() throws {
    let json = """
    {
      "data": {
        "id": "r-123", "entityAId": "u123", "entityBId": "s456",
        "relationshipClass": "ProductOwner", "relationshipClassVersion": 1,
        "status": "active", "eTag": "1", "expiresAt": "2027-08-07T00:00:00Z",
        "payload": { "custom": "fields" }
      }
    }
    """

    let response = try Constant.jsonDecoder.decode(
      DataSyncSingleResponse<DataSyncResource>.self,
      from: XCTUnwrap(json.data(using: .utf8))
    )

    XCTAssertEqual(response.data.id, "r-123")
    XCTAssertEqual(response.data.entityAId, "u123")
    XCTAssertEqual(response.data.entityBId, "s456")
    XCTAssertEqual(response.data.relationshipClass, "ProductOwner")
    XCTAssertEqual(response.data.relationshipClassVersion, 1)
    XCTAssertEqual(response.data.status, "active")
    XCTAssertEqual(response.data.eTag, "1")
    XCTAssertEqual(response.data.payload?["custom"], "fields")
  }

  func test_MembershipRelationship_MapsMembershipEndpointsToRelationshipSides() {
    let date = Date(timeIntervalSince1970: 1)
    let membership = PubNubDataSyncMembership(
      id: "membership",
      channelId: "channel",
      userId: "user",
      className: "Membership",
      classVersion: 1,
      createdAt: date,
      updatedAt: date,
      eTag: "etag",
      expiresAt: date
    )

    XCTAssertEqual(membership.relationship.entityAId, membership.channelId)
    XCTAssertEqual(membership.relationship.entityBId, membership.userId)
    XCTAssertEqual(membership.relationship.id, membership.id)
    XCTAssertEqual(membership.relationship.className, membership.className)
  }

  func test_DecodeUser_MapsEntityWireFields() throws {
    let user = try Constant.jsonDecoder.decode(
      PubNubDataSyncUser.self,
      from: XCTUnwrap(Self.entityJSON(className: "User").data(using: .utf8))
    )

    XCTAssertEqual(user.id, "alice")
    XCTAssertEqual(user.className, "User")
    XCTAssertEqual(user.classLevel, .subKey)
    XCTAssertEqual(user.classVersion, 1)
    XCTAssertEqual(user.eTag, "1")
    XCTAssertEqual(user.status, "active")
    XCTAssertEqual(user.payload?.codableValue["name"], "Alice")
  }

  func test_DecodeChannel_MapsEntityWireFields() throws {
    let channel = try Constant.jsonDecoder.decode(
      PubNubDataSyncChannel.self,
      from: XCTUnwrap(Self.entityJSON(className: "Channel").data(using: .utf8))
    )

    XCTAssertEqual(channel.id, "alice")
    XCTAssertEqual(channel.className, "Channel")
    XCTAssertEqual(channel.classLevel, .subKey)
    XCTAssertEqual(channel.classVersion, 1)
    XCTAssertEqual(channel.eTag, "1")
    XCTAssertEqual(channel.status, "active")
    XCTAssertEqual(channel.payload?.codableValue["name"], "Alice")
  }

  func test_EncodeUser_MatchesEncodedEntity() throws {
    let data = try XCTUnwrap(Self.entityJSON(className: "User").data(using: .utf8))
    let user = try Constant.jsonDecoder.decode(PubNubDataSyncUser.self, from: data)
    let entity = try Constant.jsonDecoder.decode(PubNubDataSyncEntity.self, from: data)

    XCTAssertEqual(
      try Constant.jsonDecoder.decode(AnyJSON.self, from: try Constant.jsonEncoder.encode(user)),
      try Constant.jsonDecoder.decode(AnyJSON.self, from: try Constant.jsonEncoder.encode(entity))
    )
  }

  func test_EncodeChannel_MatchesEncodedEntity() throws {
    let data = try XCTUnwrap(Self.entityJSON(className: "Channel").data(using: .utf8))
    let channel = try Constant.jsonDecoder.decode(PubNubDataSyncChannel.self, from: data)
    let entity = try Constant.jsonDecoder.decode(PubNubDataSyncEntity.self, from: data)

    XCTAssertEqual(
      try Constant.jsonDecoder.decode(AnyJSON.self, from: try Constant.jsonEncoder.encode(channel)),
      try Constant.jsonDecoder.decode(AnyJSON.self, from: try Constant.jsonEncoder.encode(entity))
    )
  }

  func test_DecodeErrorPayloadWithAndWithoutPath() throws {
    let withPath = """
    {
      "errors": [
        { "errorCode": "SYN-0004", "message": "Limit must be between 1 and 100", "path": "limit" }
      ]
    }
    """
    let withoutPath = """
    {
      "errors": [
        { "errorCode": "SYN-0301", "message": "Resource already exists" }
      ]
    }
    """

    let fieldLevel = try Constant.jsonDecoder.decode(
      DataSyncErrorPayload.self,
      from: XCTUnwrap(withPath.data(using: .utf8))
    )

    XCTAssertEqual(fieldLevel.errors.first?.errorCode, "SYN-0004")
    XCTAssertEqual(fieldLevel.errors.first?.path, "limit")

    let resourceLevel = try Constant.jsonDecoder.decode(
      DataSyncErrorPayload.self,
      from: XCTUnwrap(withoutPath.data(using: .utf8))
    )

    XCTAssertEqual(resourceLevel.errors.first?.errorCode, "SYN-0301")
    XCTAssertNil(resourceLevel.errors.first?.path)
  }
}
