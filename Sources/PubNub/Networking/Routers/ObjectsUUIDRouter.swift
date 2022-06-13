//
//  ObjectsUUIDRouter.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2020 PubNub Inc.
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

import Foundation

public struct ObjectsUUIDRouter: HTTPRouter {
  public enum Endpoint: CustomStringConvertible {
    case all(
      customFields: Bool, totalCount: Bool, filter: String?, sort: [String], limit: Int?, start: String?, end: String?
    )
    case fetch(metadataId: String, customFields: Bool)
    case set(metadata: PubNubUUIDMetadata, customFields: Bool)
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

  enum Include {
    static let custom = "custom"
    static let status = "status"
    static let type = "type"

    static func includes(custom: Bool) -> [String] {
      var includes = [Include.status, Include.type]

      if custom {
        includes.append(Include.custom)
      }

      return includes
    }
  }

  // Init
  public init(_ endpoint: Endpoint, configuration: RouterConfiguration) {
    self.endpoint = endpoint
    self.configuration = configuration
  }

  public var endpoint: Endpoint
  public var configuration: RouterConfiguration

  // Protocol Properties
  public var service: PubNubService {
    return .objects
  }

  public var category: String {
    return endpoint.description
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
      query.appendIfPresent(key: .include, value: Include.includes(custom: customFields).csvString)
      query.appendIfPresent(key: .count, value: totalCount ? totalCount.description : nil)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
    case let .fetch(_, customFields):
      query.appendIfPresent(key: .include, value: Include.includes(custom: customFields).csvString)
    case let .set(_, customFields):
      query.appendIfPresent(key: .include, value: Include.includes(custom: customFields).csvString)
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

extension ObjectsUUIDRouter.Endpoint: Equatable {
  public static func == (
    lhs: ObjectsUUIDRouter.Endpoint, rhs: ObjectsUUIDRouter.Endpoint
  ) -> Bool {
    switch (lhs, rhs) {
    case let (
      .all(lhs1, lhs2, lhs3, lhs4, lhs5, lhs6, lhs7),
      .all(rhs1, rhs2, rhs3, rhs4, rhs5, rhs6, rhs7)
    ):
      return lhs1 == rhs1 && lhs2 == rhs2 && lhs3 == rhs3 &&
        lhs4 == rhs4 && lhs5 == rhs5 && lhs6 == rhs6 && lhs7 == rhs7
    case let (.fetch(lhs1, lhs2), .fetch(rhs1, rhs2)):
      return lhs1 == rhs1 && lhs2 == rhs2
    case let (.set(lhs1, lhs2), .set(rhs1, rhs2)):
      let lhsUser = try? PubNubUUIDMetadataBase(from: lhs1)
      let rhsUser = try? PubNubUUIDMetadataBase(from: rhs1)
      return lhsUser == rhsUser && lhs2 == rhs2
    case let (.remove(lhsParam), .remove(rhsParam)):
      return lhsParam == rhsParam
    default:
      return false
    }
  }
}

// MARK: - Response Decoder

public typealias PubNubUUIDsMetadataResponseDecoder = FetchMultipleValueResponseDecoder<PubNubUUIDMetadataBase>

public struct FetchMultipleValueResponseDecoder<Value: Codable>: ResponseDecoder {
  public typealias Payload = FetchMultipleResponse<Value>
  public init() {}
}

public typealias PubNubUUIDMetadataResponseDecoder = FetchSingleValueResponseDecoder<PubNubUUIDMetadataBase>

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
