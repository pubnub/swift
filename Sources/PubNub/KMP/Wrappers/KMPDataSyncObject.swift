//
//  KMPDataSyncObject.swift
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

// MARK: - KMPDataSyncEntity

@objc
public class KMPDataSyncEntity: NSObject {
  @objc public let id: String
  // Named `entityClass` rather than `className` because `NSObject` already exposes a `className` selector
  @objc public let entityClass: String
  @objc public let classLevel: String
  @objc public let classVersion: Int
  @objc public let createdAt: Date
  @objc public let updatedAt: Date
  @objc public let eTag: String
  @objc public let expiresAt: Date?
  @objc public let status: String?
  @objc public let payload: KMPAnyJSON?

  init(entity: PubNubDataSyncEntity) {
    self.id = entity.id
    self.entityClass = entity.className
    self.classLevel = entity.classLevel.stringValue
    self.classVersion = entity.classVersion
    self.createdAt = entity.createdAt
    self.updatedAt = entity.updatedAt
    self.eTag = entity.eTag
    self.expiresAt = entity.expiresAt
    self.status = entity.status
    self.payload = if let payload = entity.concretePayload { KMPAnyJSON(payload) } else { nil }
  }
}

// MARK: - KMPDataSyncUser

@objc
public class KMPDataSyncUser: NSObject {
  @objc public let id: String
  // Named `entityClass` rather than `className` because `NSObject` already exposes a `className` selector
  @objc public let entityClass: String
  @objc public let classLevel: String
  @objc public let classVersion: Int
  @objc public let createdAt: Date
  @objc public let updatedAt: Date
  @objc public let eTag: String
  @objc public let expiresAt: Date?
  @objc public let status: String?
  @objc public let payload: KMPAnyJSON?

  init(user: PubNubDataSyncEntity) {
    self.id = user.id
    self.entityClass = user.className
    self.classLevel = user.classLevel.stringValue
    self.classVersion = user.classVersion
    self.createdAt = user.createdAt
    self.updatedAt = user.updatedAt
    self.eTag = user.eTag
    self.expiresAt = user.expiresAt
    self.status = user.status
    self.payload = if let payload = user.concretePayload { KMPAnyJSON(payload) } else { nil }
  }
}

// MARK: - KMPDataSyncChannel

@objc
public class KMPDataSyncChannel: NSObject {
  @objc public let id: String
  // Named `entityClass` rather than `className` because `NSObject` already exposes a `className` selector
  @objc public let entityClass: String
  @objc public let classLevel: String
  @objc public let classVersion: Int
  @objc public let createdAt: Date
  @objc public let updatedAt: Date
  @objc public let eTag: String
  @objc public let expiresAt: Date?
  @objc public let status: String?
  @objc public let payload: KMPAnyJSON?

  init(channel: PubNubDataSyncEntity) {
    self.id = channel.id
    self.entityClass = channel.className
    self.classLevel = channel.classLevel.stringValue
    self.classVersion = channel.classVersion
    self.createdAt = channel.createdAt
    self.updatedAt = channel.updatedAt
    self.eTag = channel.eTag
    self.expiresAt = channel.expiresAt
    self.status = channel.status
    self.payload = if let payload = channel.concretePayload { KMPAnyJSON(payload) } else { nil }
  }
}

// MARK: - KMPDataSyncRelationship

@objc
public class KMPDataSyncRelationship: NSObject {
  @objc public let id: String
  // Named `relationshipClass` rather than `className` because `NSObject` already exposes a `className` selector
  @objc public let relationshipClass: String
  @objc public let classVersion: Int
  @objc public let entityAId: String
  @objc public let entityBId: String
  @objc public let createdAt: Date
  @objc public let updatedAt: Date
  @objc public let eTag: String
  @objc public let expiresAt: Date?
  @objc public let status: String?
  @objc public let payload: KMPAnyJSON?

  init(relationship: PubNubDataSyncRelationship) {
    self.id = relationship.id
    self.relationshipClass = relationship.className
    self.classVersion = relationship.classVersion
    self.entityAId = relationship.entityAId
    self.entityBId = relationship.entityBId
    self.createdAt = relationship.createdAt
    self.updatedAt = relationship.updatedAt
    self.eTag = relationship.eTag
    self.expiresAt = relationship.expiresAt
    self.status = relationship.status
    self.payload = if let payload = relationship.concretePayload { KMPAnyJSON(payload) } else { nil }
  }
}

// MARK: - KMPDataSyncMembership

@objc
public class KMPDataSyncMembership: NSObject {
  @objc public let id: String
  @objc public let channelId: String
  @objc public let userId: String
  // Named `relationshipClass` rather than `className` because `NSObject` already exposes a `className` selector
  @objc public let relationshipClass: String
  @objc public let classVersion: Int
  @objc public let createdAt: Date
  @objc public let updatedAt: Date
  @objc public let eTag: String
  @objc public let expiresAt: Date?
  @objc public let status: String?
  @objc public let payload: KMPAnyJSON?

  init(membership: PubNubDataSyncMembership) {
    self.id = membership.id
    self.channelId = membership.channelId
    self.userId = membership.userId
    self.relationshipClass = membership.className
    self.classVersion = membership.classVersion
    self.createdAt = membership.createdAt
    self.updatedAt = membership.updatedAt
    self.eTag = membership.eTag
    self.expiresAt = membership.expiresAt
    self.status = membership.status
    self.payload = if let payload = membership.concretePayload { KMPAnyJSON(payload) } else { nil }
  }
}
