//
//  PubNubDataSync.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// The level a DataSync class is registered at
public enum PubNubDataSyncClassLevel: Hashable {
  /// A class shared across all accounts
  case global
  /// A class scoped to the account
  ///
  /// - Important: Not supported yet; support for account-level classes is planned for a future release
  case account
  /// A class scoped to the subscribe key
  case subKey
  /// A level this version of the SDK doesn't recognize, along with the value received from the server
  case unknown(String)

  /// The value used to represent the level on the wire
  public var stringValue: String {
    switch self {
    case .global:
      return "Global"
    case .account:
      return "Account"
    case .subKey:
      return "SubKey"
    case let .unknown(rawValue):
      return rawValue
    }
  }

  init(stringValue: String) {
    switch stringValue {
    case "Global":
      self = .global
    case "Account":
      self = .account
    case "SubKey":
      self = .subKey
    default:
      self = .unknown(stringValue)
    }
  }
}

extension PubNubDataSyncClassLevel: Codable {
  public init(from decoder: Decoder) throws {
    self.init(stringValue: try decoder.singleValueContainer().decode(String.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(stringValue)
  }
}

// MARK: - PubNubDataSyncEntity

/// Represents a DataSync entity, including specialized user and channel entities.
public struct PubNubDataSyncEntity: Hashable {
  /// The unique identifier of the entity
  public let id: String
  /// The name of the entity's class
  public let className: String
  /// The level the entity's class is registered at
  public let classLevel: PubNubDataSyncClassLevel
  /// The version of the entity's class
  public let classVersion: Int
  /// The date the entity was created
  public let createdAt: Date
  /// The date the entity was last updated
  public let updatedAt: Date
  /// The entity revision used for optimistic concurrency
  public let eTag: String
  /// The date the entity expires, derived from the time-to-live of its class
  public let expiresAt: Date
  /// The entity status
  public let status: String?
  /// The entity fields
  public var payload: JSONCodable? { concretePayload }

  let concretePayload: AnyJSON?

  init(
    id: String,
    className: String,
    classLevel: PubNubDataSyncClassLevel,
    classVersion: Int,
    createdAt: Date,
    updatedAt: Date,
    eTag: String,
    expiresAt: Date,
    status: String? = nil,
    payload: JSONCodable? = nil
  ) {
    self.id = id
    self.className = className
    self.classLevel = classLevel
    self.classVersion = classVersion
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.eTag = eTag
    self.expiresAt = expiresAt
    self.status = status
    self.concretePayload = payload?.codableValue
  }
}

extension PubNubDataSyncEntity: Codable {
  enum CodingKeys: String, CodingKey {
    case id
    case className = "entityClass"
    case classLevel = "entityClassLevel"
    case classVersion = "entityClassVersion"
    case createdAt
    case updatedAt
    case eTag
    case expiresAt
    case status
    case concretePayload = "payload"
  }
}

// MARK: - PubNubDataSyncRelationship

/// Represents a DataSync relationship connecting two entities in PubNub DataSync.
public struct PubNubDataSyncRelationship: Hashable {
  /// The unique identifier of the relationship
  public let id: String
  /// The name of the relationship's class
  public let className: String
  /// The version of the relationship's class
  public let classVersion: Int
  /// The unique identifier of the entity on side A of the relationship
  public let entityAId: String
  /// The unique identifier of the entity on side B of the relationship
  public let entityBId: String
  /// The date the relationship was created
  public let createdAt: Date
  /// The date the relationship was last updated
  public let updatedAt: Date
  /// The relationship revision used for optimistic concurrency
  public let eTag: String
  /// The date the relationship expires, derived from the time-to-live of its class
  public let expiresAt: Date
  /// The relationship status
  public let status: String?
  /// The relationship fields
  public var payload: JSONCodable? { concretePayload }

  let concretePayload: AnyJSON?

  init(
    id: String,
    className: String,
    classVersion: Int,
    entityAId: String,
    entityBId: String,
    createdAt: Date,
    updatedAt: Date,
    eTag: String,
    expiresAt: Date,
    status: String? = nil,
    payload: JSONCodable? = nil
  ) {
    self.id = id
    self.className = className
    self.classVersion = classVersion
    self.entityAId = entityAId
    self.entityBId = entityBId
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.eTag = eTag
    self.expiresAt = expiresAt
    self.status = status
    self.concretePayload = payload?.codableValue
  }
}

extension PubNubDataSyncRelationship: Codable {
  enum CodingKeys: String, CodingKey {
    case id
    case className = "relationshipClass"
    case classVersion = "relationshipClassVersion"
    case entityAId
    case entityBId
    case createdAt
    case updatedAt
    case eTag
    case expiresAt
    case status
    case concretePayload = "payload"
  }
}

// MARK: - PubNubDataSyncMembership

/// Represents a DataSync membership connecting a channel and a user in PubNub DataSync.
public struct PubNubDataSyncMembership: Hashable {
  /// The membership represented as a general DataSync relationship.
  public let relationship: PubNubDataSyncRelationship
  /// The unique identifier of the membership
  public var id: String { relationship.id }
  /// The unique identifier of the channel the membership belongs to
  public var channelId: String { relationship.entityAId }
  /// The unique identifier of the user the membership belongs to
  public var userId: String { relationship.entityBId }
  /// The name of the membership's class, which is `Membership` or a class that extends it
  public var className: String { relationship.className }
  /// The version of the membership's class
  public var classVersion: Int { relationship.classVersion }
  /// The date the membership was created
  public var createdAt: Date { relationship.createdAt }
  /// The date the membership was last updated
  public var updatedAt: Date { relationship.updatedAt }
  /// The membership revision used for optimistic concurrency
  public var eTag: String { relationship.eTag }
  /// The date the membership expires, derived from the time-to-live of its class
  public var expiresAt: Date { relationship.expiresAt }
  /// The membership status
  public var status: String? { relationship.status }
  /// The membership fields
  public var payload: JSONCodable? { relationship.payload }

  var concretePayload: AnyJSON? { relationship.concretePayload }

  init(
    id: String,
    channelId: String,
    userId: String,
    className: String,
    classVersion: Int,
    createdAt: Date,
    updatedAt: Date,
    eTag: String,
    expiresAt: Date,
    status: String? = nil,
    payload: JSONCodable? = nil
  ) {
    self.relationship = PubNubDataSyncRelationship(
      id: id,
      className: className,
      classVersion: classVersion,
      entityAId: channelId,
      entityBId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      eTag: eTag,
      expiresAt: expiresAt,
      status: status,
      payload: payload
    )
  }
}

extension PubNubDataSyncMembership: Codable {
  enum CodingKeys: String, CodingKey {
    case id
    case channelId
    case userId
    case className = "relationshipClass"
    case classVersion = "relationshipClassVersion"
    case createdAt
    case updatedAt
    case eTag
    case expiresAt
    case status
    case concretePayload = "payload"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.init(
      id: try container.decode(String.self, forKey: .id),
      channelId: try container.decode(String.self, forKey: .channelId),
      userId: try container.decode(String.self, forKey: .userId),
      className: try container.decode(String.self, forKey: .className),
      classVersion: try container.decode(Int.self, forKey: .classVersion),
      createdAt: try container.decode(Date.self, forKey: .createdAt),
      updatedAt: try container.decode(Date.self, forKey: .updatedAt),
      eTag: try container.decode(String.self, forKey: .eTag),
      expiresAt: try container.decode(Date.self, forKey: .expiresAt),
      status: try container.decodeIfPresent(String.self, forKey: .status),
      payload: try container.decodeIfPresent(AnyJSON.self, forKey: .concretePayload)
    )
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encode(channelId, forKey: .channelId)
    try container.encode(userId, forKey: .userId)
    try container.encode(className, forKey: .className)
    try container.encode(classVersion, forKey: .classVersion)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)
    try container.encode(eTag, forKey: .eTag)
    try container.encode(expiresAt, forKey: .expiresAt)
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(concretePayload, forKey: .concretePayload)
  }
}
