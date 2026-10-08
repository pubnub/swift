//
//  DataSyncRelationshipRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

struct DataSyncRelationshipRouter: DataSyncRouting {
  enum Endpoint: CustomStringConvertible {
    case all(
      relationshipClass: String, entityAId: String?, entityBId: String?,
      relationshipClassVersion: Int?, cursor: String?, limit: Int?,
      filterFast: String?, filter: String?, sort: String?
    )
    case fetch(id: String)
    case create(body: CreateBody)
    case replace(id: String, body: ReplaceBody, ifMatch: String?)
    case patch(id: String, operations: [JSONPatchOperation], ifMatch: String?)
    case remove(id: String, ifMatch: String?)

    var description: String {
      switch self {
      case .all:
        return "List DataSync Relationships"
      case .fetch:
        return "Fetch DataSync Relationship"
      case .create:
        return "Create DataSync Relationship"
      case .replace:
        return "Replace DataSync Relationship"
      case .patch:
        return "Patch DataSync Relationship"
      case .remove:
        return "Remove DataSync Relationship"
      }
    }
  }

  struct CreateBody: JSONCodable, Equatable {
    let id: String?
    let entityAId: String
    let entityBId: String
    let relationshipClass: String
    let relationshipClassVersion: Int
    let status: String?
    let payload: AnyJSON?

    init(
      id: String? = nil,
      entityAId: String,
      entityBId: String,
      relationshipClass: String,
      relationshipClassVersion: Int,
      status: String? = nil,
      payload: AnyJSON? = nil
    ) {
      self.id = id
      self.entityAId = entityAId
      self.entityBId = entityBId
      self.relationshipClass = relationshipClass
      self.relationshipClassVersion = relationshipClassVersion
      self.status = status
      self.payload = payload
    }
  }

  struct ReplaceBody: JSONCodable, Equatable {
    let status: String?
    let relationshipClassVersion: Int
    let payload: AnyJSON?

    init(status: String? = nil, relationshipClassVersion: Int, payload: AnyJSON? = nil) {
      self.status = status
      self.relationshipClassVersion = relationshipClassVersion
      self.payload = payload
    }
  }

  init(_ endpoint: Endpoint, configuration: RouterConfiguration, customHeaders: [String: String] = [:]) {
    self.endpoint = endpoint
    self.configuration = configuration
    self.customHeaders = customHeaders
  }

  var endpoint: Endpoint
  var configuration: RouterConfiguration
  var customHeaders: [String: String]

  var service: PubNubService {
    .dataSync
  }

  var category: String {
    endpoint.description
  }

  var pamVersion: PAMVersionRequirement {
    .version3
  }

  var path: Result<String, Error> {
    let base = "/v1/datasync/subkeys/\(subscribeKey)/relationships"

    switch endpoint {
    case .all, .create:
      return .success(base)
    case let .fetch(id):
      return .success("\(base)/\(id.urlEncodeSlash)")
    case let .replace(id, _, _):
      return .success("\(base)/\(id.urlEncodeSlash)")
    case let .patch(id, _, _):
      return .success("\(base)/\(id.urlEncodeSlash)")
    case let .remove(id, _):
      return .success("\(base)/\(id.urlEncodeSlash)")
    }
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .all(
      relationshipClass, entityAId, entityBId, relationshipClassVersion,
      cursor, limit, filterFast, filter, sort
    ):
      query.appendIfPresent(key: .relationshipClass, value: relationshipClass)
      query.appendIfPresent(key: .entityAId, value: entityAId)
      query.appendIfPresent(key: .entityBId, value: entityBId)
      query.appendIfPresent(key: .relationshipClassVersion, value: relationshipClassVersion?.description)
      query.appendIfPresent(key: .cursor, value: cursor)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .filterFast, value: filterFast)
      query.appendIfPresent(key: .filter, value: filter)
      query.appendIfPresent(key: .sort, value: sort)
    default:
      break
    }

    return .success(query)
  }

  var method: HTTPMethod {
    switch endpoint {
    case .all: return .get
    case .fetch: return .get
    case .create: return .post
    case .replace: return .put
    case .patch: return .patch
    case .remove: return .delete
    }
  }

  var body: Result<Data?, Error> {
    switch endpoint {
    case let .create(body):
      return DataSyncRequestEnvelope(data: body).encodableJSONData.map { .some($0) }
    case let .replace(_, body, _):
      return DataSyncRequestEnvelope(data: body).encodableJSONData.map { .some($0) }
    case let .patch(_, operations, _):
      return operations.encodableJSONData.map { .some($0) }
    default:
      return .success(nil)
    }
  }

  var additionalHeaders: [String: String] {
    var headers = customHeaders

    switch endpoint {
    case .create:
      headers[Constant.contentTypeHeaderKey] = DataSyncHeader.contentType(resource: "relationship")
    case let .replace(_, _, ifMatch):
      headers[Constant.contentTypeHeaderKey] = DataSyncHeader.contentType(resource: "relationship")
      headers[DataSyncHeader.ifMatch] = ifMatch
    case let .patch(_, _, ifMatch):
      headers[Constant.contentTypeHeaderKey] = DataSyncHeader.jsonPatchContentType
      headers[DataSyncHeader.ifMatch] = ifMatch
    case let .remove(_, ifMatch):
      headers[DataSyncHeader.ifMatch] = ifMatch
    default:
      break
    }

    return headers.compactMapValues { $0 }
  }

  var validationErrorDetail: String? {
    switch endpoint {
    case let .all(relationshipClass, _, _, _, _, _, _, _, _):
      return isInvalidForReason((relationshipClass.isEmpty, ErrorDescription.emptyRelationshipClass))
    case let .create(body):
      return isInvalidForReason(
        (body.entityAId.isEmpty, ErrorDescription.emptyRelationshipEntityAId),
        (body.entityBId.isEmpty, ErrorDescription.emptyRelationshipEntityBId),
        (body.relationshipClass.isEmpty, ErrorDescription.emptyRelationshipClass)
      )
    case let .fetch(id):
      return isInvalidForReason((id.isEmpty, ErrorDescription.emptyDataSyncId))
    case let .replace(id, _, _):
      return isInvalidForReason((id.isEmpty, ErrorDescription.emptyDataSyncId))
    case let .patch(id, operations, _):
      return isInvalidForReason(
        (id.isEmpty, ErrorDescription.emptyDataSyncId),
        (operations.isEmpty, ErrorDescription.emptyPatchOperations)
      )
    case let .remove(id, _):
      return isInvalidForReason((id.isEmpty, ErrorDescription.emptyDataSyncId))
    }
  }
}
