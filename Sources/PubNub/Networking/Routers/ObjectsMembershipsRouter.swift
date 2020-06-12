//
//  ObjectsMembershipsRouter.swift
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

struct ObjectsMembershipsRouter: HTTPRouter {
  enum Endpoint: CustomStringConvertible {
    case fetchMemberships(
      uuidMetadataId: String, customFields: [MembershipInclude]?, totalCount: Bool,
      filter: String?, sort: [String],
      limit: Int?, start: String?, end: String?
    )
    case fetchMembers(
      channelMetadataId: String, customFields: [MembershipInclude]?, totalCount: Bool,
      filter: String?, sort: [String],
      limit: Int?, start: String?, end: String?
    )
    case setMemberships(
      uuidMetadataId: String, customFields: [MembershipInclude]?, totalCount: Bool,
      changes: SetMembershipRequestBody,
      filter: String?, sort: [String], limit: Int?, start: String?, end: String?
    )
    case setMembers(
      channelMetadataId: String, customFields: [MembershipInclude]?, totalCount: Bool,
      changes: SetMembersRequestBody,
      filter: String?, sort: [String], limit: Int?, start: String?, end: String?
    )

    var description: String {
      switch self {
      case .fetchMemberships:
        return "Fetch the Membership Metadata for a UUID"
      case .fetchMembers:
        return "Fetch the Membership Metadata of a Channel"
      case .setMemberships:
        return "Set the Membership Metadata for a UUID"
      case .setMembers:
        return "Set the Membership Metadata of a Channel"
      }
    }
  }

  enum MembershipInclude: String, Codable {
    case custom
    case channel
    case channelCustom = "channel.custom"
    case uuid
    case uuidCustom = "uuid.custom"
  }

  struct SetMembershipRequestBody: JSONCodable {
    let set: [MembershipChange]
    let delete: [MembershipChange]
  }

  struct MembershipChange: JSONCodable {
    let metadataId: String
    let custom: [String: JSONCodableScalar]?

    // swiftlint:disable:next nesting
    enum CodingKeys: String, CodingKey {
      case object = "channel"
      case custom
    }

    // swiftlint:disable:next nesting
    enum NestedCodingKeys: String, CodingKey {
      case metadataId = "id"
    }

    init(metadataId: String, custom: [String: JSONCodableScalar]?) {
      self.metadataId = metadataId
      self.custom = custom
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)

      let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .object)
      metadataId = try nestedContainer.decode(String.self, forKey: .metadataId)
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encodeIfPresent(custom?.mapValues { $0.scalarValue }, forKey: .custom)

      var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .object)
      try nestedContainer.encode(metadataId, forKey: .metadataId)
    }
  }

  struct SetMembersRequestBody: JSONCodable {
    let set: [MemberChange]
    let delete: [MemberChange]
  }

  struct MemberChange: JSONCodable {
    let metadataId: String
    let custom: [String: JSONCodableScalar]?

    init(metadataId: String, custom: [String: JSONCodableScalar]?) {
      self.metadataId = metadataId
      self.custom = custom
    }

    // swiftlint:disable:next nesting
    enum CodingKeys: String, CodingKey {
      case object = "uuid"
      case custom
    }

    // swiftlint:disable:next nesting
    enum NestedCodingKeys: String, CodingKey {
      case metadataId = "id"
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)

      let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .object)
      metadataId = try nestedContainer.decode(String.self, forKey: .metadataId)
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encodeIfPresent(custom?.mapValues { $0.scalarValue }, forKey: .custom)

      var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .object)
      try nestedContainer.encode(metadataId, forKey: .metadataId)
    }
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
    case let .fetchMemberships(uuidMetadataId, _, _, _, _, _, _, _):
      path = "/v2/objects/\(subscribeKey)/uuids/\(uuidMetadataId.urlEncodeSlash)/channels"
    case let .fetchMembers(channelMetadataId, _, _, _, _, _, _, _):
      path = "/v2/objects/\(subscribeKey)/channels/\(channelMetadataId.urlEncodeSlash)/uuids"
    case let .setMemberships(uuidMetadataId, _, _, _, _, _, _, _, _):
      path = "/v2/objects/\(subscribeKey)/uuids/\(uuidMetadataId.urlEncodeSlash)/channels"
    case let .setMembers(channelMetadataId, _, _, _, _, _, _, _, _):
      path = "/v2/objects/\(subscribeKey)/channels/\(channelMetadataId.urlEncodeSlash)/uuids"
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .fetchMemberships(_, customFields, totalCount, filter, sort, limit, start, end),
         let .fetchMembers(_, customFields, totalCount, filter, sort, limit, start, end):
      query.appendIfPresent(key: .filter, value: filter)
      query.appendIfNotEmpty(key: .sort, value: sort)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .include, value: customFields?.map { $0.rawValue }.csvString)
      query.appendIfPresent(key: .count, value: totalCount ? totalCount.description : nil)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
    case let .setMemberships(_, customFields, totalCount, _, filter, sort, limit, start, end),
         let .setMembers(_, customFields, totalCount, _, filter, sort, limit, start, end):
      query.appendIfPresent(key: .filter, value: filter)
      query.appendIfNotEmpty(key: .sort, value: sort)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .include, value: customFields?.map { $0.rawValue }.csvString)
      query.appendIfPresent(key: .count, value: totalCount ? totalCount.description : nil)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
    }

    return .success(query)
  }

  var method: HTTPMethod {
    switch endpoint {
    case .fetchMemberships, .fetchMembers:
      return .get
    case .setMemberships, .setMembers:
      return .patch
    }
  }

  var body: Result<Data?, Error> {
    switch endpoint {
    case let .setMemberships(_, _, _, changes, _, _, _, _, _):
      return changes.encodableJSONData.map { .some($0) }
    case let .setMembers(_, _, _, changes, _, _, _, _, _):
      return changes.encodableJSONData.map { .some($0) }
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
    case let .fetchMemberships(uuidMetadataId, _, _, _, _, _, _, _):
      return isInvalidForReason((uuidMetadataId.isEmpty, ErrorDescription.emptyUUIDMetadataId))
    case let .fetchMembers(channelMetadatId, _, _, _, _, _, _, _):
      return isInvalidForReason((channelMetadatId.isEmpty, ErrorDescription.emptyChannelMetadataId))
    case let .setMemberships(uuidMetadataId, _, _, _, _, _, _, _, _):
      return isInvalidForReason((uuidMetadataId.isEmpty, ErrorDescription.emptyUUIDMetadataId))
    case let .setMembers(channelMetadatId, _, _, _, _, _, _, _, _):
      return isInvalidForReason((channelMetadatId.isEmpty, ErrorDescription.emptyChannelMetadataId))
    }
  }
}

// MARK: - Response Decoder

struct PubNubMembershipsResponseDecoder: ResponseDecoder {
  typealias Payload = PubNubMembershipsResponsePayload
}

struct PubNubMembershipsResponsePayload: Codable {
  let status: Int
  let data: [ObjectMetadataPartial]
  let totalCount: Int?
  let next: String?
  let prev: String?

  init(
    status: Int,
    data: [ObjectMetadataPartial],
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

  enum CodingKeys: String, CodingKey {
    case status
    case data
    case totalCount
    case next
    case prev
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    status = try container.decode(Int.self, forKey: .status)
    data = try container.decode([ObjectMetadataPartial].self, forKey: .data)
    totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount)
    next = try container.decodeIfPresent(String.self, forKey: .next)
    prev = try container.decodeIfPresent(String.self, forKey: .prev)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(data, forKey: .data)
    try container.encode(status, forKey: .status)
    try container.encodeIfPresent(totalCount, forKey: .totalCount)
    try container.encodeIfPresent(next, forKey: .next)
    try container.encodeIfPresent(prev, forKey: .prev)
  }
}

struct ObjectMetadataPartial: Codable {
  let channel: PartialMetadata<PubNubChannelMetadataBase>?
  let uuid: PartialMetadata<PubNubUUIDMetadataBase>?
  let custom: [String: JSONCodableScalarType]?
  let updated: Date
  let eTag: String

  struct PartialMetadata<MetadataType> {
    var metadataId: String
    var metadataObject: MetadataType?
  }

  enum CodingKeys: String, CodingKey {
    case channel
    case uuid
    case custom
    case updated
    case eTag
  }

  enum NestedCodingKeys: String, CodingKey {
    case id
  }

  init(
    channel: PartialMetadata<PubNubChannelMetadataBase>?,
    uuid: PartialMetadata<PubNubUUIDMetadataBase>?,
    updated: Date,
    eTag: String,
    custom: [String: JSONCodableScalarType]?
  ) {
    self.channel = channel
    self.uuid = uuid
    self.updated = updated
    self.eTag = eTag
    self.custom = custom
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)

    if let channel = try? container.decodeIfPresent(PubNubChannelMetadataBase.self, forKey: .channel) {
      self.channel = .init(metadataId: channel.metadataId, metadataObject: channel)
      uuid = nil
    } else if let uuid = try? container.decodeIfPresent(PubNubUUIDMetadataBase.self, forKey: .uuid) {
      self.uuid = .init(metadataId: uuid.metadataId, metadataObject: uuid)
      channel = nil
    } else if let nestedContainer = try? container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .channel) {
      channel = .init(metadataId: try nestedContainer.decode(String.self, forKey: .id), metadataObject: nil)
      uuid = nil
    } else {
      let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uuid)
      uuid = .init(metadataId: try nestedContainer.decode(String.self, forKey: .id), metadataObject: nil)
      channel = nil
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)
    try container.encodeIfPresent(custom, forKey: .custom)

    if uuid?.metadataObject != nil || channel?.metadataObject != nil {
      try container.encodeIfPresent(uuid?.metadataObject, forKey: .uuid)
      try container.encodeIfPresent(channel?.metadataObject, forKey: .channel)
    } else {
      var channelContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .channel)
      try channelContainer.encodeIfPresent(channel?.metadataId, forKey: .id)
      var uuidContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uuid)
      try uuidContainer.encodeIfPresent(uuid?.metadataId, forKey: .id)
    }
  }
}
