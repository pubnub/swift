//
//  ObjectsEndpoint.swift
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
      custom.allSatisfy { other?.custom[$0]?.scalarValue == $1.scalarValue }
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
  public let customType: [String: JSONCodableScalarType]
  public let created: Date
  public let updated: Date
  public let eTag: String

  public var custom: [String: JSONCodableScalar] {
    return customType as [String: JSONCodableScalar]
  }

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
    custom: [String: JSONCodableScalar] = [:],
    created: Date = Date.distantPast,
    updated: Date? = nil,
    eTag: String = ""
  ) {
    self.id = id ?? name
    self.name = name
    self.spaceDescription = spaceDescription
    customType = custom.mapValues { $0.scalarValue }
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
    customType = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .customType) ?? [:]
    created = try container.decodeIfPresent(Date.self, forKey: .created) ?? Date.distantPast
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)
  }
}

public struct SpaceObjectResponsePayload: Codable, Equatable {
  public let status: HTTPStatus
  public let space: SpaceObject

  enum CodingKeys: String, CodingKey {
    case status
    case space = "data"
  }
}

public struct SpaceObjectsResponsePayload: Codable {
  public let status: HTTPStatus
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
  public let status: HTTPStatus
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
}
