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

/// Represents a DataSync entity in PubNub DataSync.
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
  /// The date the entity expires, derived from the time-to-live of its class, or `nil` if the class defines no TTL
  public let expiresAt: Date?
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
    expiresAt: Date? = nil,
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

// MARK: - PubNubDataSyncUser

/// Represents a DataSync user in PubNub DataSync.
public struct PubNubDataSyncUser: Hashable {
  /// The unique identifier of the user
  public let id: String
  /// The name of the user's class, which is `User` or a class that extends it
  public let className: String
  /// The level the user's class is registered at
  public let classLevel: PubNubDataSyncClassLevel
  /// The version of the user's class
  public let classVersion: Int
  /// The date the user was created
  public let createdAt: Date
  /// The date the user was last updated
  public let updatedAt: Date
  /// The user revision used for optimistic concurrency
  public let eTag: String
  /// The date the user expires, derived from the time-to-live of its class, or `nil` if the class defines no TTL
  public let expiresAt: Date?
  /// The user status
  public let status: String?
  /// The user fields
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
    expiresAt: Date? = nil,
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

extension PubNubDataSyncUser: Codable {
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

// MARK: - PubNubDataSyncChannel

/// Represents a DataSync channel in PubNub DataSync.
public struct PubNubDataSyncChannel: Hashable {
  /// The unique identifier of the channel
  public let id: String
  /// The name of the channel's class, which is `Channel` or a class that extends it
  public let className: String
  /// The level the channel's class is registered at
  public let classLevel: PubNubDataSyncClassLevel
  /// The version of the channel's class
  public let classVersion: Int
  /// The date the channel was created
  public let createdAt: Date
  /// The date the channel was last updated
  public let updatedAt: Date
  /// The channel revision used for optimistic concurrency
  public let eTag: String
  /// The date the channel expires, derived from the time-to-live of its class, or `nil` if the class defines no TTL
  public let expiresAt: Date?
  /// The channel status
  public let status: String?
  /// The channel fields
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
    expiresAt: Date? = nil,
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

extension PubNubDataSyncChannel: Codable {
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
  /// The level the relationship's class is registered at, or `nil` when the level wasn't reported
  ///
  /// Relationships read through ``PubNub/DataSyncAPI/getRelationships(relationshipClass:entityAId:entityBId:relationshipClassVersion:cursor:limit:filter:filterAdvanced:sort:custom:completion:)``
  /// and its siblings leave this `nil`, because the service doesn't report a level on the relationship resource. Relationships delivered as a
  /// ``PubNubDataSyncEvent`` carry it.
  public let classLevel: PubNubDataSyncClassLevel?
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
  /// The date the relationship expires, derived from the time-to-live of its class, or `nil` if the class defines no TTL
  public let expiresAt: Date?
  /// The relationship status
  public let status: String?
  /// The relationship fields
  public var payload: JSONCodable? { concretePayload }

  let concretePayload: AnyJSON?

  init(
    id: String,
    className: String,
    classLevel: PubNubDataSyncClassLevel? = nil,
    classVersion: Int,
    entityAId: String,
    entityBId: String,
    createdAt: Date,
    updatedAt: Date,
    eTag: String,
    expiresAt: Date? = nil,
    status: String? = nil,
    payload: JSONCodable? = nil
  ) {
    self.id = id
    self.className = className
    self.classLevel = classLevel
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
    case classLevel = "relationshipClassLevel"
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
  /// The unique identifier of the membership
  public let id: String
  /// The unique identifier of the channel the membership belongs to
  public let channelId: String
  /// The unique identifier of the user the membership belongs to
  public let userId: String
  /// The name of the membership's class, which is `Membership` or a class that extends it
  public let className: String
  /// The version of the membership's class
  public let classVersion: Int
  /// The date the membership was created
  public let createdAt: Date
  /// The date the membership was last updated
  public let updatedAt: Date
  /// The membership revision used for optimistic concurrency
  public let eTag: String
  /// The date the membership expires, derived from the time-to-live of its class,
  /// or `nil` if the class defines no TTL
  public let expiresAt: Date?
  /// The membership status
  public let status: String?
  /// The membership fields
  public var payload: JSONCodable? { concretePayload }

  let concretePayload: AnyJSON?

  init(
    id: String,
    channelId: String,
    userId: String,
    className: String,
    classVersion: Int,
    createdAt: Date,
    updatedAt: Date,
    eTag: String,
    expiresAt: Date? = nil,
    status: String? = nil,
    payload: JSONCodable? = nil
  ) {
    self.id = id
    self.channelId = channelId
    self.userId = userId
    self.className = className
    self.classVersion = classVersion
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.eTag = eTag
    self.expiresAt = expiresAt
    self.status = status
    self.concretePayload = payload?.codableValue
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
}
