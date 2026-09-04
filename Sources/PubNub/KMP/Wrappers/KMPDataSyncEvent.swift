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
  @objc public let entity: KMPDataSyncEntity

  init(entity: KMPDataSyncEntity) {
    self.entity = entity
    super.init(event: "entityCreated")
  }
}

// MARK: - KMPDataSyncEntityUpdatedResult

@objc
public class KMPDataSyncEntityUpdatedResult: KMPDataSyncEvent {
  @objc public let entity: KMPDataSyncEntity

  init(entity: KMPDataSyncEntity) {
    self.entity = entity
    super.init(event: "entityUpdated")
  }
}

// MARK: - KMPDataSyncEntityDeletedResult

@objc
public class KMPDataSyncEntityDeletedResult: KMPDataSyncEvent {
  @objc public let removedObject: KMPDataSyncRemovedObject

  init(removedObject: KMPDataSyncRemovedObject) {
    self.removedObject = removedObject
    super.init(event: "entityDeleted")
  }
}

// MARK: - KMPDataSyncRelationshipCreatedResult

@objc
public class KMPDataSyncRelationshipCreatedResult: KMPDataSyncEvent {
  @objc public let relationship: KMPDataSyncRelationship

  init(relationship: KMPDataSyncRelationship) {
    self.relationship = relationship
    super.init(event: "relationshipCreated")
  }
}

// MARK: - KMPDataSyncRelationshipUpdatedResult

@objc
public class KMPDataSyncRelationshipUpdatedResult: KMPDataSyncEvent {
  @objc public let relationship: KMPDataSyncRelationship

  init(relationship: KMPDataSyncRelationship) {
    self.relationship = relationship
    super.init(event: "relationshipUpdated")
  }
}

// MARK: - KMPDataSyncRelationshipDeletedResult

@objc
public class KMPDataSyncRelationshipDeletedResult: KMPDataSyncEvent {
  @objc public let removedObject: KMPDataSyncRemovedRelationship

  init(removedObject: KMPDataSyncRemovedRelationship) {
    self.removedObject = removedObject
    super.init(event: "relationshipDeleted")
  }
}

// MARK: - KMPDataSyncRemovedObject

@objc
public class KMPDataSyncRemovedObject: NSObject {
  @objc public let id: String
  // Named `objectClass` rather than `className` because `NSObject` already exposes a `className` selector
  @objc public let objectClass: String
  @objc public let classLevel: String
  @objc public let classVersion: Int
  @objc public let deletedAt: Date

  init(removedObject: PubNubDataSyncRemovedObject) {
    self.id = removedObject.id
    self.objectClass = removedObject.className
    self.classLevel = removedObject.classLevel.stringValue
    self.classVersion = removedObject.classVersion
    self.deletedAt = removedObject.deletedAt
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
    case .entityCreated(let entity):
      return KMPDataSyncEntityCreatedResult(entity: KMPDataSyncEntity(entity: entity))
    case .entityUpdated(let entity):
      return KMPDataSyncEntityUpdatedResult(entity: KMPDataSyncEntity(entity: entity))
    case .entityDeleted(let removedObject):
      return KMPDataSyncEntityDeletedResult(removedObject: KMPDataSyncRemovedObject(removedObject: removedObject))
    case .relationshipCreated(let relationship):
      return KMPDataSyncRelationshipCreatedResult(relationship: KMPDataSyncRelationship(relationship: relationship))
    case .relationshipUpdated(let relationship):
      return KMPDataSyncRelationshipUpdatedResult(relationship: KMPDataSyncRelationship(relationship: relationship))
    case .relationshipDeleted(let removedRelationship):
      return KMPDataSyncRelationshipDeletedResult(
        removedObject: KMPDataSyncRemovedRelationship(removedRelationship: removedRelationship)
      )
    }
  }
}
