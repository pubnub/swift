//
//  UserObjectsRouter.swift
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

struct UserObjectsRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case fetchAll(include: CustomIncludeField?, limit: Int?, start: String?, end: String?, count: Bool?)
    case fetch(userID: String, include: CustomIncludeField?)
    case create(user: PubNubUser, include: CustomIncludeField?)
    case update(user: PubNubUser, include: CustomIncludeField?)
    case delete(userID: String)
    case fetchMemberships(
      userID: String,
      include: [CustomIncludeField]?,
      limit: Int?, start: String?, end: String?, count: Bool?
    )
    case modifyMemberships(
      userID: String,
      joining: [ObjectIdentifiable], updating: [ObjectIdentifiable], leaving: [String],
      include: [CustomIncludeField]?,
      limit: Int?, start: String?, end: String?, count: Bool?
    )

    var description: String {
      switch self {
      case .fetchAll:
        return "Fetch All User Objects"
      case .fetch:
        return "Fetch User Object"
      case .create:
        return "Create User Object"
      case .update:
        return "Update User Object"
      case .delete:
        return "Delete User Object"
      case .fetchMemberships:
        return "Fetch User's Memberships"
      case .modifyMemberships:
        return "Modify User's Memberships"
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
      path = "/v1/objects/\(subscribeKey)/users"
    case let .fetch(userID, _):
      path = "/v1/objects/\(subscribeKey)/users/\(userID.urlEncodeSlash)"
    case .create:
      path = "/v1/objects/\(subscribeKey)/users"
    case let .update(user, _):
      path = "/v1/objects/\(subscribeKey)/users/\(user.id.urlEncodeSlash)"
    case let .delete(userID):
      path = "/v1/objects/\(subscribeKey)/users/\(userID.urlEncodeSlash)"
    case let .fetchMemberships(userID, _, _, _, _, _):
      path = "/v1/objects/\(subscribeKey)/users/\(userID.urlEncodeSlash)/spaces"
    case let .modifyMemberships(userID, _, _, _, _, _, _, _, _):
      path = "/v1/objects/\(subscribeKey)/users/\(userID.urlEncodeSlash)/spaces"
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
    case let .fetchMemberships(_, include, limit, start, end, count):
      query.appendIfPresent(key: .include, value: include?.map { $0.rawValue }.csvString)
      query.appendIfPresent(key: .limit, value: limit?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .count, value: count?.description)
    case let .modifyMemberships(_, _, _, _, include, limit, start, end, count):
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
    case .fetchMemberships:
      return .get
    case .modifyMemberships:
      return .patch
    }
  }

  var body: Result<Data?, Error> {
    switch endpoint {
    case let .create(user, _):
      return user.jsonDataResult.map { .some($0) }
    case let .update(user, _):
      return user.jsonDataResult.map { .some($0) }
    case let .modifyMemberships(_, joining, updating, leaving, _, _, _, _, _):
      return MembershipChangeset(add: joining, update: updating, remove: leaving)
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
    case let .fetch(userID, _):
      return isInvalidForReason((userID.isEmpty, ErrorDescription.emptyUserID))
    case let .create(user, _):
      return isInvalidForReason(
        (user.id.isEmpty && user.name.isEmpty, ErrorDescription.invalidPubNubUser))
    case let .update(user, _):
      return isInvalidForReason(
        (user.id.isEmpty && user.name.isEmpty, ErrorDescription.invalidPubNubUser))
    case let .delete(userID):
      return isInvalidForReason((userID.isEmpty, ErrorDescription.emptyUserID))
    case let .fetchMemberships(userID, _, _, _, _, _):
      return isInvalidForReason((userID.isEmpty, ErrorDescription.emptyUserID))
    case let .modifyMemberships(userID, joining, updating, leaving, _, _, _, _, _):
      return isInvalidForReason(
        (userID.isEmpty, ErrorDescription.emptyUserID),
        (!joining.allSatisfy { !$0.id.isEmpty }, ErrorDescription.invalidJoiningMembership),
        (!updating.allSatisfy { !$0.id.isEmpty }, ErrorDescription.invalidUpdatingMembership),
        (!leaving.allSatisfy { !$0.isEmpty }, ErrorDescription.invalidLeavingMembership)
      )
    }
  }
}

// MARK: - Object Protocols

/// My Identifiable
public protocol PubNubIdentifiable {
  var id: String { get }
}

public protocol ObjectCustomizable {
  var custom: [String: JSONCodableScalar]? { get }
}

public extension ObjectCustomizable {
  /// A Codable reprentation of the custom property
  var concreteCustom: [String: JSONCodableScalarType]? {
    return custom?.mapValues { $0.scalarValue }
  }

  func customValue<T>(for key: String) -> T? {
    return custom?[key]?.rawValue as? T
  }
}

/// Minimum amount of information all Object Types contain

public protocol PubNubObject: PubNubIdentifiable, ObjectCustomizable, JSONCodable {
  var created: Date { get }
  var updated: Date { get }
  var eTag: String { get }
}

// MARK: - Concrete Request Types

public struct SimpleIdentifiableObject: Codable, Hashable {
  public let id: String

  public init(id: String) {
    self.id = id
  }
}

public struct SimpleCustomObject: ObjectIdentifiable, Codable {
  public let id: String
  public let custom: [String: JSONCodableScalar]?

  public init(_ object: ObjectIdentifiable) {
    id = object.id
    custom = object.custom
  }

  public init(_ membership: PubNubMembership) {
    id = membership.spaceId
    custom = membership.custom
  }

  public init(_ membership: PubNubMember) {
    id = membership.userId
    custom = membership.custom
  }

  enum CodingKeys: String, CodingKey {
    case id
    case custom
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(String.self, forKey: .id)
    custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encodeIfPresent(custom?.mapValues { $0.codableValue }, forKey: .custom)
  }
}

struct MembershipChangeset: Codable {
  let add: [SimpleCustomObject]
  let update: [SimpleCustomObject]
  let remove: [SimpleIdentifiableObject]

  init(add: [ObjectIdentifiable], update: [ObjectIdentifiable], remove: [String]) {
    self.add = add.map { SimpleCustomObject($0) }
    self.update = update.map { SimpleCustomObject($0) }
    self.remove = remove.map { SimpleIdentifiableObject(id: $0) }
  }
}

// MARK: - User Protocols

public protocol PubNubUser: PubNubObject {
  var name: String { get }
  var externalId: String? { get }
  var profileURL: String? { get }
  var email: String? { get }

  /// Allows for other PubNubUser objects to transcode between themselves
  init(from user: PubNubUser) throws
}

extension PubNubUser {
  public func transcode<T: PubNubUser>(into _: T.Type) throws -> T {
    return try transcode()
  }

  public func transcode<T: PubNubUser>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

public protocol PubNubMembership: PubNubObject {
  var spaceId: String { get }
  var space: PubNubSpace? { get set }

  init(from membership: PubNubMembership) throws
}

extension PubNubMembership {
  public var id: String {
    return spaceId
  }

  public func transcode<T: PubNubMembership>(into _: T.Type) throws -> T {
    return try transcode()
  }

  public func transcode<T: PubNubMembership>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: - Response Decoder

enum ObjectsResponseCodingKeys: String, CodingKey {
  case status
  case data
  case totalCount
  case next
  case prev
}

enum ObjectResponseCodingKeys: String, CodingKey {
  case status
  case data
}

// MARK: Protocol Users

struct PubNubUsersResponseDecoder: ResponseDecoder {
  typealias Payload = PubNubUsersResponsePayload
}

public struct PubNubUsersResponsePayload: Codable {
  public let status: Int
  public let data: [PubNubUser]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?

  public init(
    status: Int,
    data: [PubNubUser],
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
    let container = try decoder.container(keyedBy: ObjectsResponseCodingKeys.self)

    data = try container.decode([UserObject].self, forKey: .data)
    status = try container.decode(Int.self, forKey: .status)
    totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount)
    next = try container.decodeIfPresent(String.self, forKey: .next)
    prev = try container.decodeIfPresent(String.self, forKey: .prev)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: ObjectsResponseCodingKeys.self)

    try container.encode(try data.map { try $0.transcode(into: UserObject.self) }, forKey: .data)
    try container.encode(status, forKey: .status)
    try container.encodeIfPresent(totalCount, forKey: .totalCount)
    try container.encodeIfPresent(next, forKey: .next)
    try container.encodeIfPresent(prev, forKey: .prev)
  }
}

// MARK: Users

public struct UsersResponsePayload<T: PubNubUser> {
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

  public init<T: PubNubUser>(
    protocol response: PubNubUsersResponsePayload,
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

extension UsersResponsePayload: Codable where T: Codable {}
extension UsersResponsePayload: Equatable where T: Equatable {}

// MARK: Protocol User

struct PubNubUserResponseDecoder: ResponseDecoder {
  typealias Payload = PubNubUserResponsePayload
}

public struct PubNubUserResponsePayload: Codable {
  public let status: Int
  public let data: PubNubUser

  public init(status: Int = 200, data: PubNubUser) {
    self.status = status
    self.data = data
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ObjectResponseCodingKeys.self)

    data = try container.decode(UserObject.self, forKey: .data)
    status = try container.decode(Int.self, forKey: .status)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: ObjectsResponseCodingKeys.self)

    try container.encode(try data.transcode(into: UserObject.self), forKey: .data)
    try container.encode(status, forKey: .status)
  }
}

// MARK: User

public struct UserResponsePayload<T: PubNubUser> {
  public let status: Int
  public let data: T
}

extension UserResponsePayload: Equatable where T: Equatable {}

// MARK: Protocol Memberships

struct PubNubMembershipsResponseDecoder: ResponseDecoder {
  typealias Payload = PubNubMembershipsResponsePayload
}

public struct PubNubMembershipsResponsePayload: Codable {
  public let status: Int
  public let data: [PubNubMembership]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?

  public init(
    status: Int,
    data: [PubNubMembership],
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
    data = try container.decode([UserObjectMembership].self, forKey: .data)
    totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount)
    next = try container.decodeIfPresent(String.self, forKey: .next)
    prev = try container.decodeIfPresent(String.self, forKey: .prev)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: ObjectsResponseCodingKeys.self)

    try container.encode(try data.map { try $0.transcode(into: UserObjectMembership.self) }, forKey: .data)
    try container.encode(status, forKey: .status)
    try container.encodeIfPresent(totalCount, forKey: .totalCount)
    try container.encodeIfPresent(next, forKey: .next)
    try container.encodeIfPresent(prev, forKey: .prev)
  }
}

// MARK: Memberships

public struct MembershipsResponsePayload<T: PubNubMembership> {
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

  public init<T: PubNubMembership>(
    protocol response: PubNubMembershipsResponsePayload,
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

extension MembershipsResponsePayload: Equatable where T: Equatable {}

// MARK: - Response

/// Top-Level Coding Keys that can be used when Coding a PubNub User
public struct UserObject: PubNubUser, Codable, Equatable {
  public let id: String

  public let name: String
  public let externalId: String?
  public let profileURL: String?
  public let email: String?

  public let created: Date
  public let updated: Date
  public let eTag: String

  public let custom: [String: JSONCodableScalar]?

  public init(
    name: String,
    id: String? = nil,
    externalId: String? = nil,
    profileURL: String? = nil,
    email: String? = nil,
    custom: [String: JSONCodableScalar]? = nil,
    created: Date = Date.distantPast,
    updated: Date? = nil,
    eTag: String = ""
  ) {
    self.id = id ?? name
    self.name = name
    self.email = email
    self.externalId = externalId
    self.profileURL = profileURL
    self.custom = custom
    self.created = created
    self.updated = updated ?? created
    self.eTag = eTag
  }

  public init(copy user: UserObject) {
    id = user.id
    name = user.name
    email = user.email
    externalId = user.externalId
    profileURL = user.profileURL
    custom = user.custom
    created = user.created
    updated = user.updated
    eTag = user.eTag
  }

  public init(from user: PubNubUser) {
    self.init(
      name: user.name,
      id: user.id,
      externalId: user.externalId,
      profileURL: user.profileURL,
      email: user.email,
      custom: user.custom,
      created: user.created,
      updated: user.updated,
      eTag: user.eTag
    )
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case externalId
    case profileURL = "profileUrl"
    case email
    case custom
    case created
    case updated
    case eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    email = try container.decodeIfPresent(String.self, forKey: .email)
    externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
    profileURL = try container.decodeIfPresent(String.self, forKey: .profileURL)
    custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
    created = try container.decode(Date.self, forKey: .created)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encodeIfPresent(email, forKey: .email)
    try container.encodeIfPresent(externalId, forKey: .externalId)
    try container.encodeIfPresent(profileURL, forKey: .profileURL)
    try container.encodeIfPresent(custom?.mapValues { $0.codableValue }, forKey: .custom)
    try container.encode(created, forKey: .created)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)
  }

  public static func == (lhs: UserObject, rhs: UserObject) -> Bool {
    return lhs.id == rhs.id &&
      lhs.name == rhs.name &&
      lhs.externalId == rhs.externalId &&
      lhs.profileURL == rhs.profileURL &&
      lhs.email == rhs.email &&
      lhs.created == rhs.created &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag &&
      lhs.custom?.allSatisfy {
        rhs.custom?[$0]?.scalarValue == $1.scalarValue
      } ?? true
  }
}

// MARK: - Membership Response

public struct UserObjectMembership: PubNubMembership, PubNubIdentifiable, Codable, Equatable {
  public let id: String
  public var spaceId: String {
    return id
  }

  var spaceObject: SpaceObject?
  public var space: PubNubSpace? {
    get { return spaceObject }
    set { spaceObject = try? newValue?.transcode() }
  }

  public let custom: [String: JSONCodableScalar]?

  public let created: Date
  public let updated: Date
  public let eTag: String

  public init(
    id: String,
    custom: [String: JSONCodableScalar]? = nil,
    space: PubNubSpace?,
    created: Date = Date(),
    updated: Date? = nil,
    eTag: String = ""
  ) {
    self.id = id
    self.custom = custom
    spaceObject = try? space?.transcode()
    self.created = created
    self.updated = updated ?? created
    self.eTag = eTag
  }

  public init(from membership: PubNubMembership) throws {
    self.init(
      id: membership.id,
      custom: membership.custom,
      space: membership.space,
      created: membership.created,
      updated: membership.updated,
      eTag: membership.eTag
    )
  }

  enum CodingKeys: String, CodingKey {
    case id
    case spaceObject = "space"
    case custom
    case created
    case updated
    case eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(String.self, forKey: .id)
    spaceObject = try container.decodeIfPresent(SpaceObject.self, forKey: .spaceObject)
    custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
    created = try container.decode(Date.self, forKey: .created)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encodeIfPresent(spaceObject, forKey: .spaceObject)
    try container.encodeIfPresent(custom?.mapValues { $0.codableValue }, forKey: .custom)
    try container.encode(created, forKey: .created)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)
  }

  public static func == (lhs: UserObjectMembership, rhs: UserObjectMembership) -> Bool {
    return lhs.id == rhs.id &&
      lhs.spaceObject == rhs.spaceObject &&
      lhs.created == lhs.created &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag &&
      lhs.custom?.allSatisfy {
        rhs.custom?[$0]?.scalarValue == $1.scalarValue
      } ?? true
  }
}

// MARK: - Deprecated (v2.0.0)

public typealias ObjectIdentifiable = PubNubIdentifiable & ObjectCustomizable & JSONCodable

public typealias SpaceMembership = UserObjectMembership

public typealias UserObjectsResponsePayload = UsersResponsePayload<UserObject>
extension UserObjectsResponsePayload {
  public var users: [T] {
    return data
  }
}

public typealias UserMembershipsResponsePayload = MembershipsResponsePayload<UserObjectMembership>
extension UserMembershipsResponsePayload {
  public var memberships: [T] {
    return data
  }

  // swiftlint:disable:next file_length
}
