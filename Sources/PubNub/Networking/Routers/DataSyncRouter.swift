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
enum JSONPatchOperation: Encodable {
  case add(path: String, value: JSONCodable)
  case remove(path: String)
  case replace(path: String, value: JSONCodable)
  case move(from: String, path: String)
  case copy(from: String, path: String)
  case test(path: String, value: JSONCodable)

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

// MARK: - Request envelope

/// Wraps a create/replace request body in the `{ "data": ... }`
struct DataSyncRequestEnvelope<Value: Encodable>: Encodable {
  let data: Value
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

// MARK: - Error envelope

/// A single failure entry in a DataSync error response.
struct DataSyncErrorItem: Codable, Equatable {
  /// An opaque service error code.
  let errorCode: String
  /// A human-readable error message.
  let message: String
  /// The offending field, if any: an RFC 6901 JSON Pointer for a request-body failure, or the bare parameter name for a query-parameter failure.
  let path: String?
}

/// The DataSync v4 error envelope, which differs from ``GenericServicePayloadResponse``.
struct DataSyncErrorPayload: Codable, Equatable {
  let errors: [DataSyncErrorItem]
}

/// A router for the DataSync v4 data plane, which returns an error envelope distinct from ``GenericServicePayloadResponse``.
protocol DataSyncRouting: HTTPRouter {}

/// Decodes the DataSync v4 error envelope, falling back to the default decoding when the body isn't one.
extension DataSyncRouting {
  func decodeError(request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError? {
    guard let payload = try? Constant.jsonDecoder.decode(DataSyncErrorPayload.self, from: data), !payload.errors.isEmpty else {
      return AnyJSONResponseDecoder().decodeDefaultError(
        router: self, request: request, response: response, for: data
      )
    }

    return PubNubError(
      reason: nil,
      router: self,
      request: request,
      response: response,
      additional: payload.errors.map {
        ErrorDetail(
          message: $0.message,
          location: $0.path ?? "",
          locationType: $0.errorCode
        )
      }
    )
  }
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
