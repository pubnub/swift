//
//  DataSyncRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Shared header helpers

enum DataSyncHeader {
  static let ifMatch = "If-Match"
  static let jsonPatchContentType = "application/json-patch+json"

  /// Vendor media type for a resource write body, e.g.
  /// `application/vnd.pubnub.objects.user+json;version=1`.
  static func contentType(resource: String, version: Int = 1) -> String {
    "application/vnd.pubnub.objects.\(resource)+json;version=\(version)"
  }
}

// MARK: - JSON Patch (RFC 6902)

/// A single RFC 6902 JSON Patch operation used by DataSync `PATCH` endpoints.
enum JSONPatchOperation: Encodable, Equatable {
  case add(path: String, value: AnyJSON)
  case remove(path: String)
  case replace(path: String, value: AnyJSON)
  case move(from: String, path: String)
  case copy(from: String, path: String)
  case test(path: String, value: AnyJSON)

  private enum CodingKeys: String, CodingKey {
    case op
    case path
    case value
    case from
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case let .add(path, value):
      try container.encode("add", forKey: .op)
      try container.encode(path, forKey: .path)
      try container.encode(value, forKey: .value)
    case let .remove(path):
      try container.encode("remove", forKey: .op)
      try container.encode(path, forKey: .path)
    case let .replace(path, value):
      try container.encode("replace", forKey: .op)
      try container.encode(path, forKey: .path)
      try container.encode(value, forKey: .value)
    case let .move(from, path):
      try container.encode("move", forKey: .op)
      try container.encode(from, forKey: .from)
      try container.encode(path, forKey: .path)
    case let .copy(from, path):
      try container.encode("copy", forKey: .op)
      try container.encode(from, forKey: .from)
      try container.encode(path, forKey: .path)
    case let .test(path, value):
      try container.encode("test", forKey: .op)
      try container.encode(path, forKey: .path)
      try container.encode(value, forKey: .value)
    }
  }
}

// MARK: - Response envelope models

/// Pagination metadata returned on DataSync list responses.
struct DataSyncPageMeta: Codable, Equatable {
  let nextCursor: String?
  let hasNext: Bool?
  let limit: Int?

  enum CodingKeys: String, CodingKey {
    case nextCursor = "next_cursor"
    case hasNext = "has_next"
    case limit
  }
}

/// Navigation links returned on DataSync list responses.
struct DataSyncLinks: Codable, Equatable {
  let `self`: String?
  let next: String?
}

/// Envelope for a single DataSync resource read/write.
struct DataSyncSingleResponse<Value: Codable>: Codable {
  let data: Value
}

/// Envelope for a paginated DataSync list response.
struct DataSyncListResponse<Value: Codable>: Codable {
  let data: [Value]
  let links: DataSyncLinks?
  let meta: DataSyncPageMeta?
}

/// Envelope for a no-body success response.
struct DataSyncStatusResponse: Codable {
}

// MARK: - Raw resource

struct DataSyncResource: Codable, Equatable {
  let id: String
  let status: String?
  let entityClass: String?
  let entityClassVersion: Int?
  let entityClassLevel: String?
  let relationshipClass: String?
  let relationshipClassVersion: Int?
  let entityAId: String?
  let entityBId: String?
  let channelId: String?
  let userId: String?
  let createdAt: String?
  let updatedAt: String?
  let eTag: String?
  let expiresAt: String?
  let payload: AnyJSON?
}

// MARK: - Response decoders

struct DataSyncSingleValueResponseDecoder<Value: Codable>: ResponseDecoder {
  typealias Payload = DataSyncSingleResponse<Value>
}

struct DataSyncListValueResponseDecoder<Value: Codable>: ResponseDecoder {
  typealias Payload = DataSyncListResponse<Value>
}

struct DataSyncStatusResponseDecoder: ResponseDecoder {
  typealias Payload = DataSyncStatusResponse

  func decode(
    response: EndpointResponse<Data>
  ) -> Result<EndpointResponse<Payload>, Error> {
    .success(
      EndpointResponse<Payload>(
        router: response.router,
        request: response.request,
        response: response.response,
        data: response.data,
        payload: DataSyncStatusResponse()
      )
    )
  }
}
