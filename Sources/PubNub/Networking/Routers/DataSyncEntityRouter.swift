//
//  DataSyncEntityRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

struct DataSyncEntityRouter: HTTPRouter {
  enum Endpoint: CustomStringConvertible {
    case all(
      entityClass: String, entityClassVersion: Int?, entityClassLevel: String?, cursor: String?, limit: Int?,
      filter: String?, filterAdvanced: String?, sort: String?
    )
    case fetch(id: String)
    case create(body: CreateBody)
    case replace(id: String, body: ReplaceBody, ifMatch: String?)
    case patch(id: String, operations: [JSONPatchOperation], ifMatch: String?)
    case remove(id: String, ifMatch: String?)

    var description: String {
      switch self {
      case .all:
        return "List DataSync Entities"
      case .fetch:
        return "Fetch DataSync Entity"
      case .create:
        return "Create DataSync Entity"
      case .replace:
        return "Replace DataSync Entity"
      case .patch:
        return "Patch DataSync Entity"
      case .remove:
        return "Remove DataSync Entity"
      }
    }
  }

  struct CreateBody: JSONCodable, Equatable {
    let id: String?
    let entityClass: String
    let entityClassVersion: Int
    let status: String?
    let payload: AnyJSON?

    init(
      id: String? = nil,
      entityClass: String,
      entityClassVersion: Int,
      status: String? = nil,
      payload: AnyJSON? = nil
    ) {
      self.id = id
      self.entityClass = entityClass
      self.entityClassVersion = entityClassVersion
      self.status = status
      self.payload = payload
    }
  }

  struct ReplaceBody: JSONCodable, Equatable {
    let status: String?
    let entityClassVersion: Int
    let payload: AnyJSON?

    init(status: String? = nil, entityClassVersion: Int, payload: AnyJSON? = nil) {
      self.status = status
      self.entityClassVersion = entityClassVersion
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
    let base = "/v1/datasync/subkeys/\(subscribeKey)/entities"

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
    case let .all(entityClass, entityClassVersion, entityClassLevel, cursor, limit, filter, filterAdvanced, sort):
      query.appendIfPresent(key: .entityClass, value: entityClass)
      query.appendIfPresent(key: .entityClassVersion, value: entityClassVersion?.description)
      query.appendIfPresent(key: .entityClassLevel, value: entityClassLevel)
      query.appendIfPresent(key: .cursor, value: cursor)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .filter, value: filter)
      query.appendIfPresent(key: .filterAdvanced, value: filterAdvanced)
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
      headers[Constant.contentTypeHeaderKey] = DataSyncHeader.contentType(resource: "entity")
    case let .replace(_, _, ifMatch):
      headers[Constant.contentTypeHeaderKey] = DataSyncHeader.contentType(resource: "entity")
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

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .all(entityClass, _, _, _, _, _, _, _):
      return isInvalidForReason((entityClass.isEmpty, ErrorDescription.emptyEntityClass))
    case let .create(body):
      return isInvalidForReason((body.entityClass.isEmpty, ErrorDescription.emptyEntityClass))
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
