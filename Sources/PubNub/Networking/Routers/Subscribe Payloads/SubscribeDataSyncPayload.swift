//
//  SubscribeDataSyncPayload.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

struct SubscribeDataSyncPayload {
  let version: String
  let source: String
  let event: PubNubDataSyncEvent

  enum Action: String, Codable, Hashable {
    case create
    case update
    case delete
  }

  enum ObjectType: String, Codable, Hashable {
    case entity
    case relationship
    case user
    case channel
    case membership
  }
}

extension SubscribeDataSyncPayload: Decodable {
  enum CodingKeys: String, CodingKey {
    case version
    case metadata
    case data
  }

  enum MetadataCodingKeys: String, CodingKey {
    case event
    case source
    case type
    case className
    case classLevel
    case classVersion
  }

  enum DataCodingKeys: String, CodingKey {
    case id
    case createdAt
    case updatedAt
    case deletedAt
    case eTag
    case expiresAt
    case status
    case payload
    case entityAId
    case entityBId
    case channelId
    case userId
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let metadata = try container.nestedContainer(keyedBy: MetadataCodingKeys.self, forKey: .metadata)

    version = try container.decode(String.self, forKey: .version)
    source = try metadata.decode(String.self, forKey: .source)

    let action = try metadata.decode(Action.self, forKey: .event)
    let type = try metadata.decode(ObjectType.self, forKey: .type)
    let className = try metadata.decode(String.self, forKey: .className)
    let classLevel = PubNubDataSyncClassLevel(stringValue: try metadata.decode(String.self, forKey: .classLevel))
    let classVersion = try metadata.decode(Int.self, forKey: .classVersion)

    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
    let identifier = try data.decode(String.self, forKey: .id)

    switch (type, action) {
    case (.entity, .create), (.entity, .update), (.user, .create), (.user, .update), (.channel, .create), (.channel, .update):
      let entity = PubNubDataSyncEntity(
        id: identifier,
        className: className,
        classLevel: classLevel,
        classVersion: classVersion,
        createdAt: try data.decode(Date.self, forKey: .createdAt),
        updatedAt: try data.decode(Date.self, forKey: .updatedAt),
        eTag: try data.decode(String.self, forKey: .eTag),
        expiresAt: try data.decode(Date.self, forKey: .expiresAt),
        status: try data.decodeIfPresent(String.self, forKey: .status),
        payload: try data.decodeIfPresent(AnyJSON.self, forKey: .payload)
      )
      event = action == .create ? .entityCreated(entity) : .entityUpdated(entity)
    case (.relationship, .create), (.relationship, .update), (.membership, .create), (.membership, .update):
      // A membership frames its two sides as `channelId` and `userId`
      let entityAKey: DataCodingKeys = type == .membership ? .channelId : .entityAId
      let entityBKey: DataCodingKeys = type == .membership ? .userId : .entityBId

      let relationship = PubNubDataSyncRelationship(
        id: identifier,
        className: className,
        classVersion: classVersion,
        entityAId: try data.decode(String.self, forKey: entityAKey),
        entityBId: try data.decode(String.self, forKey: entityBKey),
        createdAt: try data.decode(Date.self, forKey: .createdAt),
        updatedAt: try data.decode(Date.self, forKey: .updatedAt),
        eTag: try data.decode(String.self, forKey: .eTag),
        expiresAt: try data.decode(Date.self, forKey: .expiresAt),
        status: try data.decodeIfPresent(String.self, forKey: .status),
        payload: try data.decodeIfPresent(AnyJSON.self, forKey: .payload)
      )
      event = action == .create ? .relationshipCreated(relationship) : .relationshipUpdated(relationship)
    case (.entity, .delete), (.user, .delete), (.channel, .delete):
      let removed = PubNubDataSyncRemovedObject(
        id: identifier,
        className: className,
        classLevel: classLevel,
        classVersion: classVersion,
        deletedAt: try data.decode(Date.self, forKey: .deletedAt)
      )
      event = .entityDeleted(removed)
    case (.relationship, .delete), (.membership, .delete):
      event = .relationshipDeleted(
        PubNubDataSyncRemovedRelationship(
          id: identifier,
          className: className,
          classVersion: classVersion,
          deletedAt: try data.decode(Date.self, forKey: .deletedAt)
        )
      )
    }
  }
}

extension SubscribeMessagePayload {
  func asDataSyncEvent() -> PubNubDataSyncEvent? {
    try? payload.decode(SubscribeDataSyncPayload.self).event
  }
}
