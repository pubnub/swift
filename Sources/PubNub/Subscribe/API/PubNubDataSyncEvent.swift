//
//  PubNubDataSyncEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// The type of a DataSync entity event.
public enum PubNubDataSyncEntityKind: String, Hashable {
  /// A user, including classes that extend User
  case user
  /// A channel, including classes that extend Channel
  case channel
  /// A custom entity
  case custom
}

/// The type of a DataSync relationship event.
public enum PubNubDataSyncRelationshipKind: String, Hashable {
  /// A membership
  case membership
  /// A custom relationship
  case custom
}

/// A created or updated DataSync entity event.
public struct PubNubDataSyncEntityEvent: Hashable {
  /// The entity type
  public let kind: PubNubDataSyncEntityKind
  /// The created or updated entity
  public let entity: PubNubDataSyncEntity
}

/// A deleted DataSync entity event.
public struct PubNubDataSyncEntityDeletedEvent: Hashable {
  /// The entity type
  public let kind: PubNubDataSyncEntityKind
  /// Information identifying the deleted entity
  public let removed: PubNubDataSyncRemovedObject
}

/// A created or updated DataSync relationship event.
public struct PubNubDataSyncRelationshipEvent: Hashable {
  /// The relationship type
  public let kind: PubNubDataSyncRelationshipKind
  /// The created or updated relationship
  public let relationship: PubNubDataSyncRelationship
}

/// A deleted DataSync relationship event.
public struct PubNubDataSyncRelationshipDeletedEvent: Hashable {
  /// The relationship type
  public let kind: PubNubDataSyncRelationshipKind
  /// Information identifying the deleted relationship
  public let removed: PubNubDataSyncRemovedObject
}

/// A DataSync change received over subscribe.
public struct PubNubDataSyncEvent: Hashable {
  /// The channel the event was received on
  public let channel: String
  /// The channel group or wildcard subscription match (if exists)
  public let subscription: String?
  /// The `Timetoken` for when the event was published
  public let timetoken: Timetoken
  /// The change the event describes
  public let change: Change

  /// Possible DataSync changes
  public enum Change: Hashable {
    /// An entity was created
    case entityCreated(PubNubDataSyncEntityEvent)
    /// An entity was updated
    case entityUpdated(PubNubDataSyncEntityEvent)
    /// An entity was deleted
    case entityDeleted(PubNubDataSyncEntityDeletedEvent)
    /// A relationship was created
    case relationshipCreated(PubNubDataSyncRelationshipEvent)
    /// A relationship was updated
    case relationshipUpdated(PubNubDataSyncRelationshipEvent)
    /// A relationship was deleted
    case relationshipDeleted(PubNubDataSyncRelationshipDeletedEvent)
    /// A change this version of the SDK doesn't recognize.
    case unknown(PubNubDataSyncUnknownEvent)
  }
}

/// A DataSync change whose object type or action this version of the SDK doesn't recognize.
public struct PubNubDataSyncUnknownEvent: Hashable {
  /// The object type received from the server, taken from `metadata.type`
  public let type: String
  /// The action received from the server, taken from `metadata.event`
  public let event: String
  /// The name of the object's class, if the server sent one
  public let className: String?
  /// The level the object's class is registered at, if the server sent one
  public let classLevel: PubNubDataSyncClassLevel?
  /// The version of the object's class, if the server sent one
  public let classVersion: Int?
  /// The unmodified `metadata` object
  public var metadata: JSONCodable? { concreteMetadata }
  /// The unmodified `data` object, if the server sent one
  public var payload: JSONCodable? { concretePayload }

  let concreteMetadata: AnyJSON?
  let concretePayload: AnyJSON?

  init(
    type: String,
    event: String,
    className: String? = nil,
    classLevel: PubNubDataSyncClassLevel? = nil,
    classVersion: Int? = nil,
    metadata: JSONCodable? = nil,
    payload: JSONCodable? = nil
  ) {
    self.type = type
    self.event = event
    self.className = className
    self.classLevel = classLevel
    self.classVersion = classVersion
    self.concreteMetadata = metadata?.codableValue
    self.concretePayload = payload?.codableValue
  }
}

/// A DataSync object, either an entity or a relationship, that was deleted.
public struct PubNubDataSyncRemovedObject: Hashable {
  /// The unique identifier of the deleted object
  public let id: String
  /// The name of the deleted object's class
  public let className: String
  /// The level the deleted object's class is registered at
  public let classLevel: PubNubDataSyncClassLevel
  /// The version of the deleted object's class
  public let classVersion: Int
  /// The date the object was deleted
  public let deletedAt: Date
}
