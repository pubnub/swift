//
//  ObjectsUUIDRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public struct ObjectsUserRouter: HTTPRouter {
  public enum Endpoint: CustomStringConvertible {
    case all(include: [Include]?, totalCount: Bool, filter: String?, sort: [String], limit: Int?, start: String?, end: String?)
    case fetch(metadataId: String, include: [Include]?)
    case set(metadata: PubNubUserMetadata, include: [Include]?)
    case remove(metadataId: String)

    public var description: String {
      switch self {
      case .all:
        return "Get All Metadata by UUIDs"
      case .fetch:
        return "Fetch Metadata for a UUID"
      case .set:
        return "Set Metadata for a UUID"
      case .remove:
        return "Remove Metadata from a UUID"
      }
    }
  }

  // Custom request body object for .set endpoint
  struct SetUUIDMetadataRequestBody: JSONCodable {
    var name: String?
    var type: String?
    var status: String?
    var externalId: String?
    var profileURL: String?
    var email: String?
    var custom: [String: JSONCodableScalarType]?

    // swiftlint:disable:next nesting
    enum CodingKeys: String, CodingKey {
      case name
      case type
      case status
      case externalId
      case profileURL = "profileUrl"
      case email
      case custom
    }
  }

  public enum Include: String {
    case custom
    case status
    case type

    static func includes(from array: [Include]?) -> String? {
      array?.map { $0.rawValue }.csvString
    }
  }

  // Init
  public init(_ endpoint: Endpoint, configuration: RouterConfiguration, customHeaders: [String: String] = [:]) {
    self.endpoint = endpoint
    self.configuration = configuration
    self.customHeaders = customHeaders
  }

  public var endpoint: Endpoint
  public var configuration: RouterConfiguration
  public var customHeaders: [String: String]

  // Protocol Properties
  public var service: PubNubService {
    return .objects
  }

  public var category: String {
    return endpoint.description
  }

  public var additionalHeaders: [String: String] {
    customHeaders
  }

  public var path: Result<String, Error> {
    let path: String

    switch endpoint {
    case .all:
      path = "/v2/objects/\(subscribeKey)/uuids"
    case let .fetch(metadataId, _):
      path = "/v2/objects/\(subscribeKey)/uuids/\(metadataId.urlEncodeSlash)"
    case let .set(metadata, _):
      path = "/v2/objects/\(subscribeKey)/uuids/\(metadata.metadataId.urlEncodeSlash)"
    case let .remove(metadataId):
      path = "/v2/objects/\(subscribeKey)/uuids/\(metadataId.urlEncodeSlash)"
    }
    return .success(path)
  }

  public var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .all(customFields, totalCount, filter, sort, limit, start, end):
      query.appendIfPresent(key: .filter, value: filter)
      query.appendIfNotEmpty(key: .sort, value: sort)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .include, value: Include.includes(from: customFields))
      query.appendIfPresent(key: .count, value: totalCount ? totalCount.description : nil)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
    case let .fetch(_, customFields):
      query.appendIfPresent(key: .include, value: Include.includes(from: customFields))
    case let .set(_, customFields):
      query.appendIfPresent(key: .include, value: Include.includes(from: customFields))
    case .remove:
      break
    }

    return .success(query)
  }

  public var method: HTTPMethod {
    switch endpoint {
    case .all:
      return .get
    case .fetch:
      return .get
    case .set:
      return .patch
    case .remove:
      return .delete
    }
  }

  public var body: Result<Data?, Error> {
    switch endpoint {
    case let .set(user, _):
      return SetUUIDMetadataRequestBody(
        name: user.name, type: user.type, status: user.status, externalId: user.externalId, profileURL: user.profileURL,
        email: user.email, custom: user.custom?.mapValues { $0.scalarValue }
      ).jsonDataResult.map { .some($0) }
    default:
      return .success(nil)
    }
  }

  public var pamVersion: PAMVersionRequirement {
    return .version3
  }

  // Validated
  public var validationErrorDetail: String? {
    switch endpoint {
    case .all:
      return nil
    case let .fetch(metadataId, _):
      return isInvalidForReason((metadataId.isEmpty, ErrorDescription.emptyUUIDMetadataId))
    case let .set(metadata, _):
      return isInvalidForReason(
        (metadata.metadataId.isEmpty, ErrorDescription.invalidUUIDMetadata))
    case let .remove(metadataId):
      return isInvalidForReason((metadataId.isEmpty, ErrorDescription.emptyUUIDMetadataId))
    }
  }
}

extension ObjectsUserRouter.Endpoint: Equatable {
  public static func == (
    lhs: ObjectsUserRouter.Endpoint, rhs: ObjectsUserRouter.Endpoint
  ) -> Bool {
    switch (lhs, rhs) {
    case let (.all(lhs1, lhs2, lhs3, lhs4, lhs5, lhs6, lhs7), .all(rhs1, rhs2, rhs3, rhs4, rhs5, rhs6, rhs7)):
      return lhs1 == rhs1 && lhs2 == rhs2 && lhs3 == rhs3 && lhs4 == rhs4 && lhs5 == rhs5 && lhs6 == rhs6 && lhs7 == rhs7
    case let (.fetch(lhs1, lhs2), .fetch(rhs1, rhs2)):
      return lhs1 == rhs1 && lhs2 == rhs2
    case let (.set(lhs1, lhs2), .set(rhs1, rhs2)):
      let lhsUser = try? PubNubUserMetadataBase(from: lhs1)
      let rhsUser = try? PubNubUserMetadataBase(from: rhs1)
      return lhsUser == rhsUser && lhs2 == rhs2
    case let (.remove(lhsParam), .remove(rhsParam)):
      return lhsParam == rhsParam
    default:
      return false
    }
  }
}

// MARK: - Response Decoder

public typealias PubNubUsersMetadataResponseDecoder = FetchMultipleValueResponseDecoder<PubNubUserMetadataBase>

public struct FetchMultipleValueResponseDecoder<Value: Codable>: ResponseDecoder {
  public typealias Payload = FetchMultipleResponse<Value>
  public init() {}
}

public typealias PubNubUserMetadataResponseDecoder = FetchSingleValueResponseDecoder<PubNubUserMetadataBase>

public struct FetchSingleValueResponseDecoder<Value: Codable>: ResponseDecoder {
  public typealias Payload = FetchSingleResponse<Value>
  public init() {}
}

public struct FetchStatusResponseDecoder: ResponseDecoder {
  public typealias Payload = FetchStatusResponse
  public init() {}
}

public struct FetchSingleResponse<Value: Codable>: Codable {
  public let status: Int
  public let data: Value
}

public struct FetchMultipleResponse<Value: Codable>: Codable {
  public let status: Int
  public let data: [Value]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?
}

public struct FetchStatusResponse: Codable {
  public let status: Int
}
