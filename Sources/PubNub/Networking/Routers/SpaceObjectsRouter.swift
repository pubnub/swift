//
//  SpaceObjectsRouter.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

// MARK: - Router

struct SpaceObjectsRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case fetchAll(include: CustomIncludeField?, limit: Int?, start: String?, end: String?, count: Bool?)
    case fetch(spaceID: String, include: CustomIncludeField?)
    case create(space: PubNubSpace, include: CustomIncludeField?)
    case update(space: PubNubSpace, include: CustomIncludeField?)
    case delete(spaceID: String)
    case fetchMembers(
      spaceID: String,
      include: [CustomIncludeField]?,
      limit: Int?, start: String?, end: String?, count: Bool?
    )
    case modifyMembers(
      spaceID: String,
      adding: [ObjectIdentifiable], updating: [ObjectIdentifiable], removing: [String],
      include: [CustomIncludeField]?,
      limit: Int?, start: String?, end: String?, count: Bool?
    )

    var description: String {
      switch self {
      case .fetchAll:
        return "Fetch All Space Objects"
      case .fetch:
        return "Fetch Space Object"
      case .create:
        return "Create Space Object"
      case .update:
        return "Update Space Object"
      case .delete:
        return "Delete Space Object"
      case .fetchMembers:
        return "Fetch Space's Members"
      case .modifyMembers:
        return "Modify Space's Members"
      }
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
    case .fetchAll:
      path = "/v1/objects/\(subscribeKey)/spaces"
    case let .fetch(spaceID, _):
      path = "/v1/objects/\(subscribeKey)/spaces/\(spaceID.urlEncodeSlash)"
    case .create:
      path = "/v1/objects/\(subscribeKey)/spaces"
    case let .update(space, _):
      path = "/v1/objects/\(subscribeKey)/spaces/\(space.id.urlEncodeSlash)"
    case let .delete(spaceID):
      path = "/v1/objects/\(subscribeKey)/spaces/\(spaceID.urlEncodeSlash)"
    case let .fetchMembers(spaceID, _, _, _, _, _):
      path = "/v1/objects/\(subscribeKey)/spaces/\(spaceID.urlEncodeSlash)/users"
    case let .modifyMembers(spaceID, _, _, _, _, _, _, _, _):
      path = "/v1/objects/\(subscribeKey)/spaces/\(spaceID.urlEncodeSlash)/users"
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .fetchAll(include, limit, start, end, count):
      query.appendIfPresent(key: .include, value: include?.rawValue)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .count, value: count?.description)
    case let .fetch(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case let .create(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case let .update(_, include):
      query.appendIfPresent(key: .include, value: include?.rawValue)
    case .delete:
      break
    case let .fetchMembers(_, include, limit, start, end, count):
      query.appendIfPresent(key: .include, value: include?.map { $0.rawValue }.csvString)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .count, value: count?.description)
    case let .modifyMembers(_, _, _, _, include, limit, start, end, count):
      query.appendIfPresent(key: .include, value: include?.map { $0.rawValue }.csvString)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .count, value: count?.description)
    }

    return .success(query)
  }

  var method: HTTPMethod {
    switch endpoint {
    case .fetchAll:
      return .get
    case .fetch:
      return .get
    case .create:
      return .post
    case .update:
      return .patch
    case .delete:
      return .delete
    case .fetchMembers:
      return .get
    case .modifyMembers:
      return .patch
    }
  }

  var body: Result<Data?, Error> {
    switch endpoint {
    case let .create(user, _):
      return user.jsonDataResult.map { .some($0) }
    case let .update(user, _):
      return user.jsonDataResult.map { .some($0) }
    case let .modifyMembers(_, adding, updating, removing, _, _, _, _, _):
      return MembershipChangeset(add: adding, update: updating, remove: removing)
        .encodableJSONData.map { .some($0) }
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
    case .fetchAll:
      return nil
    case let .fetch(spaceID, _):
      return isInvalidForReason((spaceID.isEmpty, ErrorDescription.emptySpaceID))
    case let .create(space, _):
      return isInvalidForReason(
        (space.id.isEmpty && space.name.isEmpty, ErrorDescription.invalidPubNubSpace))
    case let .update(space, _):
      return isInvalidForReason(
        (space.id.isEmpty && space.name.isEmpty, ErrorDescription.invalidPubNubSpace))
    case let .delete(spaceID):
      return isInvalidForReason((spaceID.isEmpty, ErrorDescription.emptySpaceID))
    case let .fetchMembers(spaceID, _, _, _, _, _):
      return isInvalidForReason((spaceID.isEmpty, ErrorDescription.emptySpaceID))
    case let .modifyMembers(spaceID, adding, updating, removing, _, _, _, _, _):
      return isInvalidForReason(
        (spaceID.isEmpty, ErrorDescription.emptySpaceID),
        (!adding.allSatisfy { !$0.id.isEmpty }, ErrorDescription.invalidJoiningMember),
        (!updating.allSatisfy { !$0.id.isEmpty }, ErrorDescription.invalidUpdatingMember),
        (!removing.allSatisfy { !$0.isEmpty }, ErrorDescription.invalidLeavingMember)
      )
    }
  }
}

// MARK: - Space Protocols

public protocol PubNubSpace: PubNubObject {
  var name: String { get }
  var spaceDescription: String? { get }

  /// Allows for other PubNubSpace objects to transcode between themselves
  init(from space: PubNubSpace) throws
}

extension PubNubSpace {
  public func transcode<T: PubNubSpace>(into _: T.Type) throws -> T {
    return try transcode()
  }

  public func transcode<T: PubNubSpace>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

public protocol PubNubMember: PubNubObject {
  var userId: String { get }
  var user: PubNubUser? { get set }

  init(from member: PubNubMember) throws
}

extension PubNubMember {
  public var id: String {
    return userId
  }

  public func transcode<T: PubNubMember>(into _: T.Type) throws -> T {
    return try transcode()
  }

  public func transcode<T: PubNubMember>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: - Response Decoder

// MARK: Protocol Spaces

struct PubNubSpacesResponseDecoder: ResponseDecoder {
  typealias Payload = PubNubSpacesResponsePayload
}

public struct PubNubSpacesResponsePayload: Codable {
  public let status: Int
  public let data: [PubNubSpace]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?

  public init(
    status: Int,
    data: [PubNubSpace],
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

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    data = try container.decode([SpaceObject].self, forKey: .data)
    status = try container.decode(Int.self, forKey: .status)
    totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount)
    next = try container.decodeIfPresent(String.self, forKey: .next)
    prev = try container.decodeIfPresent(String.self, forKey: .prev)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(try data.map { try $0.transcode(into: SpaceObject.self) }, forKey: .data)
    try container.encode(status, forKey: .status)
    try container.encodeIfPresent(totalCount, forKey: .totalCount)
    try container.encodeIfPresent(next, forKey: .next)
    try container.encodeIfPresent(prev, forKey: .prev)
  }
}

// MARK: Spaces

public struct SpacesResponsePayload<T: PubNubSpace> {
  public let status: Int
  public let data: [T]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?

  public init(
    status: Int,
    data: [T],
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

  public init<T: PubNubSpace>(
    protocol response: PubNubSpacesResponsePayload,
    into _: T.Type
  ) throws {
    self.init(
      status: response.status,
      data: try response.data.map { try $0.transcode() },
      totalCount: response.totalCount,
      next: response.next,
      prev: response.prev
    )
  }
}

extension SpacesResponsePayload: Codable where T: Codable {}
extension SpacesResponsePayload: Equatable where T: Equatable {}

// MARK: Protocol Space

struct PubNubSpaceResponseDecoder: ResponseDecoder {
  typealias Payload = PubNubSpaceResponsePayload
}

public struct PubNubSpaceResponsePayload: Codable {
  public let status: Int
  public let data: PubNubSpace

  public init(status: Int = 200, data: PubNubSpace) {
    self.status = status
    self.data = data
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ObjectResponseCodingKeys.self)

    data = try container.decode(SpaceObject.self, forKey: .data)
    status = try container.decode(Int.self, forKey: .status)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: ObjectsResponseCodingKeys.self)

    try container.encode(try data.transcode(into: SpaceObject.self), forKey: .data)
    try container.encode(status, forKey: .status)
  }
}

// MARK: Space

public struct SpaceResponsePayload<T: PubNubSpace> {
  public let status: Int
  public let data: T
}

extension SpaceResponsePayload: Equatable where T: Equatable {}

// MARK: Protocol Members

struct PubNubMembersResponseDecoder: ResponseDecoder {
  typealias Payload = PubNubMembersResponsePayload
}

public struct PubNubMembersResponsePayload: Codable {
  public let status: Int
  public let data: [PubNubMember]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?

  public init(
    status: Int,
    data: [PubNubMember],
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

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ObjectsResponseCodingKeys.self)

    status = try container.decode(Int.self, forKey: .status)
    data = try container.decode([SpaceObjectMember].self, forKey: .data)
    totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount)
    next = try container.decodeIfPresent(String.self, forKey: .next)
    prev = try container.decodeIfPresent(String.self, forKey: .prev)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: ObjectsResponseCodingKeys.self)

    try container.encode(try data.map { try $0.transcode(into: SpaceObjectMember.self) }, forKey: .data)
    try container.encode(status, forKey: .status)
    try container.encodeIfPresent(totalCount, forKey: .totalCount)
    try container.encodeIfPresent(next, forKey: .next)
    try container.encodeIfPresent(prev, forKey: .prev)
  }
}

// MARK: Members

public struct MembersResponsePayload<T: PubNubMember> {
  public let status: Int
  public let data: [T]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?

  public init(
    status: Int,
    data: [T],
    totalCount: Int?,
    next: String?,
    prev: String?
  ) throws {
    self.status = status
    self.data = data
    self.totalCount = totalCount
    self.next = next
    self.prev = prev
  }

  public init<T: PubNubMember>(
    protocol response: PubNubMembersResponsePayload,
    into _: T.Type
  ) throws {
    try self.init(
      status: response.status,
      data: try response.data.map { try $0.transcode() },
      totalCount: response.totalCount,
      next: response.next,
      prev: response.prev
    )
  }
}

extension MembersResponsePayload: Equatable where T: Equatable {}

// MARK: - Space Response

public struct SpaceObject: PubNubSpace, Codable, Equatable {
  public let id: String
  public let name: String
  public let spaceDescription: String?

  public var custom: [String: JSONCodableScalar]?

  public let created: Date
  public let updated: Date
  public let eTag: String

  public init(
    name: String,
    id: String? = nil,
    spaceDescription: String? = nil,
    custom: [String: JSONCodableScalar]? = nil,
    created: Date = Date.distantPast,
    updated: Date? = nil,
    eTag: String = ""
  ) {
    self.id = id ?? name
    self.name = name
    self.spaceDescription = spaceDescription
    self.custom = custom
    self.created = created
    self.updated = updated ?? created
    self.eTag = eTag
  }

  public init(from space: PubNubSpace) {
    self.init(
      name: space.name,
      id: space.id,
      spaceDescription: space.spaceDescription,
      custom: space.custom,
      created: space.created,
      updated: space.updated,
      eTag: space.eTag
    )
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case spaceDescription = "description"
    case custom
    case created
    case updated
    case eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    spaceDescription = try container.decodeIfPresent(String.self, forKey: .spaceDescription)
    custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
    created = try container.decode(Date.self, forKey: .created)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encodeIfPresent(spaceDescription, forKey: .spaceDescription)
    try container.encodeIfPresent(custom?.mapValues { $0.codableValue }, forKey: .custom)
    try container.encode(created, forKey: .created)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)
  }

  public static func == (lhs: SpaceObject, rhs: SpaceObject) -> Bool {
    return lhs.id == rhs.id &&
      lhs.name == rhs.name &&
      lhs.spaceDescription == rhs.spaceDescription &&
      lhs.created == lhs.created &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag &&
      lhs.custom?.allSatisfy {
        rhs.custom?[$0]?.scalarValue == $1.scalarValue
      } ?? true
  }
}

// MARK: - Member Response

public struct SpaceObjectMember: PubNubMember, PubNubIdentifiable, Codable, Equatable {
  public let id: String
  public var userId: String {
    return id
  }

  public let custom: [String: JSONCodableScalar]?

  var userObject: UserObject?
  public var user: PubNubUser? {
    get { return userObject }
    set { userObject = try? newValue?.transcode() }
  }

  public let created: Date
  public let updated: Date
  public let eTag: String

  public init(
    id: String,
    custom: [String: JSONCodableScalar]? = nil,
    user: PubNubUser?,
    created: Date = Date(),
    updated: Date? = nil,
    eTag: String = ""
  ) {
    self.id = id
    self.custom = custom
    userObject = try? user?.transcode()
    self.created = created
    self.updated = updated ?? created
    self.eTag = eTag
  }

  public init(from member: PubNubMember) throws {
    self.init(
      id: member.userId,
      custom: member.custom,
      user: member.user,
      created: member.created,
      updated: member.updated,
      eTag: member.eTag
    )
  }

  enum CodingKeys: String, CodingKey {
    case id
    case user
    case custom
    case created
    case updated
    case eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(String.self, forKey: .id)
    userObject = try container.decodeIfPresent(UserObject.self, forKey: .user)
    custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
    created = try container.decode(Date.self, forKey: .created)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encodeIfPresent(userObject, forKey: .user)
    try container.encodeIfPresent(custom?.mapValues { $0.codableValue }, forKey: .custom)
    try container.encode(created, forKey: .created)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)
  }

  public static func == (lhs: SpaceObjectMember, rhs: SpaceObjectMember) -> Bool {
    return lhs.id == rhs.id &&
      lhs.userObject == rhs.userObject &&
      lhs.created == lhs.created &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag &&
      lhs.custom?.allSatisfy {
        rhs.custom?[$0]?.scalarValue == $1.scalarValue
      } ?? true
  }
}

// MARK: - Deprecated (v2.0.0)

public typealias SpaceObjectsResponsePayload = SpacesResponsePayload<SpaceObject>
extension SpaceObjectsResponsePayload {
  public var spaces: [T] {
    return data
  }
}

public typealias UserMembership = SpaceObjectMember

public typealias SpaceMembershipResponsePayload = MembersResponsePayload<SpaceObjectMember>
extension SpaceMembershipResponsePayload {
  public var memberships: [T] {
    return data
  }

  // swiftlint:disable:next file_length
}
