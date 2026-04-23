//
//  PubNubEntityEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public struct PubNubEntityEvent: Codable {
  public enum Action: String, Codable, Hashable {
    case updated = "set"
    case removed = "delete"
  }

  public enum EntityType: String, Codable, Hashable {
    case user = "uuid"
    case space = "channel"
    case membership
  }

  public let source: String
  public let version: String
  public let action: Action
  public let type: EntityType
  public let data: AnyJSON

  public init(
    source: String,
    version: String,
    action: Action,
    type: EntityType,
    data: AnyJSON
  ) {
    self.source = source
    self.version = version
    self.action = action
    self.type = type
    self.data = data
  }

  enum CodingKeys: String, CodingKey {
    case source
    case version
    case action = "event"
    case type
    case data
  }
}
