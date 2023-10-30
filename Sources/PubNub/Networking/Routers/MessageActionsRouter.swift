//
//  MessageActionsRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Router

struct MessageActionsRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CaseAccessible, CustomStringConvertible {
    case fetch(channel: String, start: Timetoken?, end: Timetoken?, limit: Int?)
    case add(channel: String, type: String, value: String, timetoken: Timetoken)
    case remove(channel: String, message: Timetoken, action: Timetoken)

    var description: String {
      switch self {
      case .fetch:
        return "Fetch a List of Message Actions"
      case .add:
        return "Add a Message Action"
      case .remove:
        return "Remove a Message Action"
      }
    }
  }

  struct AddRequestBody: Codable, Hashable {
    let type: String
    let value: String

    init(type: String, value: String) {
      self.type = type
      self.value = value
    }
  }

  // Init
  init(_ endpoint: Endpoint, configuration: RouterConfiguration) {
    self.endpoint = endpoint
    self.configuration = configuration
  }

  var endpoint: Endpoint
  var configuration: RouterConfiguration

  // Protocol Properties
  var service: PubNubService {
    return .messageActions
  }

  var category: String {
    return endpoint.description
  }

  var path: Result<String, Error> {
    let path: String

    switch endpoint {
    case let .fetch(channel, _, _, _):
      path = "/v1/message-actions/\(subscribeKey)/channel/\(channel)"
    case let .add(channel, _, _, timetoken):
      path = "/v1/message-actions/\(subscribeKey)/channel/\(channel)/message/\(timetoken)"
    case let .remove(channel, message, action):
      path = "/v1/message-actions/\(subscribeKey)/channel/\(channel)/message/\(message)/action/\(action)"
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .fetch(_, start, end, limit):
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .limit, value: limit?.description)
    case .add:
      break
    case .remove:
      break
    }

    return .success(query)
  }

  var method: HTTPMethod {
    switch endpoint {
    case .fetch:
      return .get
    case .add:
      return .post
    case .remove:
      return .delete
    }
  }

  var body: Result<Data?, Error> {
    switch endpoint {
    case .fetch:
      return .success(nil)
    case let .add(_, actionType, actionValue, _):
      return AddRequestBody(type: actionType, value: actionValue)
        .encodableJSONData.map { .some($0) }
    case .remove:
      return .success(nil)
    }
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .fetch(channel, _, _, _):
      return isInvalidForReason((channel.isEmpty, ErrorDescription.emptyChannelString))
    case let .add(channel, actionType, actionValue, _):
      return isInvalidForReason(
        (channel.isEmpty, ErrorDescription.emptyChannelString),
        (actionType.isEmpty, ErrorDescription.invalidMessageAction),
        (actionValue.isEmpty, ErrorDescription.invalidMessageAction)
      )
    case let .remove(channel, _, _):
      return isInvalidForReason(
        (channel.isEmpty, ErrorDescription.emptyChannelString)
      )
    }
  }
}

// MARK: - Response Decoder

struct MessageActionsResponseDecoder: ResponseDecoder {
  typealias Payload = MessageActionsResponsePayload
}

struct MessageActionResponseDecoder: ResponseDecoder {
  typealias Payload = MessageActionResponsePayload
}

struct DeleteResponseDecoder: ResponseDecoder {
  typealias Payload = DeleteResponsePayload
}

// MARK: - Response Body

struct MessageActionPayload: Codable, Hashable {
  let uuid: String
  let type: String
  let value: String
  let actionTimetoken: Timetoken
  let messageTimetoken: Timetoken

  enum CodingKeys: String, CodingKey {
    case uuid
    case type
    case value
    case actionTimetoken
    case messageTimetoken
  }

  init(
    uuid: String = UUID().uuidString,
    type: String,
    value: String,
    actionTimetoken: Timetoken = 0,
    messageTimetoken: Timetoken = 0
  ) {
    self.uuid = uuid
    self.type = type
    self.value = value
    self.actionTimetoken = actionTimetoken
    self.messageTimetoken = messageTimetoken
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    uuid = try container.decode(String.self, forKey: .uuid)
    type = try container.decode(String.self, forKey: .type)
    value = try container.decode(String.self, forKey: .value)

    let actionTimetoken = try container.decode(String.self, forKey: .actionTimetoken)
    self.actionTimetoken = Timetoken(actionTimetoken) ?? 0
    let messageTimetoken = try container.decode(String.self, forKey: .messageTimetoken)
    self.messageTimetoken = Timetoken(messageTimetoken) ?? 0
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(uuid, forKey: .uuid)
    try container.encode(type, forKey: .type)
    try container.encode(value, forKey: .value)
    try container.encode(actionTimetoken.description, forKey: .actionTimetoken)
    try container.encode(messageTimetoken.description, forKey: .messageTimetoken)
  }
}

// MARK: Fetch Message Action Response

struct MessageActionsResponsePayload: Codable, Hashable {
  let actions: [MessageActionPayload]
  let start: Timetoken?
  let end: Timetoken?
  let limit: Int?

  enum CodingKeys: String, CodingKey {
    case data
    case more
  }

  enum MoreCodingKeys: String, CodingKey {
    case start
    case end
    case limit
  }

  init(
    actions: [MessageActionPayload],
    start: Timetoken? = nil,
    end: Timetoken? = nil,
    limit: Int? = nil
  ) {
    self.actions = actions
    self.start = start
    self.end = end
    self.limit = limit
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    actions = try container.decode([MessageActionPayload].self, forKey: .data)

    let pageContainer = try? container.nestedContainer(keyedBy: MoreCodingKeys.self, forKey: .more)
    start = Timetoken(try pageContainer?.decodeIfPresent(String.self, forKey: .start) ?? "")
    end = Timetoken(try pageContainer?.decodeIfPresent(String.self, forKey: .end) ?? "")
    limit = try pageContainer?.decodeIfPresent(Int.self, forKey: .limit)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(actions, forKey: .data)

    var pageContainer = container.nestedContainer(keyedBy: MoreCodingKeys.self, forKey: .more)
    try pageContainer.encodeIfPresent(start?.description, forKey: .start)
    try pageContainer.encodeIfPresent(end?.description, forKey: .end)
    try pageContainer.encodeIfPresent(limit, forKey: .limit)
  }
}

// MARK: Add Message Action Response

struct MessageActionResponsePayload: Codable, Hashable {
  let data: MessageActionPayload
  let error: ErrorPayload?
}

// MARK: Delete Response

struct DeleteResponsePayload: Codable, Hashable {
  let status: Int
  let error: ErrorPayload?
}
