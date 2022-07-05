//
//  ObjectsChannelRouter.swift
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

public struct ObjectsChannelRouter: HTTPRouter {
  public enum Endpoint: CustomStringConvertible {
    case all(
      customFields: Bool, totalCount: Bool, filter: String?, sort: [String], limit: Int?, start: String?, end: String?
    )
    case fetch(metadataId: String, customFields: Bool)
    case set(metadata: PubNubChannelMetadata, customFields: Bool)
    case remove(metadataId: String)

    public var description: String {
      switch self {
      case .all:
        return "Get All Metadata for Channels"
      case .fetch:
        return "Fetch Metadata for a Channel"
      case .set:
        return "Set Metadata for a Channel"
      case .remove:
        return "Remove Metadata from a Channel"
      }
    }
  }

  // Custom request body object for .set endpoint
  struct SetChannelMetadataRequestBody: JSONCodable {
    var name: String?
    var type: String?
    var status: String?
    var description: String?
    var custom: [String: JSONCodableScalarType]?
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
      path = "/v2/objects/\(subscribeKey)/channels"
    case let .fetch(metadataId, _):
      path = "/v2/objects/\(subscribeKey)/channels/\(metadataId.urlEncodeSlash)"
    case let .set(metadata, _):
      path = "/v2/objects/\(subscribeKey)/channels/\(metadata.metadataId.urlEncodeSlash)"
    case let .remove(metadataId):
      path = "/v2/objects/\(subscribeKey)/channels/\(metadataId.urlEncodeSlash)"
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
    case let .set(channel, _):
      return SetChannelMetadataRequestBody(
        name: channel.name, type: channel.type, status: channel.status, description: channel.channelDescription,
        custom: channel.custom?.mapValues { $0.scalarValue }
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
      return isInvalidForReason((metadataId.isEmpty, ErrorDescription.emptyChannelMetadataId))
    case let .set(metadata, _):
      return isInvalidForReason(
        (metadata.metadataId.isEmpty, ErrorDescription.invalidChannelMetadata))
    case let .remove(metadataId):
      return isInvalidForReason((metadataId.isEmpty, ErrorDescription.emptyChannelMetadataId))
    }
  }
}

extension ObjectsChannelRouter.Endpoint: Equatable {
  public static func == (
    lhs: ObjectsChannelRouter.Endpoint, rhs: ObjectsChannelRouter.Endpoint
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
      let lhsUser = try? PubNubChannelMetadataBase(from: lhs1)
      let rhsUser = try? PubNubChannelMetadataBase(from: rhs1)
      return lhsUser == rhsUser && lhs2 == rhs2
    case let (.remove(lhsParam), .remove(rhsParam)):
      return lhsParam == rhsParam
    default:
      return false
    }
  }
}

// MARK: - Response Decoder

public struct PubNubChannelsMetadataResponseDecoder: ResponseDecoder {
  public typealias Payload = PubNubChannelsMetadataResponsePayload
  public init() {}
}

public struct PubNubChannelMetadataResponseDecoder: ResponseDecoder {
  public typealias Payload = PubNubChannelMetadataResponsePayload
  public init() {}
}

public struct PubNubChannelsMetadataResponsePayload: Codable {
  let status: Int
  public let data: [PubNubChannelMetadata]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?

  enum CodingKeys: String, CodingKey {
    case status
    case data
    case totalCount
    case next
    case prev
  }

  init(
    status: Int,
    data: [PubNubChannelMetadataBase],
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

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    data = try container.decode([PubNubChannelMetadataBase].self, forKey: .data)
    status = try container.decode(Int.self, forKey: .status)
    totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount)
    next = try container.decodeIfPresent(String.self, forKey: .next)
    prev = try container.decodeIfPresent(String.self, forKey: .prev)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(try data.map { try $0.transcode(into: PubNubChannelMetadataBase.self) }, forKey: .data)
    try container.encode(status, forKey: .status)
    try container.encodeIfPresent(totalCount, forKey: .totalCount)
    try container.encodeIfPresent(next, forKey: .next)
    try container.encodeIfPresent(prev, forKey: .prev)
  }
}

public struct PubNubChannelMetadataResponsePayload: Codable {
  let status: Int
  public let data: PubNubChannelMetadata

  enum CodingKeys: String, CodingKey {
    case status
    case data
  }

  init(status: Int = 200, data: PubNubChannelMetadataBase) {
    self.status = status
    self.data = data
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    data = try container.decode(PubNubChannelMetadataBase.self, forKey: .data)
    status = try container.decode(Int.self, forKey: .status)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(try data.transcode(into: PubNubChannelMetadataBase.self), forKey: .data)
    try container.encode(status, forKey: .status)
  }
}
