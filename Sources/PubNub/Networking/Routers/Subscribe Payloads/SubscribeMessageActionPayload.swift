//
//  SubscribeMessageActionPayload.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

struct SubscribeMessageActionPayload: Codable, Hashable {
  let source: String
  let version: String
  let event: Action
  let actionType: String
  let actionValue: String
  let actionTimetoken: Timetoken
  let messageTimetoken: Timetoken

  enum CodingKeys: String, CodingKey {
    case source
    case version
    case event
    case data
  }

  enum DataCodingKeys: String, CodingKey {
    case actionType = "type"
    case actionValue = "value"
    case actionTimetoken
    case messageTimetoken
  }

  enum Action: String, Codable, Hashable {
    case added
    case removed
  }

  init(
    source: String,
    version: String,
    event: Action,
    actionType: String,
    actionValue: String,
    actionTimetoken: Timetoken,
    messageTimetoken: Timetoken
  ) {
    self.source = source
    self.version = version
    self.event = event
    self.actionType = actionType
    self.actionValue = actionValue
    self.actionTimetoken = actionTimetoken
    self.messageTimetoken = messageTimetoken
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    source = try container.decode(String.self, forKey: .source)
    version = try container.decode(String.self, forKey: .version)
    event = try container.decode(Action.self, forKey: .event)

    let dataContainer = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
    actionType = try dataContainer.decode(String.self, forKey: .actionType)
    actionValue = try dataContainer.decode(String.self, forKey: .actionValue)

    let actionTimetoken = try dataContainer.decode(String.self, forKey: .actionTimetoken)
    self.actionTimetoken = Timetoken(actionTimetoken) ?? 0
    let messageTimetoken = try dataContainer.decode(String.self, forKey: .messageTimetoken)
    self.messageTimetoken = Timetoken(messageTimetoken) ?? 0
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(source, forKey: .source)
    try container.encode(version, forKey: .version)
    try container.encode(event, forKey: .event)

    var dataContainer = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
    try dataContainer.encode(actionType, forKey: .actionType)
    try dataContainer.encode(actionValue, forKey: .actionValue)
    try dataContainer.encode(actionTimetoken.description, forKey: .actionTimetoken)
    try dataContainer.encode(messageTimetoken.description, forKey: .messageTimetoken)
  }
}
