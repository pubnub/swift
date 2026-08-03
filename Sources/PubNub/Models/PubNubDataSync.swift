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

// MARK: - PubNubDataSyncRelationship

/// Represents a DataSync relationship connecting two entities in PubNub DataSync.
public struct PubNubDataSyncRelationship: Hashable {
  /// The unique identifier of the relationship
  public let id: String
  /// The name of the relationship's class
  public let className: String
  /// The level the relationship's class is registered at
  public let classLevel: PubNubDataSyncClassLevel
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

  public init(
    id: String,
    className: String,
    classLevel: PubNubDataSyncClassLevel,
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
