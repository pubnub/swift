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
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let timetoken: Timetoken

  init(channel: String = "", subscription: String? = nil, timetoken: Timetoken = 0) {
    self.channel = channel
    self.subscription = subscription
    self.timetoken = timetoken
  }
}

// MARK: - KMPDataSyncEntityCreatedResult

@objc
public class KMPDataSyncEntityCreatedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let entity: KMPDataSyncEntity

  init(entityEvent: PubNubDataSyncEntityEvent, channel: String, subscription: String?, timetoken: Timetoken) {
    self.kind = entityEvent.kind.rawValue
    self.entity = KMPDataSyncEntity(entity: entityEvent.entity)

    super.init(channel: channel, subscription: subscription, timetoken: timetoken)
  }
}

// MARK: - KMPDataSyncEntityUpdatedResult

@objc
public class KMPDataSyncEntityUpdatedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let entity: KMPDataSyncEntity

  init(entityEvent: PubNubDataSyncEntityEvent, channel: String, subscription: String?, timetoken: Timetoken) {
    self.kind = entityEvent.kind.rawValue
    self.entity = KMPDataSyncEntity(entity: entityEvent.entity)

    super.init(channel: channel, subscription: subscription, timetoken: timetoken)
  }
}

// MARK: - KMPDataSyncEntityDeletedResult

@objc
public class KMPDataSyncEntityDeletedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let removedEntity: KMPDataSyncRemovedEntity

  init(entityEvent: PubNubDataSyncEntityDeletedEvent, channel: String, subscription: String?, timetoken: Timetoken) {
    self.kind = entityEvent.kind.rawValue
    self.removedEntity = KMPDataSyncRemovedEntity(removedEntity: entityEvent.removed)

    super.init(channel: channel, subscription: subscription, timetoken: timetoken)
  }
}

// MARK: - KMPDataSyncRelationshipCreatedResult

@objc
public class KMPDataSyncRelationshipCreatedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let relationship: KMPDataSyncRelationship

  init(relationshipEvent: PubNubDataSyncRelationshipEvent, channel: String, subscription: String?, timetoken: Timetoken) {
    self.kind = relationshipEvent.kind.rawValue
    self.relationship = KMPDataSyncRelationship(relationship: relationshipEvent.relationship)

    super.init(channel: channel, subscription: subscription, timetoken: timetoken)
  }
}

// MARK: - KMPDataSyncRelationshipUpdatedResult

@objc
public class KMPDataSyncRelationshipUpdatedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let relationship: KMPDataSyncRelationship

  init(relationshipEvent: PubNubDataSyncRelationshipEvent, channel: String, subscription: String?, timetoken: Timetoken) {
    self.kind = relationshipEvent.kind.rawValue
    self.relationship = KMPDataSyncRelationship(relationship: relationshipEvent.relationship)

    super.init(channel: channel, subscription: subscription, timetoken: timetoken)
  }
}

// MARK: - KMPDataSyncRelationshipDeletedResult

@objc
public class KMPDataSyncRelationshipDeletedResult: KMPDataSyncEvent {
  @objc public let kind: String
  @objc public let removedRelationship: KMPDataSyncRemovedRelationship

  init(relationshipEvent: PubNubDataSyncRelationshipDeletedEvent, channel: String, subscription: String?, timetoken: Timetoken) {
    self.kind = relationshipEvent.kind.rawValue
    self.removedRelationship = KMPDataSyncRemovedRelationship(removedRelationship: relationshipEvent.removed)

    super.init(channel: channel, subscription: subscription, timetoken: timetoken)
  }
}

// MARK: - KMPDataSyncUnknownResult

@objc
public class KMPDataSyncUnknownResult: KMPDataSyncEvent {
  @objc public let type: String
  @objc public let event: String
  // Named `objectClass` rather than `className` because `NSObject` already exposes a `className` selector
  @objc public let objectClass: String?
  @objc public let classLevel: String?
  @objc public let classVersion: NSNumber?
  @objc public let metadata: KMPAnyJSON?
  @objc public let payload: KMPAnyJSON?

  init(unknownEvent: PubNubDataSyncUnknownEvent, channel: String, subscription: String?, timetoken: Timetoken) {
    self.type = unknownEvent.type
    self.event = unknownEvent.event
    self.objectClass = unknownEvent.className
    self.classLevel = unknownEvent.classLevel?.stringValue
    self.classVersion = if let version = unknownEvent.classVersion { NSNumber(value: version) } else { nil }
    self.metadata = if let metadata = unknownEvent.concreteMetadata { KMPAnyJSON(metadata) } else { nil }
    self.payload = if let payload = unknownEvent.concretePayload { KMPAnyJSON(payload) } else { nil }

    super.init(channel: channel, subscription: subscription, timetoken: timetoken)
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
  @objc public let classLevel: String
  @objc public let classVersion: Int
  @objc public let deletedAt: Date

  init(removedRelationship: PubNubDataSyncRemovedRelationship) {
    self.id = removedRelationship.id
    self.objectClass = removedRelationship.className
    self.classLevel = removedRelationship.classLevel.stringValue
    self.classVersion = removedRelationship.classVersion
    self.deletedAt = removedRelationship.deletedAt
  }
}

// MARK: - KMPDataSyncEvent (Factory Method)

extension KMPDataSyncEvent {
  static func from(event: PubNubDataSyncEvent) -> KMPDataSyncEvent {
    let channel = event.channel
    let subscription = event.subscription
    let timetoken = event.timetoken

    switch event.change {
    case .entityCreated(let entityEvent):
      return KMPDataSyncEntityCreatedResult(
        entityEvent: entityEvent,
        channel: channel, subscription: subscription, timetoken: timetoken
      )
    case .entityUpdated(let entityEvent):
      return KMPDataSyncEntityUpdatedResult(
        entityEvent: entityEvent,
        channel: channel, subscription: subscription, timetoken: timetoken
      )
    case .entityDeleted(let entityEvent):
      return KMPDataSyncEntityDeletedResult(
        entityEvent: entityEvent,
        channel: channel, subscription: subscription, timetoken: timetoken
      )
    case .relationshipCreated(let relationshipEvent):
      return KMPDataSyncRelationshipCreatedResult(
        relationshipEvent: relationshipEvent,
        channel: channel, subscription: subscription, timetoken: timetoken
      )
    case .relationshipUpdated(let relationshipEvent):
      return KMPDataSyncRelationshipUpdatedResult(
        relationshipEvent: relationshipEvent,
        channel: channel, subscription: subscription, timetoken: timetoken
      )
    case .relationshipDeleted(let relationshipEvent):
      return KMPDataSyncRelationshipDeletedResult(
        relationshipEvent: relationshipEvent,
        channel: channel, subscription: subscription, timetoken: timetoken
      )
    case .unknown(let unknownEvent):
      return KMPDataSyncUnknownResult(
        unknownEvent: unknownEvent,
        channel: channel, subscription: subscription, timetoken: timetoken
      )
    }
  }
}
