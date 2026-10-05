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
  public let removed: PubNubDataSyncRemovedEntity
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
  public let removed: PubNubDataSyncRemovedRelationship
}

/// Possible subevents for DataSync
public enum PubNubDataSyncEvent: Hashable {
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
}

/// A DataSync entity that was deleted.
public struct PubNubDataSyncRemovedEntity: Hashable {
  /// The unique identifier of the deleted entity
  public let id: String
  /// The name of the deleted entity's class
  public let className: String
  /// The level the deleted entity's class is registered at
  public let classLevel: PubNubDataSyncClassLevel
  /// The version of the deleted entity's class
  public let classVersion: Int
  /// The date the entity was deleted
  public let deletedAt: Date
}

/// A DataSync relationship that was deleted.
public struct PubNubDataSyncRemovedRelationship: Hashable {
  /// The unique identifier of the deleted relationship
  public let id: String
  /// The name of the deleted relationship's class
  public let className: String
  /// The version of the deleted relationship's class
  public let classVersion: Int
  /// The date the relationship was deleted
  public let deletedAt: Date
}
