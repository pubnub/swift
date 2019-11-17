//
//  MessageActionsRouter.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

// MARK: - Router

struct MessageActionsRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case fetch(channel: String, start: Timetoken?, end: Timetoken?, limit: Int?)
    case add(channel: String, message: MessageAction, timetoken: Timetoken)
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
    case let .add(channel, _, timetoken):
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
    case let .add(_, message, _):
      return message.concreteType.encodableJSONData.map { .some($0) }
    case .remove:
      return .success(nil)
    }
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .fetch(channel, _, _, _):
      return isInvalidForReason((channel.isEmpty, ErrorDescription.emptyChannelString))
    case let .add(channel, message, _):
      return isInvalidForReason(
        (channel.isEmpty, ErrorDescription.emptyChannelString),
        (!message.isValid, ErrorDescription.invalidMessageAction)
      )
    case let .remove(channel, _, _):
      return isInvalidForReason(
        (channel.isEmpty, ErrorDescription.emptyChannelString)
      )
    }
  }
}

// MARK: - Request Object

/// A MessageAction that can be associated with a published message
public protocol MessageAction: Validated {
  /// The type of action (e.g. reaction)
  var type: String { get }
  /// The value of the action (e.g. smiley_face)
  var value: String { get }
}

extension MessageAction {
  public var validationError: Error? {
    if type.isEmpty || value.isEmpty {
      return PubNubError(.missingRequiredParameter)
    }

    return nil
  }

  public var concreteType: ConcreteMessageAction {
    return ConcreteMessageAction(type: type, value: value)
  }
}

public struct ConcreteMessageAction: MessageAction, Codable, Hashable {
  public let type: String
  public let value: String

  public init(type: String, value: String) {
    self.type = type
    self.value = value
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

public struct MessageActionsResponsePayload: Codable, Hashable {
  public let actions: [MessageActionPayload]

  public let start: Timetoken?
  public let end: Timetoken?
  public let limit: Int?

  enum CodingKeys: String, CodingKey {
    case actions = "data"
    case start
    case end
    case limit
    case more
  }

  public init(
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

  init(actions: [MessageActionPayload], more: MessageActionMorePaylaod? = nil) {
    self.actions = actions
    start = more?.start
    end = more?.end
    limit = more?.limit
  }

  public init(from decoder: Decoder) throws {
    // Check if container is keyed or unkeyed
    let container = try decoder.container(keyedBy: CodingKeys.self)
    actions = try container.decode([MessageActionPayload].self, forKey: .actions)
    let more = try container.decodeIfPresent(MessageActionMorePaylaod.self, forKey: .more)
    start = more?.start
    end = more?.end
    limit = more?.limit
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(actions, forKey: .actions)
    try container.encode(start, forKey: .start)
    try container.encode(end, forKey: .end)
    try container.encode(limit, forKey: .limit)
  }
}

public struct MessageActionResponsePayload: Codable, Hashable {
  public let action: MessageActionPayload
  public let error: ErrorPayload?

  enum CodingKeys: String, CodingKey {
    case action = "data"
    case error
  }
}

public struct MessageActionPayload: Codable, Hashable {
  public let uuid: String
  public let type: String
  public let value: String
  public let actionTimetoken: Timetoken
  public let messageTimetoken: Timetoken

  public init(
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

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    uuid = try container.decode(String.self, forKey: .uuid)
    type = try container.decode(String.self, forKey: .type)
    value = try container.decode(String.self, forKey: .value)

    let actionTimetoken = try container.decode(String.self, forKey: .actionTimetoken)
    self.actionTimetoken = Timetoken(actionTimetoken) ?? 0
    let messageTimetoken = try container.decode(String.self, forKey: .messageTimetoken)
    self.messageTimetoken = Timetoken(messageTimetoken) ?? 0
  }
}

struct MessageActionMorePaylaod: Codable, Hashable {
  let start: Timetoken?
  let end: Timetoken?
  let limit: Int?

  init(start: Timetoken?, end: Timetoken?, limit: Int?) {
    self.start = start
    self.end = end
    self.limit = limit
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let start = try container.decodeIfPresent(String.self, forKey: .start) ?? ""
    self.start = Timetoken(start)
    let end = try container.decodeIfPresent(String.self, forKey: .end) ?? ""
    self.end = Timetoken(end)
    limit = try container.decodeIfPresent(Int.self, forKey: .limit)
  }
}

public struct DeleteResponsePayload: Codable, Hashable {
  let status: Int
  public let error: ErrorPayload?

  public var message: EndpointResponseMessage {
    return .acknowledge
  }
}
