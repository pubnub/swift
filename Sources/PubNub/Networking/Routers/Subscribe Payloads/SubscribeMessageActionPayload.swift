//
//  SubscribeMessageActionPayload.swift
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
