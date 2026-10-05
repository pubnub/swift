//
//  KMPDataSyncEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
//
// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
// While these symbols are public, they are intended strictly for internal usage.
//
// External developers should refrain from directly using these symbols in their code, as their implementation details
// may change in future versions of the framework, potentially leading to breaking changes.

import Foundation

// MARK: - KMPDataSyncEvent

@objc
public class KMPDataSyncEvent: NSObject {
  @objc public let event: String

  init(event: String = "") {
    self.event = event
  }
}

// MARK: - KMPDataSyncEntityCreatedResult

@objc
public class KMPDataSyncEntityCreatedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let entity: KMPDataSyncEntity

  init(entityEvent: PubNubDataSyncEntityEvent) {
    self.kind = entityEvent.kind.rawValue
    self.entity = KMPDataSyncEntity(entity: entityEvent.entity)

    super.init(event: "entityCreated")
  }
}

// MARK: - KMPDataSyncEntityUpdatedResult

@objc
public class KMPDataSyncEntityUpdatedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let entity: KMPDataSyncEntity

  init(entityEvent: PubNubDataSyncEntityEvent) {
    self.kind = entityEvent.kind.rawValue
    self.entity = KMPDataSyncEntity(entity: entityEvent.entity)

    super.init(event: "entityUpdated")
  }
}

// MARK: - KMPDataSyncEntityDeletedResult

@objc
public class KMPDataSyncEntityDeletedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let removedEntity: KMPDataSyncRemovedEntity

  init(entityEvent: PubNubDataSyncEntityDeletedEvent) {
    self.kind = entityEvent.kind.rawValue
    self.removedEntity = KMPDataSyncRemovedEntity(removedEntity: entityEvent.removed)

    super.init(event: "entityDeleted")
  }
}

// MARK: - KMPDataSyncRelationshipCreatedResult

@objc
public class KMPDataSyncRelationshipCreatedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let relationship: KMPDataSyncRelationship

  init(relationshipEvent: PubNubDataSyncRelationshipEvent) {
    self.kind = relationshipEvent.kind.rawValue
    self.relationship = KMPDataSyncRelationship(relationship: relationshipEvent.relationship)

    super.init(event: "relationshipCreated")
  }
}

// MARK: - KMPDataSyncRelationshipUpdatedResult

@objc
public class KMPDataSyncRelationshipUpdatedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let relationship: KMPDataSyncRelationship

  init(relationshipEvent: PubNubDataSyncRelationshipEvent) {
    self.kind = relationshipEvent.kind.rawValue
    self.relationship = KMPDataSyncRelationship(relationship: relationshipEvent.relationship)

    super.init(event: "relationshipUpdated")
  }
}

// MARK: - KMPDataSyncRelationshipDeletedResult

@objc
public class KMPDataSyncRelationshipDeletedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let removedRelationship: KMPDataSyncRemovedRelationship

  init(relationshipEvent: PubNubDataSyncRelationshipDeletedEvent) {
    self.kind = relationshipEvent.kind.rawValue
    self.removedRelationship = KMPDataSyncRemovedRelationship(removedRelationship: relationshipEvent.removed)

    super.init(event: "relationshipDeleted")
  }
}

// MARK: - KMPDataSyncRemovedEntity

@objc
public class KMPDataSyncRemovedEntity: NSObject {
  @objc public let id: String
  // Named `objectClass` rather than `className` because `NSObject` already exposes a `className` selector
  @objc public let objectClass: String
  @objc public let classLevel: String
  @objc public let classVersion: Int
  @objc public let deletedAt: Date

  init(removedEntity: PubNubDataSyncRemovedEntity) {
    self.id = removedEntity.id
    self.objectClass = removedEntity.className
    self.classLevel = removedEntity.classLevel.stringValue
    self.classVersion = removedEntity.classVersion
    self.deletedAt = removedEntity.deletedAt
  }
}

// MARK: - KMPDataSyncRemovedRelationship

@objc
public class KMPDataSyncRemovedRelationship: NSObject {
  @objc public let id: String
  // Named `objectClass` rather than `className` because `NSObject` already exposes a `className` selector
  @objc public let objectClass: String
  @objc public let classVersion: Int
  @objc public let deletedAt: Date

  init(removedRelationship: PubNubDataSyncRemovedRelationship) {
    self.id = removedRelationship.id
    self.objectClass = removedRelationship.className
    self.classVersion = removedRelationship.classVersion
    self.deletedAt = removedRelationship.deletedAt
  }
}

// MARK: - KMPDataSyncEvent (Factory Method)

extension KMPDataSyncEvent {
  static func from(event: PubNubDataSyncEvent) -> KMPDataSyncEvent {
    switch event {
    case .entityCreated(let entityEvent):
      return KMPDataSyncEntityCreatedResult(entityEvent: entityEvent)
    case .entityUpdated(let entityEvent):
      return KMPDataSyncEntityUpdatedResult(entityEvent: entityEvent)
    case .entityDeleted(let entityEvent):
      return KMPDataSyncEntityDeletedResult(entityEvent: entityEvent)
    case .relationshipCreated(let relationshipEvent):
      return KMPDataSyncRelationshipCreatedResult(relationshipEvent: relationshipEvent)
    case .relationshipUpdated(let relationshipEvent):
      return KMPDataSyncRelationshipUpdatedResult(relationshipEvent: relationshipEvent)
    case .relationshipDeleted(let relationshipEvent):
      return KMPDataSyncRelationshipDeletedResult(relationshipEvent: relationshipEvent)
    }
  }
}
