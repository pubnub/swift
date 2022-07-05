//
//  SubscribeObjectPayload.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2020 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

struct SubscribeObjectMetadataPayload {
  let source: String
  let version: String
  let event: Action
  let type: MetadataType
  let subscribeEvent: SubscriptionEvent

  enum Action: String, Codable, Hashable {
    case set
    case delete
  }

  enum MetadataType: String, Codable, Hashable {
    case uuid
    case channel
    case membership
  }

  init(
    source: String,
    version: String,
    event: Action,
    type: MetadataType,
    subscribeEvent: SubscriptionEvent
  ) {
    self.source = source
    self.version = version
    self.event = event
    self.type = type
    self.subscribeEvent = subscribeEvent
  }
}

extension SubscribeObjectMetadataPayload: Codable {
  enum CodingKeys: String, CodingKey {
    case source
    case version
    case event
    case type
    case subscribeEvent = "data"
  }

  enum NestedCodingKeys: String, CodingKey {
    case metadataId = "id"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    source = try container.decode(String.self, forKey: .source)
    version = try container.decode(String.self, forKey: .version)
    event = try container.decode(Action.self, forKey: .event)
    type = try container.decode(MetadataType.self, forKey: .type)

    switch (type, event) {
    case (.uuid, .set):
      subscribeEvent = .uuidMetadataSet(
        try container.decode(PubNubUUIDMetadataChangeset.self, forKey: .subscribeEvent)
      )
    case (.uuid, .delete):
      let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .subscribeEvent)
      let identifier = try nestedContainer.decode(String.self, forKey: .metadataId)
      subscribeEvent = .uuidMetadataRemoved(metadataId: identifier)
    case (.channel, .set):
      subscribeEvent = .channelMetadataSet(
        try container.decode(PubNubChannelMetadataChangeset.self, forKey: .subscribeEvent)
      )
    case (.channel, .delete):
      let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .subscribeEvent)
      let identifier = try nestedContainer.decode(String.self, forKey: .metadataId)
      subscribeEvent = .channelMetadataRemoved(metadataId: identifier)
    case (.membership, .set):
      let membership = try container.decode(PubNubMembershipMetadataBase.self, forKey: .subscribeEvent)
      subscribeEvent = .membershipMetadataSet(membership)
    case (.membership, .delete):
      let membership = try container.decode(PubNubMembershipMetadataBase.self, forKey: .subscribeEvent)
      subscribeEvent = .membershipMetadataRemoved(membership)
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(source, forKey: .source)
    try container.encode(version, forKey: .version)
    try container.encode(event, forKey: .event)
    try container.encode(type, forKey: .type)

    switch subscribeEvent {
    case let .uuidMetadataSet(changeset):
      try container.encode(changeset, forKey: .subscribeEvent)
    case let .uuidMetadataRemoved(metadataId):
      var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .subscribeEvent)
      try nestedContainer.encode(metadataId, forKey: .metadataId)
    case let .channelMetadataSet(changeset):
      try container.encode(changeset, forKey: .subscribeEvent)
    case let .channelMetadataRemoved(metadataId):
      var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .subscribeEvent)
      try nestedContainer.encode(metadataId, forKey: .metadataId)
    case let .membershipMetadataSet(membership), let .membershipMetadataRemoved(membership):
      try container.encode(try membership.transcode(into: PubNubMembershipMetadataBase.self), forKey: .subscribeEvent)
    default:
      break
    }
  }
}

// MARK: - PubNubUUIDMetadataChangeset Coders

extension PubNubUUIDMetadataChangeset: Codable {
  enum CodingKeys: String, CodingKey {
    case metadataId = "id"
    case name
    case type
    case status
    case externalId
    case profileUrl
    case email
    case custom
    case updated
    case eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    metadataId = try container.decode(String.self, forKey: .metadataId)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)

    var changes = [PubNubMetadataChange<PubNubUUIDMetadata>]()
    if container.contains(.name) {
      changes.append(.stringOptional(\.name, try container.decodeIfPresent(String.self, forKey: .name)))
    }
    if container.contains(.type) {
      changes.append(.stringOptional(\.type, try container.decodeIfPresent(String.self, forKey: .type)))
    }
    if container.contains(.status) {
      changes.append(.stringOptional(\.status, try container.decodeIfPresent(String.self, forKey: .status)))
    }
    if container.contains(.externalId) {
      changes.append(.stringOptional(
        \.externalId, try container.decodeIfPresent(String.self, forKey: .externalId)
      ))
    }
    if container.contains(.profileUrl) {
      changes.append(.stringOptional(
        \.profileURL, try container.decodeIfPresent(String.self, forKey: .profileUrl)
      ))
    }
    if container.contains(.email) {
      changes.append(.stringOptional(\.email, try container.decodeIfPresent(String.self, forKey: .email)))
    }
    if container.contains(.custom) {
      changes.append(.customOptional(
        \.custom,
        try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
      ))
    }
    self.changes = changes
  }

  // swiftlint:disable:next cyclomatic_complexity
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(metadataId, forKey: .metadataId)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)

    for change in changes {
      switch change {
      case let .stringOptional(path, value):
        switch path {
        case \.name:
          if let value = value {
            try container.encode(value, forKey: .name)
          } else {
            try container.encodeNil(forKey: .name)
          }
        case \.type:
          if let value = value {
            try container.encode(value, forKey: .type)
          } else {
            try container.encodeNil(forKey: .type)
          }
        case \.status:
          if let value = value {
            try container.encode(value, forKey: .status)
          } else {
            try container.encodeNil(forKey: .status)
          }
        case \.externalId:
          if let value = value {
            try container.encode(value, forKey: .externalId)
          } else {
            try container.encodeNil(forKey: .externalId)
          }
        case \.profileURL:
          if let value = value {
            try container.encode(value, forKey: .profileUrl)
          } else {
            try container.encodeNil(forKey: .profileUrl)
          }
        case \.email:
          if let value = value {
            try container.encode(value, forKey: .email)
          } else {
            try container.encodeNil(forKey: .email)
          }
        default:
          break
        }
      case let .customOptional(_, value):
        if let value = value {
          try container.encode(value.mapValues { $0.scalarValue }, forKey: .custom)
        } else {
          try container.encodeNil(forKey: .custom)
        }
      }
    }
  }
}

// MARK: - PubNubChannelDMetadataChangeset Coders

extension PubNubChannelMetadataChangeset: Codable {
  enum CodingKeys: String, CodingKey {
    case metadataId = "id"
    case name
    case type
    case status
    case channelDescription = "description"
    case custom
    case updated
    case eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    metadataId = try container.decode(String.self, forKey: .metadataId)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)

    var changes = [PubNubMetadataChange<PubNubChannelMetadata>]()
    if container.contains(.name) {
      changes.append(.stringOptional(\.name, try container.decodeIfPresent(String.self, forKey: .name)))
    }
    if container.contains(.type) {
      changes.append(.stringOptional(\.type, try container.decodeIfPresent(String.self, forKey: .type)))
    }
    if container.contains(.status) {
      changes.append(.stringOptional(\.status, try container.decodeIfPresent(String.self, forKey: .status)))
    }
    if container.contains(.channelDescription) {
      changes.append(.stringOptional(
        \.channelDescription,
        try container.decodeIfPresent(String.self, forKey: .channelDescription)
      ))
    }
    if container.contains(.custom) {
      changes.append(.customOptional(
        \.custom,
        try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
      ))
    }
    self.changes = changes
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(metadataId, forKey: .metadataId)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)

    for change in changes {
      switch change {
      case let .stringOptional(path, value):
        switch path {
        case \.name:
          if let value = value {
            try container.encode(value, forKey: .name)
          } else {
            try container.encodeNil(forKey: .name)
          }
        case \.type:
          if let value = value {
            try container.encode(value, forKey: .type)
          } else {
            try container.encodeNil(forKey: .type)
          }
        case \.status:
          if let value = value {
            try container.encode(value, forKey: .status)
          } else {
            try container.encodeNil(forKey: .status)
          }
        case \.channelDescription:
          if let value = value {
            try container.encode(value, forKey: .channelDescription)
          } else {
            try container.encodeNil(forKey: .channelDescription)
          }
        default:
          break
        }

      case let .customOptional(_, value):
        if let value = value {
          try container.encode(value.mapValues { $0.scalarValue }, forKey: .custom)
        } else {
          try container.encodeNil(forKey: .custom)
        }
      }
    }
  }
}
