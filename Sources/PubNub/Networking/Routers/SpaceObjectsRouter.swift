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
      adding: [ObjectIdentifiable], updating: [ObjectIdentifiable], removing: [ObjectIdentifiable],
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
    case .fetch(let spaceID, _):
      path = "/v1/objects/\(subscribeKey)/spaces/\(spaceID.urlEncodeSlash)"
    case .create:
      path = "/v1/objects/\(subscribeKey)/spaces"
    case .update(let pace, _):
      path = "/v1/objects/\(subscribeKey)/spaces/\(pace.id.urlEncodeSlash)"
    case let .delete(spaceID):
      path = "/v1/objects/\(subscribeKey)/spaces/\(spaceID.urlEncodeSlash)"
    case let .fetchMembers(parameters):
      path = "/v1/objects/\(subscribeKey)/spaces/\(parameters.spaceID.urlEncodeSlash)/users"
    case let .modifyMembers(parameters):
      path = "/v1/objects/\(subscribeKey)/spaces/\(parameters.spaceID.urlEncodeSlash)/users"
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
    case .create(let user, _):
      return user.jsonDataResult.map { .some($0) }
    case .update(let user, _):
      return user.jsonDataResult.map { .some($0) }
    case let .modifyMembers(_, adding, updating, removing, _, _, _, _, _):
      let changeset = ObjectIdentifiableChangeset(add: adding,
                                                  update: updating,
                                                  remove: removing)
      return changeset.encodableJSONData.map { .some($0) }
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
    case .fetch(let userID, _):
      return isInvalidForReason((userID.isEmpty, ErrorDescription.emptySpaceID))
    case .create(let user, _):
      return isInvalidForReason((!user.isValid, ErrorDescription.invalidPubNubSpace))
    case .update(let user, _):
      return isInvalidForReason((!user.isValid, ErrorDescription.invalidPubNubSpace))
    case let .delete(userID):
      return isInvalidForReason((userID.isEmpty, ErrorDescription.emptySpaceID))
    case let .fetchMembers(parameters):
      return isInvalidForReason((parameters.spaceID.isEmpty, ErrorDescription.emptySpaceID))
    case let .modifyMembers(parameters):
      return isInvalidForReason(
        (parameters.spaceID.isEmpty, ErrorDescription.emptySpaceID),
        (!parameters.adding.allSatisfy { $0.isValid }, ErrorDescription.invalidJoiningMember),
        (!parameters.updating.allSatisfy { $0.isValid }, ErrorDescription.invalidUpdatingMember),
        (!parameters.removing.allSatisfy { $0.isValid }, ErrorDescription.invalidLeavingMember)
      )
    }
  }
}

// MARK: - Space Protocols

public protocol PubNubSpace: ObjectIdentifiable {
  var name: String { get }
  var spaceDescription: String? { get }
}

extension PubNubSpace {
  var isValid: Bool {
    return !id.isEmpty && !name.isEmpty
  }

  var spaceObject: SpaceObject {
    guard let object = self as? SpaceObject else {
      return SpaceObject(self)
    }
    return object
  }
}

extension PubNubSpace where Self: Equatable {
  func isEqual(_ other: PubNubSpace?) -> Bool {
    return id == other?.id &&
      name == other?.name &&
      spaceDescription == other?.spaceDescription &&
      custom?.allSatisfy {
        other?.custom?[$0]?.scalarValue == $1.scalarValue
      } ?? true
  }
}

public protocol UpdatableSpace: PubNubSpace {
  var updated: Date { get }
  var eTag: String { get }
}

extension UpdatableSpace {
  var spaceObject: SpaceObject {
    guard let object = self as? SpaceObject else {
      return SpaceObject(updatable: self)
    }
    return object
  }
}

// MARK: - Response Decoder

struct SpaceObjectResponseDecoder: ResponseDecoder {
  typealias Payload = SpaceObjectResponsePayload
}

struct SpaceObjectsResponseDecoder: ResponseDecoder {
  typealias Payload = SpaceObjectsResponsePayload
}

// MARK: - Membership Response Decoder

struct SpaceMembershipObjectsResponseDecoder: ResponseDecoder {
  typealias Payload = SpaceMembershipResponsePayload
}

// MARK: - Response

public struct SpaceObject: Codable, Equatable, UpdatableSpace {
  public let id: String
  public let name: String
  public let spaceDescription: String?
  public let created: Date
  public let updated: Date
  public let eTag: String

  public var custom: [String: JSONCodableScalar]? {
    return customType
  }

  let customType: [String: JSONCodableScalarType]?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case spaceDescription = "description"
    case customType = "custom"
    case created
    case updated
    case eTag
  }

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
    customType = custom?.mapValues { $0.scalarValue }
    self.created = created
    self.updated = updated ?? created
    self.eTag = eTag
  }

  public init(_ spaceProto: PubNubSpace) {
    self.init(
      name: spaceProto.name,
      id: spaceProto.id,
      spaceDescription: spaceProto.spaceDescription,
      custom: spaceProto.custom
    )
  }

  public init(updatable: UpdatableSpace) {
    self.init(
      name: updatable.name,
      id: updatable.id,
      spaceDescription: updatable.spaceDescription,
      custom: updatable.custom,
      updated: updatable.updated,
      eTag: updatable.eTag
    )
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    spaceDescription = try container.decodeIfPresent(String.self, forKey: .spaceDescription)
    customType = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .customType)
    created = try container.decodeIfPresent(Date.self, forKey: .created) ?? Date.distantPast
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)
  }
}

public struct SpaceObjectResponsePayload: Codable, Equatable {
  public let status: Int
  public let space: SpaceObject

  enum CodingKeys: String, CodingKey {
    case status
    case space = "data"
  }
}

public struct SpaceObjectsResponsePayload: Codable {
  public let status: Int
  public let spaces: [SpaceObject]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?

  enum CodingKeys: String, CodingKey {
    case status
    case spaces = "data"
    case totalCount
    case next
    case prev
  }
}

// MARK: - Membership Response

public struct UserMembership: Codable, Equatable {
  public let id: String
  public let customType: [String: JSONCodableScalarType]
  public let user: UserObject?
  public let created: Date
  public let updated: Date
  public let eTag: String

  enum CodingKeys: String, CodingKey {
    case id
    case user
    case customType = "custom"
    case created
    case updated
    case eTag
  }

  public init(
    id: String,
    custom: [String: JSONCodableScalarType] = [:],
    user: PubNubUser?,
    created: Date = Date(),
    updated: Date? = nil,
    eTag: String = ""
  ) {
    self.id = id
    customType = custom.mapValues { $0.scalarValue }
    self.user = user?.userObject
    self.created = created
    self.updated = updated ?? created
    self.eTag = eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(String.self, forKey: .id)
    user = try container.decodeIfPresent(UserObject.self, forKey: .user)
    customType = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .customType) ?? [:]
    created = try container.decode(Date.self, forKey: .created)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)
  }
}

public struct SpaceMembershipResponsePayload: Codable {
  public let status: Int
  public let memberships: [UserMembership]
  public let totalCount: Int?
  public let next: String?
  public let prev: String?

  enum CodingKeys: String, CodingKey {
    case status
    case memberships = "data"
    case totalCount
    case next
    case prev
  }

  // swiftlint:disable:next file_length
}
