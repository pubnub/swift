//
//  DataSyncRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class DataSyncRouterTests: XCTestCase {
  let config = TestPubNubFactory.makeConfig(subscribeKey: "demo-sub")

  private func queryValue(_ router: HTTPRouter, _ key: String) throws -> String? {
    try router.queryItems.get().first { $0.name == key }?.value
  }

  private func queryNames(_ router: HTTPRouter) throws -> Set<String> {
    Set(try router.queryItems.get().map { $0.name })
  }

  private func decodeBody(_ router: HTTPRouter) throws -> AnyJSON {
    let request = try router.asURLRequest.get()
    let body = try XCTUnwrap(request.httpBody)

    return try Constant.jsonDecoder.decode(AnyJSON.self, from: body)
  }

  private func decodeBodyArray(_ router: HTTPRouter) throws -> [AnyJSON] {
    let request = try router.asURLRequest.get()
    let body = try XCTUnwrap(request.httpBody)

    return try Constant.jsonDecoder.decode([AnyJSON].self, from: body)
  }
}

// MARK: - Users: List

extension DataSyncRouterTests {
  func test_UserList_AllQueryItems() throws {
    let endpoint = DataSyncUserRouter.Endpoint.all(
      entityClassVersion: 2, cursor: "TjIw", limit: 25,
      filter: "status=='active'", filterAdvanced: "a AND b", sort: "+name"
    )
    let router = DataSyncUserRouter(
      endpoint,
      configuration: config
    )

    XCTAssertEqual(router.service, .dataSync)
    XCTAssertEqual(router.pamVersion, .version3)
    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/users")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(try queryValue(router, "entity_class_version"), "2")
    XCTAssertEqual(try queryValue(router, "cursor"), "TjIw")
    XCTAssertEqual(try queryValue(router, "limit"), "25")
    XCTAssertEqual(try queryValue(router, "filter"), "status=='active'")
    XCTAssertEqual(try queryValue(router, "filter_advanced"), "a AND b")
    XCTAssertEqual(try queryValue(router, "sort"), "+name")
  }

  func test_UserList_OmitsNilQueryItems() throws {
    let endpoint = DataSyncUserRouter.Endpoint.all(
      entityClassVersion: nil, cursor: nil, limit: nil,
      filter: nil, filterAdvanced: nil, sort: nil
    )
    let router = DataSyncUserRouter(
      endpoint,
      configuration: config
    )

    let names = try queryNames(router)

    XCTAssertFalse(names.contains("entity_class_version"))
    XCTAssertFalse(names.contains("cursor"))
    XCTAssertFalse(names.contains("limit"))
    XCTAssertFalse(names.contains("filter"))
    XCTAssertFalse(names.contains("filter_advanced"))
    XCTAssertFalse(names.contains("sort"))
  }
}

// MARK: - Users: Fetch

extension DataSyncRouterTests {
  func test_UserFetch_Endpoint() throws {
    let router = DataSyncUserRouter(.fetch(id: "alice"), configuration: config)
    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/users/alice")
    XCTAssertNil(router.validationError)
    XCTAssertNil(request.httpBody)
    XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
  }

  func test_UserFetch_EmptyIdFailsValidation() throws {
    let router = DataSyncUserRouter(.fetch(id: ""), configuration: config)

    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyDataSyncId)
  }

  func test_UserFetch_EncodesSlashInId() throws {
    let router = DataSyncUserRouter(.fetch(id: "a/b"), configuration: config)

    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/users/a%2Fb")
  }
}

// MARK: - Users: Create

extension DataSyncRouterTests {
  func test_UserCreate_Endpoint() throws {
    let router = DataSyncUserRouter(
      .create(body: .init(id: "alice", entityClassVersion: 1, payload: ["name": "Alice"])),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .post)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/users")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/vnd.pubnub.objects.user+json;version=1")

    let body = try decodeBody(router)

    XCTAssertEqual(body["id"]?.stringOptional, "alice")
    XCTAssertEqual(body["entityClassVersion"]?.intOptional, 1)
    XCTAssertEqual(body["payload"]?["name"]?.stringOptional, "Alice")
  }
}

// MARK: - Users: Replace

extension DataSyncRouterTests {
  func test_UserReplace_Endpoint() throws {
    let router = DataSyncUserRouter(
      .replace(id: "alice", body: .init(entityClassVersion: 1), ifMatch: "\"5\""),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .put)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/users/alice")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/vnd.pubnub.objects.user+json;version=1")
    XCTAssertEqual(request.value(forHTTPHeaderField: "If-Match"), "\"5\"")

    let body = try decodeBody(router)
    XCTAssertEqual(body["entityClassVersion"]?.intOptional, 1)
  }

  func test_UserReplace_EmptyIdFailsValidation() throws {
    let router = DataSyncUserRouter(
      .replace(id: "", body: .init(entityClassVersion: 1), ifMatch: nil),
      configuration: config
    )

    XCTAssertEqual(router.method, .put)
    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyDataSyncId)
  }
}

// MARK: - Users: Patch

extension DataSyncRouterTests {
  func test_UserPatch_Endpoint() throws {
    let ops: [JSONPatchOperation] = [
      .replace(path: "/payload/profileUrl", value: "https://x")
    ]
    let router = DataSyncUserRouter(
      .patch(id: "alice", operations: ops, ifMatch: "\"2\""),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .patch)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/users/alice")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json-patch+json")
    XCTAssertEqual(request.value(forHTTPHeaderField: "If-Match"), "\"2\"")

    let encodedOps = try decodeBodyArray(router)

    XCTAssertEqual(encodedOps.count, 1)
    XCTAssertEqual(encodedOps.first?["op"]?.stringOptional, "replace")
    XCTAssertEqual(encodedOps.first?["path"]?.stringOptional, "/payload/profileUrl")
    XCTAssertEqual(encodedOps.first?["value"]?.stringOptional, "https://x")
  }

  func test_UserPatch_EmptyOperationsFailsValidation() throws {
    let router = DataSyncUserRouter(.patch(id: "alice", operations: [], ifMatch: nil), configuration: config)

    XCTAssertEqual(router.method, .patch)
    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyPatchOperations)
  }
}

// MARK: - Users: Remove

extension DataSyncRouterTests {
  func test_UserRemove_Endpoint() throws {
    let router = DataSyncUserRouter(.remove(id: "alice", ifMatch: "\"9\""), configuration: config)
    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .delete)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/users/alice")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(request.value(forHTTPHeaderField: "If-Match"), "\"9\"")
    XCTAssertNil(request.httpBody)
  }

  func test_UserRemove_OmitsIfMatchWhenNil() throws {
    let router = DataSyncUserRouter(.remove(id: "alice", ifMatch: nil), configuration: config)
    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .delete)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/users/alice")
    XCTAssertNil(router.validationError)
    XCTAssertNil(request.value(forHTTPHeaderField: "If-Match"))
  }
}

// MARK: - JSONPatchOperation encoding

extension DataSyncRouterTests {
  private func encode(_ op: JSONPatchOperation) throws -> AnyJSON {
    let data = try Constant.jsonEncoder.encode([op])
    let array = try Constant.jsonDecoder.decode([AnyJSON].self, from: data)

    return try XCTUnwrap(array.first)
  }

  func test_JSONPatch_Add() throws {
    let json = try encode(.add(path: "/payload/a", value: 1))

    XCTAssertEqual(json["op"]?.stringOptional, "add")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["value"]?.intOptional, 1)
    XCTAssertNil(json["from"])
  }

  func test_JSONPatch_Remove() throws {
    let json = try encode(.remove(path: "/payload/a"))

    XCTAssertEqual(json["op"]?.stringOptional, "remove")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/a")
    XCTAssertNil(json["value"])
    XCTAssertNil(json["from"])
  }

  func test_JSONPatch_Replace() throws {
    let json = try encode(.replace(path: "/payload/a", value: "x"))

    XCTAssertEqual(json["op"]?.stringOptional, "replace")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["value"]?.stringOptional, "x")
    XCTAssertNil(json["from"])
  }

  func test_JSONPatch_Move() throws {
    let json = try encode(.move(from: "/payload/a", path: "/payload/b"))

    XCTAssertEqual(json["op"]?.stringOptional, "move")
    XCTAssertEqual(json["from"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/b")
    XCTAssertNil(json["value"])
  }

  func test_JSONPatch_Copy() throws {
    let json = try encode(.copy(from: "/payload/a", path: "/payload/b"))

    XCTAssertEqual(json["op"]?.stringOptional, "copy")
    XCTAssertEqual(json["from"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/b")
    XCTAssertNil(json["value"])
  }

  func test_JSONPatch_Test() throws {
    let json = try encode(.test(path: "/payload/a", value: true))

    XCTAssertEqual(json["op"]?.stringOptional, "test")
    XCTAssertEqual(json["path"]?.stringOptional, "/payload/a")
    XCTAssertEqual(json["value"]?.boolOptional, true)
    XCTAssertNil(json["from"])
  }
}

// MARK: - Channels

extension DataSyncRouterTests {
  func test_ChannelFetch_Endpoint() throws {
    let router = DataSyncChannelRouter(.fetch(id: "general"), configuration: config)

    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/channels/general")
    XCTAssertNil(router.validationError)
  }

  func test_ChannelCreate_SetsVendorContentType() throws {
    let router = DataSyncChannelRouter(
      .create(body: .init(entityClassVersion: 1)),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .post)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/channels")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/vnd.pubnub.objects.channel+json;version=1")
  }

  func test_ChannelReplace_SetsVendorContentTypeAndIfMatch() throws {
    let router = DataSyncChannelRouter(
      .replace(id: "general", body: .init(entityClassVersion: 1), ifMatch: "\"5\""),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .put)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/channels/general")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/vnd.pubnub.objects.channel+json;version=1")
    XCTAssertEqual(request.value(forHTTPHeaderField: "If-Match"), "\"5\"")
  }

  func test_ChannelPatch_SetsJsonPatchContentType() throws {
    let router = DataSyncChannelRouter(
      .patch(id: "general", operations: [.remove(path: "/payload/x")], ifMatch: "\"3\""),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .patch)
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json-patch+json")
    XCTAssertEqual(request.value(forHTTPHeaderField: "If-Match"), "\"3\"")
  }

  func test_ChannelRemove_OmitsIfMatchWhenNil() throws {
    let router = DataSyncChannelRouter(.remove(id: "general", ifMatch: nil), configuration: config)
    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .delete)
    XCTAssertNil(request.value(forHTTPHeaderField: "If-Match"))
    XCTAssertNil(request.httpBody)
  }
}

// MARK: - Memberships

extension DataSyncRouterTests {
  func test_MembershipFetch_Endpoint() throws {
    let router = DataSyncMembershipRouter(.fetch(id: "m-1"), configuration: config)

    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/memberships/m-1")
    XCTAssertNil(router.validationError)
  }

  func test_MembershipList_FilterQueryItems() throws {
    let endpoint = DataSyncMembershipRouter.Endpoint.all(
      userId: "alice", channelId: "general", relationshipClassVersion: 1,
      cursor: nil, limit: nil, filter: nil, filterAdvanced: nil, sort: nil
    )

    let router = DataSyncMembershipRouter(endpoint, configuration: config)

    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/memberships")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(try queryValue(router, "user_id"), "alice")
    XCTAssertEqual(try queryValue(router, "channel_id"), "general")
    XCTAssertEqual(try queryValue(router, "relationship_class_version"), "1")

    let names = try queryNames(router)

    XCTAssertFalse(names.contains("cursor"))
    XCTAssertFalse(names.contains("limit"))
    XCTAssertFalse(names.contains("filter"))
    XCTAssertFalse(names.contains("filter_advanced"))
    XCTAssertFalse(names.contains("sort"))
  }

  func test_MembershipCreate_SetsVendorContentType() throws {
    let endpoint = DataSyncMembershipRouter.Endpoint.create(
      body: .init(
        channelId: "general",
        userId: "alice",
        relationshipClassVersion: 1
      )
    )

    let router = DataSyncMembershipRouter(endpoint, configuration: config)
    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .post)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/memberships")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/vnd.pubnub.objects.membership+json;version=1")

    let body = try decodeBody(router)

    XCTAssertEqual(body["channelId"]?.stringOptional, "general")
    XCTAssertEqual(body["userId"]?.stringOptional, "alice")
    XCTAssertEqual(body["relationshipClassVersion"]?.intOptional, 1)
  }

  func test_MembershipCreate_EmptyChannelIdFailsValidation() throws {
    let router = DataSyncMembershipRouter(
      .create(body: .init(channelId: "", userId: "alice", relationshipClassVersion: 1)),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyMembershipChannelId)
  }

  func test_MembershipCreate_EmptyUserIdFailsValidation() throws {
    let router = DataSyncMembershipRouter(
      .create(body: .init(channelId: "general", userId: "", relationshipClassVersion: 1)),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyMembershipUserId)
  }
}

// MARK: - Entities

extension DataSyncRouterTests {
  func test_EntityFetch_Endpoint() throws {
    let router = DataSyncEntityRouter(.fetch(id: "i789"), configuration: config)

    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/entities/i789")
    XCTAssertNil(router.validationError)
  }

  func test_EntityList_RequiresEntityClassQueryItem() throws {
    let router = DataSyncEntityRouter(
      .all(entityClass: "user", entityClassVersion: nil, cursor: nil, limit: nil, filter: nil, filterAdvanced: nil, sort: nil),
      configuration: config
    )

    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/entities")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(try queryValue(router, "entity_class"), "user")
  }

  func test_EntityList_MissingEntityClassFailsValidation() throws {
    let router = DataSyncEntityRouter(
      .all(entityClass: "", entityClassVersion: nil, cursor: nil, limit: nil, filter: nil, filterAdvanced: nil, sort: nil),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyEntityClass)
  }

  func test_EntityCreate_SetsVendorContentType() throws {
    let router = DataSyncEntityRouter(
      .create(body: .init(entityClass: "user", entityClassVersion: 1)),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .post)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/entities")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/vnd.pubnub.objects.entity+json;version=1")

    let body = try decodeBody(router)

    XCTAssertEqual(body["entityClass"]?.stringOptional, "user")
    XCTAssertEqual(body["entityClassVersion"]?.intOptional, 1)
  }

  func test_EntityCreate_EmptyEntityClassFailsValidation() throws {
    let router = DataSyncEntityRouter(
      .create(body: .init(entityClass: "", entityClassVersion: 1)),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyEntityClass)
  }
}

// MARK: - Relationships

extension DataSyncRouterTests {
  func test_RelationshipFetch_Endpoint() throws {
    let router = DataSyncRelationshipRouter(.fetch(id: "r-1"), configuration: config)

    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/relationships/r-1")
    XCTAssertNil(router.validationError)
  }

  func test_RelationshipList_FilterQueryItems() throws {
    let router = DataSyncRelationshipRouter(
      .all(
        relationshipClass: "ProductOwner", entityAId: "u123", entityBId: "s456",
        relationshipClassVersion: nil, cursor: nil, limit: nil, filter: nil, filterAdvanced: nil, sort: nil
      ),
      configuration: config
    )

    XCTAssertEqual(router.method, .get)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/relationships")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(try queryValue(router, "relationship_class"), "ProductOwner")
    XCTAssertEqual(try queryValue(router, "entity_a_id"), "u123")
    XCTAssertEqual(try queryValue(router, "entity_b_id"), "s456")
  }

  func test_RelationshipList_MissingClassFailsValidation() throws {
    let router = DataSyncRelationshipRouter(
      .all(
        relationshipClass: "", entityAId: nil, entityBId: nil, relationshipClassVersion: nil,
        cursor: nil, limit: nil, filter: nil, filterAdvanced: nil, sort: nil
      ),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyRelationshipClass)
  }

  func test_RelationshipCreate_SetsVendorContentType() throws {
    let router = DataSyncRelationshipRouter(
      .create(
        body: .init(
          entityAId: "u123",
          entityBId: "s456",
          relationshipClass: "ProductOwner",
          relationshipClassVersion: 1
        )
      ),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(router.method, .post)
    XCTAssertEqual(try router.path.get(), "/v1/datasync/subkeys/demo-sub/relationships")
    XCTAssertNil(router.validationError)
    XCTAssertEqual(
      request.value(forHTTPHeaderField: "Content-Type"),
       "application/vnd.pubnub.objects.relationship+json;version=1"
    )

    let body = try decodeBody(router)

    XCTAssertEqual(body["entityAId"]?.stringOptional, "u123")
    XCTAssertEqual(body["entityBId"]?.stringOptional, "s456")
    XCTAssertEqual(body["relationshipClass"]?.stringOptional, "ProductOwner")
    XCTAssertEqual(body["relationshipClassVersion"]?.intOptional, 1)
  }

  func test_RelationshipCreate_EmptyEntityAIdFailsValidation() throws {
    let router = DataSyncRelationshipRouter(
      .create(body: .init(
        entityAId: "", entityBId: "s456", relationshipClass: "ProductOwner", relationshipClassVersion: 1
      )),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyRelationshipEntityAId)
  }

  func test_RelationshipCreate_EmptyEntityBIdFailsValidation() throws {
    let router = DataSyncRelationshipRouter(
      .create(body: .init(
        entityAId: "u123", entityBId: "", relationshipClass: "ProductOwner", relationshipClassVersion: 1
      )),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyRelationshipEntityBId)
  }

  func test_RelationshipCreate_EmptyClassFailsValidation() throws {
    let router = DataSyncRelationshipRouter(
      .create(body: .init(
        entityAId: "u123", entityBId: "s456", relationshipClass: "", relationshipClassVersion: 1
      )),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.reason, .missingRequiredParameter)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyRelationshipClass)
  }
}

// MARK: - Response Decoders

extension DataSyncRouterTests {
  func test_DecodeSingleResourceEnvelope() throws {
    let json = """
    {
      "data": {
        "id": "alice", "status": "active", "entityClassVersion": 1,
        "createdAt": "2021-01-01T00:00:00.000Z", "updatedAt": "2021-01-01T00:00:00.000Z",
        "eTag": "1", "payload": { "name": "Alice", "email": "alice@example.com" }
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
  }

  func test_DecodeListEnvelopeWithMeta() throws {
    let json = """
    {
      "data": [
        { "id": "alice", "entityClassVersion": 1, "eTag": "1" }
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

  func test_DecodeRelationshipResourceFields() throws {
    let json = """
    {
      "data": {
        "id": "r-123", "entityAId": "u123", "entityBId": "s456",
        "relationshipClass": "ProductOwner", "relationshipClassVersion": 1,
        "status": "active", "eTag": "1", "payload": { "custom": "fields" }
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
}

// MARK: - asURLRequest Content-Type regression

extension DataSyncRouterTests {
  func test_RouterSuppliedContentTypeSurvivesWithBody() throws {
    // A router with an explicit Content-Type should not be overridden by the default.
    let router = DataSyncUserRouter(
      .create(body: .init(entityClassVersion: 1)),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(
      request.value(forHTTPHeaderField: "Content-Type"),
       "application/vnd.pubnub.objects.user+json;version=1"
    )
    XCTAssertNotEqual(
      request.value(forHTTPHeaderField: "Content-Type"),
      Constant.defaultContentTypeHeader
    )
  }

  func test_DefaultContentTypeStillAppliedWhenRouterSuppliesNone() throws {
    // A router with a body but no explicit Content-Type still gets the default.
    let router = PublishRouter(
      PublishRouter.Endpoint.compressedPublish(
        message: ["msg"],
        channel: "c",
        customMessageType: nil,
        shouldStore: nil,
        ttl: nil,
        meta: nil
      ),
      configuration: config
    )

    let request = try router.asURLRequest.get()

    XCTAssertEqual(
      request.value(forHTTPHeaderField: "Content-Type"),
      Constant.defaultContentTypeHeader
    )
  }
}
