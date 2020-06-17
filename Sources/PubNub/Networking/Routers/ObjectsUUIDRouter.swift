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

struct ObjectsUUIDRouter: HTTPRouter {
  enum Endpoint: CustomStringConvertible {
    case all(
      customFields: Bool, totalCount: Bool, filter: String?, sort: [String], limit: Int?, start: String?, end: String?
    )
    case fetch(metadataId: String, customFields: Bool)
    case set(metadata: PubNubUUIDMetadata, customFields: Bool)
    case remove(metadataId: String)

    var description: String {
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
    var name: String
    var externalId: String?
    var profileURL: String?
    var email: String?
    var custom: [String: JSONCodableScalarType]?
  }

  struct Include {
    static let custom = "custom"
  }

  // Init
  init(_ endpoint: Endpoint, configuration: RouterConfiguration) {
    self.endpoint = endpoint
    self.configuration = configuration
  }

  var endpoint: Endpoint
  var configuration: RouterConfiguration

  // Protocol Properties
  var service: PubNubService {
    return .objects
  }

  var category: String {
    return endpoint.description
  }

  var path: Result<String, Error> {
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

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .all(customFields, totalCount, filter, sort, limit, start, end):
      query.appendIfPresent(key: .filter, value: filter)
      query.appendIfNotEmpty(key: .sort, value: sort)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .include, value: customFields ? Include.custom : nil)
      query.appendIfPresent(key: .count, value: totalCount ? totalCount.description : nil)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
    case let .fetch(_, customFields):
      query.appendIfPresent(key: .include, value: customFields ? Include.custom : nil)
    case let .set(_, customFields):
      query.appendIfPresent(key: .include, value: customFields ? Include.custom : nil)
    case .remove:
      break
    }

    return .success(query)
  }

  var method: HTTPMethod {
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

  var body: Result<Data?, Error> {
    switch endpoint {
    case let .set(user, _):
      return SetUUIDMetadataRequestBody(
        name: user.name, externalId: user.externalId, profileURL: user.profileURL,
        email: user.email, custom: user.custom?.mapValues { $0.scalarValue }
      ).jsonDataResult.map { .some($0) }
    default:
      return .success(nil)
    }
  }

  var pamVersion: PAMVersionRequirement {
    return .version3
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case .all:
      return nil
    case let .fetch(metadataId, _):
      return isInvalidForReason((metadataId.isEmpty, ErrorDescription.emptyUUIDMetadataId))
    case let .set(metadata, _):
      return isInvalidForReason(
        (metadata.metadataId.isEmpty && metadata.name.isEmpty, ErrorDescription.invalidUUIDMetadata))
    case let .remove(metadataId):
      return isInvalidForReason((metadataId.isEmpty, ErrorDescription.emptyUUIDMetadataId))
    }
  }
}

// MARK: - Response Decoder

struct PubNubUUIDsMetadataResponseDecoder: ResponseDecoder {
  typealias Payload = PubNubUUIDsMetadataResponsePayload
}

struct PubNubUUIDMetadataResponseDecoder: ResponseDecoder {
  typealias Payload = PubNubUUIDMetadataResponsePayload
}

struct PubNubUUIDsMetadataResponsePayload: Codable {
  let status: Int
  let data: [PubNubUUIDMetadata]
  let totalCount: Int?
  let next: String?
  let prev: String?

  enum CodingKeys: String, CodingKey {
    case status
    case data
    case totalCount
    case next
    case prev
  }

  init(
    status: Int,
    data: [PubNubUUIDMetadataBase],
    totalCount: Int?,
    next: String?,
    prev: String?
  ) {
    self.status = status
    self.data = data
    self.totalCount = totalCount
    self.next = next
    self.prev = prev
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    data = try container.decode([PubNubUUIDMetadataBase].self, forKey: .data)
    status = try container.decode(Int.self, forKey: .status)
    totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount)
    next = try container.decodeIfPresent(String.self, forKey: .next)
    prev = try container.decodeIfPresent(String.self, forKey: .prev)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(try data.map { try $0.transcode(into: PubNubUUIDMetadataBase.self) }, forKey: .data)
    try container.encode(status, forKey: .status)
    try container.encodeIfPresent(totalCount, forKey: .totalCount)
    try container.encodeIfPresent(next, forKey: .next)
    try container.encodeIfPresent(prev, forKey: .prev)
  }
}

struct PubNubUUIDMetadataResponsePayload: Codable {
  let status: Int
  let data: PubNubUUIDMetadata

  enum CodingKeys: String, CodingKey {
    case status
    case data
  }

  init(status: Int = 200, data: PubNubUUIDMetadataBase) {
    self.status = status
    self.data = data
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    data = try container.decode(PubNubUUIDMetadataBase.self, forKey: .data)
    status = try container.decode(Int.self, forKey: .status)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(try data.transcode(into: PubNubUUIDMetadataBase.self), forKey: .data)
    try container.encode(status, forKey: .status)
  }
}
