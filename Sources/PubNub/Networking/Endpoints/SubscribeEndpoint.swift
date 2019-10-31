//
//  SubscribeEndpoint.swift
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

// MARK: - Response Decoder

struct SubscribeResponseDecoder: ResponseDecoder {
  typealias Payload = SubscriptionResponsePayload

  func decrypt(_ crypto: Crypto, message: MessageResponse<AnyJSON>) -> MessageResponse<AnyJSON> {
    // Convert base64 string into Data
    if let messageData = message.payload.dataOptional {
      // If a message fails we just return the original and move on
      do {
        let decryptedPayload = try crypto.decrypt(encrypted: messageData).get()
        if let decodedString = String(bytes: decryptedPayload, encoding: .utf8) {
          return message.message(with: AnyJSON(reverse: decodedString))
        } else {
          // swiftlint:disable:next line_length
          PubNub.log.error("Decrypted subscribe payload data failed to stringify for base64 encoded payload \(decryptedPayload.base64EncodedString())")
        }
      } catch {
        PubNub.log.error("Subscribe message failed to decrypt due to \(error)")
      }
    }

    return message
  }

  func decrypt(response: SubscriptionResponse) -> Result<SubscriptionResponse, Error> {
    // End early if we don't have a cipher key
    guard let crypto = response.router.configuration.cipherKey else {
      return .success(response)
    }

    var messages = response.payload.messages
    for (index, messageType) in messages.enumerated() {
      switch messageType {
      case let .message(message):
        messages[index] = .message(decrypt(crypto, message: message))
      case let .signal(signal):
        messages[index] = .signal(decrypt(crypto, message: signal))
      default:
        messages[index] = messageType
      }
    }

    let decryptedResponse = SubscriptionResponse(router: response.router,
                                                 request: response.request,
                                                 response: response.response,
                                                 data: response.data,
                                                 payload: SubscriptionResponsePayload(token: response.payload.token,
                                                                                      messages: messages))

    return .success(decryptedResponse)
  }
}

// MARK: - Response Body

public typealias SubscriptionResponse = Response<SubscriptionResponsePayload>

public struct SubscriptionResponsePayload: Codable {
  // Root Level
  public let token: TimetokenResponse
  public let messages: [SubscriptionPayload]

  enum CodingKeys: String, CodingKey {
    case token = "t"
    case messages = "m"
  }
}

// MARK: - Timetoken Response

public struct TimetokenResponse: Codable, Hashable {
  public let timetoken: Timetoken
  public let region: Int

  enum CodingKeys: String, CodingKey {
    case timetoken = "t"
    case region = "r"
  }

  public init(timetoken: Timetoken, region: Int) {
    self.timetoken = timetoken
    self.region = region
  }

  // We want the timetoken as a Int instead of a String
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    region = try container.decode(Int.self, forKey: .region)

    let timetokenString = try container.decode(String.self, forKey: .timetoken)
    timetoken = Timetoken(timetokenString) ?? 0
  }
}

// MARK: - Payload Responses

public enum SubscriptionPayload: Codable {
  case message(MessageResponse<AnyJSON>)
  case presence(MessageResponse<PresenceResponse>)
  case signal(MessageResponse<AnyJSON>)
  case object(MessageResponse<ObjectSubscribePayload>)
  case messageAction(MessageResponse<MessageActionSubscribePayload>)

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case let .message(value):
      try container.encode(value)
    case let .presence(value):
      try container.encode(value)
    case let .signal(value):
      try container.encode(value)
    case let .object(value):
      try container.encode(value)
    case let .messageAction(value):
      try container.encode(value)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let presencePayload = try? container.decode(MessageResponse<PresenceResponse>.self) {
      self = .presence(presencePayload)
    } else if let objectPayload = try? container.decode(MessageResponse<ObjectSubscribePayload>.self) {
      self = .object(objectPayload)
    } else if let messageActionPayload = try? container.decode(MessageResponse<MessageActionSubscribePayload>.self) {
      self = .messageAction(messageActionPayload)
    } else {
      let payload = try container.decode(MessageResponse<AnyJSON>.self)

      if payload.messageType == .message {
        self = .message(payload)
      } else {
        self = .signal(payload)
      }
    }
  }
}

// MARK: Message Response

public enum MessageType: Int, Codable {
  case message = 0
  case signal = 1
  case object = 2
  case action = 3
  case presence = 99
}

public struct MessageResponse<Payload>: Codable, Hashable where Payload: Codable, Payload: Hashable {
  public let shard: String
  public let subscriptionMatch: String?
  public let channel: String
  public let messageType: MessageType
  public let payload: Payload
  public let flags: Int
  public let issuer: String?
  public let subscribeKey: String
  public let originTimetoken: TimetokenResponse?
  public let publishTimetoken: TimetokenResponse
  public let metadata: AnyJSON?

  enum CodingKeys: String, CodingKey {
    case shard = "a"
    case subscriptionMatch = "b"
    case channel = "c"
    case payload = "d"
    case messageType = "e"
    case flags = "f"
    case issuer = "i"
    case subscribeKey = "k"
    case originTimetoken = "o"
    case publishTimetoken = "p"
    case metadata = "u"
  }

  public init(
    shard: String,
    subscriptionMatch: String?,
    channel: String,
    messageType: MessageType,
    payload: Payload,
    flags: Int,
    issuer: String?,
    subscribeKey: String,
    originTimetoken: TimetokenResponse?,
    publishTimetoken: TimetokenResponse,
    metadata: AnyJSON?
  ) {
    self.shard = shard
    self.subscriptionMatch = subscriptionMatch
    self.channel = channel
    self.messageType = messageType
    self.payload = payload
    self.flags = flags
    self.issuer = issuer
    self.subscribeKey = subscribeKey
    self.originTimetoken = originTimetoken
    self.publishTimetoken = publishTimetoken
    self.metadata = metadata
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    shard = try container.decode(String.self, forKey: .shard)
    subscriptionMatch = try container
      .decodeIfPresent(String.self, forKey: .subscriptionMatch)?.trimmingPresenceChannelSuffix
    channel = try container.decode(String.self, forKey: .channel).trimmingPresenceChannelSuffix
    payload = try container.decode(Payload.self, forKey: .payload)
    flags = try container.decode(Int.self, forKey: .flags)
    issuer = try container.decodeIfPresent(String.self, forKey: .issuer)
    subscribeKey = try container.decode(String.self, forKey: .subscribeKey)
    originTimetoken = try container.decodeIfPresent(TimetokenResponse.self, forKey: .originTimetoken)
    publishTimetoken = try container.decode(TimetokenResponse.self, forKey: .publishTimetoken)
    metadata = try container.decodeIfPresent(AnyJSON.self, forKey: .metadata)

    let messageType = try container.decodeIfPresent(Int.self, forKey: .messageType)
    switch messageType {
    case .some(1):
      self.messageType = .signal
    case .some(2):
      self.messageType = .object
    case .some(3):
      self.messageType = .action
    default:
      if payload is PresenceResponse {
        self.messageType = .presence
      } else {
        self.messageType = .message
      }
    }
  }

  func message(with newPayload: Payload) -> MessageResponse {
    return MessageResponse(shard: shard,
                           subscriptionMatch: subscriptionMatch,
                           channel: channel,
                           messageType: messageType,
                           payload: newPayload,
                           flags: flags,
                           issuer: issuer,
                           subscribeKey: subscribeKey,
                           originTimetoken: originTimetoken,
                           publishTimetoken: publishTimetoken,
                           metadata: metadata)
  }
}

// MARK: Object Response

public enum ObjectAction: String, Codable, Hashable {
  case add = "create"
  case update
  case delete
}

public enum ObjectType: String, Codable, Hashable {
  case user
  case space
  case membership
}

public struct ObjectSubscribePayload: Codable, Hashable {
  public let source: String
  public let version: String
  public let event: ObjectAction
  public let type: ObjectType
  public let data: AnyJSON

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    source = try container.decode(String.self, forKey: .source)
    version = try container.decode(String.self, forKey: .version)
    event = try container.decode(ObjectAction.self, forKey: .event)
    type = try container.decode(ObjectType.self, forKey: .type)
    data = try container.decode(AnyJSON.self, forKey: .data)
  }

  func decodedEvent() throws -> SubscriptionEvent {
    switch (type, event) {
    case (.user, .update):
      return .userUpdated(try data.decode(UserObject.self))
    case (.user, .delete):
      return .userDeleted(try data.decode(IdentifierEvent.self))
    case (.space, .update):
      return .spaceUpdated(try data.decode(SpaceObject.self))
    case (.space, .delete):
      return .spaceDeleted(try data.decode(IdentifierEvent.self))
    case (.membership, .add):
      return .membershipAdded(try data.decode(MembershipEvent.self))
    case (.membership, .update):
      return .membershipUpdated(try data.decode(MembershipEvent.self))
    case (.membership, .delete):
      return .membershipDeleted(try data.decode(MembershipEvent.self))
    default:
      throw DecodingError.typeMismatch(SubscriptionEvent.self,
                                       .init(codingPath: [],
                                             debugDescription: "Could not match payload with any known type"))
    }
  }
}

// MARK: Message Action Response

public struct MessageActionSubscribePayload: Codable, Hashable {
  let source: String
  let version: String
  let event: MessageActionEventType
  public let data: MessageActionEvent
}

enum MessageActionEventType: String, Codable, Hashable {
  case added
  case removed
}

public struct MessageActionEvent: Codable, Hashable {
  public let type: String
  public let value: String
  public let actionTimetoken: Timetoken
  public let messageTimetoken: Timetoken

  public init(type: String, value: String, actionTimetoken: Timetoken, messageTimetoken: Timetoken) {
    self.type = type
    self.value = value
    self.actionTimetoken = actionTimetoken
    self.messageTimetoken = messageTimetoken
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    type = try container.decode(String.self, forKey: .type)
    value = try container.decode(String.self, forKey: .value)

    let actionTimetoken = try container.decode(String.self, forKey: .actionTimetoken)
    self.actionTimetoken = Timetoken(actionTimetoken) ?? 0
    let messageTimetoken = try container.decode(String.self, forKey: .messageTimetoken)
    self.messageTimetoken = Timetoken(messageTimetoken) ?? 0
  }
}

// MARK: Presence Response

public struct PresenceResponse: Codable, Hashable {
  public let action: PresenceStateEvent
  public let timetoken: Timetoken
  public let occupancy: Int

  public let join: [String]
  public let leave: [String]
  public let timeout: [String]
  public let channelState: [String: [String: AnyJSON]]

  enum CodingKeys: String, CodingKey {
    case action
    case timetoken = "timestamp"
    case occupancy

    case join
    case leave
    case timeout

    // State breakdown
    case uuid
    case data
  }

  public init(
    action: PresenceStateEvent,
    timetoken: Timetoken,
    occupancy: Int,
    join: [String],
    leave: [String],
    timeout: [String],
    channelState: [String: [String: JSONCodable]]
  ) {
    self.action = action
    self.timetoken = timetoken
    self.occupancy = occupancy
    self.join = join
    self.leave = leave
    self.timeout = timeout
    self.channelState = channelState.mapValues { $0.mapValues { $0.codableValue } }
  }

  // We want the timetoken as a Int instead of a String
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    action = try container.decode(PresenceStateEvent.self, forKey: .action)
    timetoken = try container.decode(Timetoken.self, forKey: .timetoken)
    occupancy = try container.decode(Int.self, forKey: .occupancy)

    let stateData = try container.decodeIfPresent([String: AnyJSON].self, forKey: .data)
    let uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
    var join = try container.decodeIfPresent([String].self, forKey: .join) ?? []
    var leave = try container.decodeIfPresent([String].self, forKey: .leave) ?? []
    var timedOut = try container.decodeIfPresent([String].self, forKey: .timeout) ?? []

    switch action {
    case .join:
      join.append(uuid)
    case .leave:
      leave.append(uuid)
    case .timeout:
      timedOut.append(uuid)
    case .stateChange:
      break
    case .interval:
      // Lists should already be populated
      break
    }

    if let stateData = stateData, !uuid.isEmpty {
      channelState = [uuid: stateData]
    } else {
      channelState = [:]
    }

    self.join = join
    self.leave = leave
    timeout = timedOut
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(action.rawValue, forKey: .action)
    try container.encode(timetoken, forKey: .timetoken)
    try container.encode(occupancy, forKey: .occupancy)

    try container.encode(join, forKey: .join)
    try container.encode(leave, forKey: .leave)
    try container.encode(timeout, forKey: .timeout)

    switch action {
    case .join:
      if let joinUUID = join.first {
        try container.encode(joinUUID, forKey: .uuid)
      }
    case .leave:
      if let leaveUUID = leave.first {
        try container.encode(leaveUUID, forKey: .uuid)
      }
    case .timeout:
      if let timeoutUUID = timeout.first {
        try container.encode(timeoutUUID, forKey: .uuid)
      }
    case .stateChange:
      break
    case .interval:
      break
    }

    if let (uuid, stateData) = channelState.first {
      try container.encode(uuid, forKey: .uuid)
      try container.encode(stateData.mapValues { AnyJSON($0) }, forKey: .data)
    }
  }

  // swiftlint:disable:next file_length
}
