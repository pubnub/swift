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
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let metadata = try container.nestedContainer(keyedBy: MetadataCodingKeys.self, forKey: .metadata)

    version = try container.decode(String.self, forKey: .version)
    source = try metadata.decode(String.self, forKey: .source)

    let action = try metadata.decode(Action.self, forKey: .event)
    let type = try metadata.decode(ObjectType.self, forKey: .type)
    let rawClassName = try metadata.decode(String.self, forKey: .className)
    let classVersion = try metadata.decode(Int.self, forKey: .classVersion)
    let (className, classLevel) = Self.parseClassName(rawClassName)

    let data = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
    let identifier = try data.decode(String.self, forKey: .id)

    switch (type, action) {
    case (.entity, .create), (.entity, .update):
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
    case (.relationship, .create), (.relationship, .update):
      let relationship = PubNubDataSyncRelationship(
        id: identifier,
        className: className,
        classLevel: classLevel,
        classVersion: classVersion,
        entityAId: try data.decode(String.self, forKey: .entityAId),
        entityBId: try data.decode(String.self, forKey: .entityBId),
        createdAt: try data.decode(Date.self, forKey: .createdAt),
        updatedAt: try data.decode(Date.self, forKey: .updatedAt),
        eTag: try data.decode(String.self, forKey: .eTag),
        expiresAt: try data.decode(Date.self, forKey: .expiresAt),
        status: try data.decodeIfPresent(String.self, forKey: .status),
        payload: try data.decodeIfPresent(AnyJSON.self, forKey: .payload)
      )
      event = action == .create ? .relationshipCreated(relationship) : .relationshipUpdated(relationship)
    case (.entity, .delete), (.relationship, .delete):
      let removed = PubNubDataSyncRemovedObject(
        id: identifier,
        className: className,
        classLevel: classLevel,
        classVersion: classVersion,
        deletedAt: try data.decode(Date.self, forKey: .deletedAt)
      )
      event = type == .entity ? .entityDeleted(removed) : .relationshipDeleted(removed)
    }
  }

  private static func parseClassName(_ rawValue: String) -> (String, PubNubDataSyncClassLevel) {
    if rawValue.hasPrefix("::") {
      return (String(rawValue.dropFirst(2)), .subKey)
    } else if rawValue.hasSuffix("::") {
      return (String(rawValue.dropLast(2)), .global)
    } else if rawValue.hasPrefix(":"), rawValue.hasSuffix(":") {
      return (String(rawValue.dropFirst().dropLast()), .account)
    } else {
      return (rawValue, .subKey)
    }
  }
}

extension SubscribeMessagePayload {
  func asDataSyncEvent() -> PubNubDataSyncEvent? {
    try? payload.decode(SubscribeDataSyncPayload.self).event
  }
}
