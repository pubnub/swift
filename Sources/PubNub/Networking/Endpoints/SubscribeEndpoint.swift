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

  func decrypt(response: SubscriptionResponse) -> Result<SubscriptionResponse, Error> {
    // End early if we don't have a cipher key
    guard let crypto = response.router.configuration.cipherKey else {
      return .success(response)
    }

    var messages = response.payload.messages
    for (index, message) in messages.enumerated() {
      // Convert base64 string into Data
      if let messageData = message.payload.dataOptional {
        // If a message fails we just return the original and move on
        do {
          let decryptedPayload = try crypto.decrypt(encrypted: messageData).get()
          if let decodedString = String(bytes: decryptedPayload, encoding: .utf8) {
            messages[index] = message.message(with: AnyJSON(reverse: decodedString))
          } else {
            // swiftlint:disable:next line_length
            PubNub.log.error("Decrypted subscribe payload data failed to stringify for base64 encoded payload \(decryptedPayload.base64EncodedString())")
          }
        } catch {
          PubNub.log.error("Subscribe message failed to decrypt due to \(error)")
        }
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
  public let messages: [MessageResponse]

  enum CodingKeys: String, CodingKey {
    case token = "t"
    case messages = "m"
  }
}

public struct TimetokenResponse: Codable, Hashable {
  public let timetoken: Timetoken
  public let region: Int

  enum CodingKeys: String, CodingKey {
    case timetoken = "t"
    case region = "r"
  }

  // We want the timetoken as a Int instead of a String
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    region = try container.decode(Int.self, forKey: .region)

    let timetokenString = try container.decode(String.self, forKey: .timetoken)
    timetoken = Timetoken(timetokenString) ?? 0
  }
}

public enum MessageType: Int, Codable {
  case message = 0
  case signal = 1
  case object = 2
}

public struct MessageResponse: Codable, Hashable {
  public let shard: String
  public let subscriptionMatch: String?
  public let channel: String
  public let messageType: MessageType
  public let payload: AnyJSON
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
    payload: AnyJSON,
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
    subscriptionMatch = try container.decodeIfPresent(String.self, forKey: .subscriptionMatch)
    channel = try container.decode(String.self, forKey: .channel)
    payload = try container.decode(AnyJSON.self, forKey: .payload)
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
    default:
      self.messageType = .message
    }
  }

  func message(with newPayload: AnyJSON) -> MessageResponse {
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

  public func hash(into hasher: inout Hasher) {
    shard.hash(into: &hasher)
    subscriptionMatch.hash(into: &hasher)
    channel.hash(into: &hasher)
    messageType.hash(into: &hasher)
    //    payload: AnyJSON
    flags.hash(into: &hasher)
    issuer.hash(into: &hasher)
    subscribeKey.hash(into: &hasher)
    originTimetoken.hash(into: &hasher)
    publishTimetoken.hash(into: &hasher)
    //    metadata: AnyJSON?
  }
}

public struct PresenceMessageResponse: Codable, Hashable {
  public let action: PresenceStateEvent
  public let timetoken: Timetoken
  public let occupancy: Int

  public let join: [String]
  public let leave: [String]
  public let timeout: [String]
  public let channelState: ChannelPresenceState

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

  public func hash(into hasher: inout Hasher) {
    action.hash(into: &hasher)
    timetoken.hash(into: &hasher)
    occupancy.hash(into: &hasher)
//    data.hash(into: &hasher)
    join.hash(into: &hasher)
    leave.hash(into: &hasher)
    timeout.hash(into: &hasher)
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

  public static func == (lhs: PresenceMessageResponse, rhs: PresenceMessageResponse) -> Bool {
    return lhs.action == rhs.action &&
      lhs.timetoken == rhs.timetoken &&
      lhs.occupancy == rhs.occupancy &&
      lhs.join == rhs.join &&
      lhs.leave == rhs.leave &&
      lhs.timeout == rhs.timeout &&
      lhs.channelState.mapValues { AnyJSON($0) } == rhs.channelState.mapValues { AnyJSON($0) }
  }
}
