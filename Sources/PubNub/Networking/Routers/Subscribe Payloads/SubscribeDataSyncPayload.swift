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
  let change: PubNubDataSyncEvent.Change

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

  // swiftlint:disable:next function_body_length
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let metadata = try container.nestedContainer(keyedBy: MetadataCodingKeys.self, forKey: .metadata)

    let source = try metadata.decode(String.self, forKey: .source)
    let rawAction = try metadata.decode(String.self, forKey: .event)
    let rawType = try metadata.decode(String.self, forKey: .type)

    // Anything that isn't recognizably a DataSync envelope is discarded rather than reported
    // as an unknown change, so `PubNubDataSyncUnknownEvent` only ever describes a DataSync change
    guard source == "data-sync", !rawAction.isEmpty, !rawType.isEmpty else {
      throw DecodingError.dataCorruptedError(
        forKey: .metadata,
        in: container,
        debugDescription: "Not a DataSync envelope: source '\(source)', event '\(rawAction)', type '\(rawType)'"
      )
    }

    // An object type or action added to the service after this SDK version was released is
    // surfaced with its envelope intact instead of being dropped
    guard let action = Action(rawValue: rawAction), let type = ObjectType(rawValue: rawType) else {
      change = .unknown(
        PubNubDataSyncUnknownEvent(
          type: rawType,
          event: rawAction,
          className: try metadata.decodeIfPresent(String.self, forKey: .className),
          classLevel: try metadata.decodeIfPresent(String.self, forKey: .classLevel).map {
            PubNubDataSyncClassLevel(stringValue: $0)
          },
          classVersion: try metadata.decodeIfPresent(Int.self, forKey: .classVersion),
          metadata: try container.decodeIfPresent(AnyJSON.self, forKey: .metadata),
          payload: try container.decodeIfPresent(AnyJSON.self, forKey: .data)
        )
      )
      return
    }

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
      let entityEvent = PubNubDataSyncEntityEvent(
        kind: type.entityKind,
        entity: entity
      )

      change = action == .create ? .entityCreated(entityEvent) : .entityUpdated(entityEvent)

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
      let relationshipEvent = PubNubDataSyncRelationshipEvent(
        kind: type.relationshipKind,
        relationship: relationship
      )

      change = action == .create ? .relationshipCreated(relationshipEvent) : .relationshipUpdated(relationshipEvent)

    case (.entity, .delete), (.user, .delete), (.channel, .delete):
      let removed = PubNubDataSyncRemovedEntity(
        id: identifier,
        className: className,
        classLevel: classLevel,
        classVersion: classVersion,
        deletedAt: try data.decode(Date.self, forKey: .deletedAt)
      )
      change = .entityDeleted(
        PubNubDataSyncEntityDeletedEvent(
          kind: type.entityKind,
          removed: removed
        )
      )

    case (.relationship, .delete), (.membership, .delete):
      change = .relationshipDeleted(
        PubNubDataSyncRelationshipDeletedEvent(
          kind: type.relationshipKind,
          removed: PubNubDataSyncRemovedRelationship(
            id: identifier,
            className: className,
            classVersion: classVersion,
            deletedAt: try data.decode(Date.self, forKey: .deletedAt)
          )
        )
      )
    }
  }
}

private extension SubscribeDataSyncPayload.ObjectType {
  var entityKind: PubNubDataSyncEntityKind {
    switch self {
    case .entity:
      return .custom
    case .user:
      return .user
    case .channel:
      return .channel
    case .relationship, .membership:
      preconditionFailure("A relationship type cannot be converted to an entity kind")
    }
  }

  var relationshipKind: PubNubDataSyncRelationshipKind {
    switch self {
    case .relationship:
      return .custom
    case .membership:
      return .membership
    case .entity, .user, .channel:
      preconditionFailure("An entity type cannot be converted to a relationship kind")
    }
  }
}

extension SubscribeMessagePayload {
  func decodeDataSyncEvent() throws -> PubNubDataSyncEvent {
    PubNubDataSyncEvent(
      channel: channel,
      subscription: subscription,
      timetoken: publishTimetoken.timetoken,
      change: try payload.decode(SubscribeDataSyncPayload.self).change
    )
  }
}
