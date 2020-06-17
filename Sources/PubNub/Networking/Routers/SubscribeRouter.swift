//
//  SubscribeRouter.swift
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

struct SubscribeRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CaseAccessible, CustomStringConvertible {
    case subscribe(channels: [String], groups: [String],
                   timetoken: Timetoken?, region: String?,
                   heartbeat: UInt?, filter: String?)

    var description: String {
      switch self {
      case .subscribe:
        return "Subscribe"
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
    return .subscribe
  }

  var category: String {
    return endpoint.description
  }

  var path: Result<String, Error> {
    let path: String

    switch endpoint {
    case let .subscribe(channels, _, _, _, _, _):
      path = "/v2/subscribe/\(subscribeKey)/\(channels.commaOrCSVString.urlEncodeSlash)/0"
    }

    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .subscribe(_, groups, timetoken, region, heartbeat, filter):
      query.appendIfNotEmpty(key: .channelGroup, value: groups)
      query.appendIfPresent(key: .timetokenShort, value: timetoken?.description)
      query.appendIfPresent(key: .regionShort, value: region?.description)
      query.appendIfPresent(key: .filterExpr, value: filter)
      query.appendIfPresent(key: .heartbeat, value: heartbeat?.description)
    }

    return .success(query)
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .subscribe(channels, groups, _, _, _, _):
      return isInvalidForReason(
        (channels.isEmpty && groups.isEmpty, ErrorDescription.missingChannelsAnyGroups))
    }
  }
}

// MARK: - Response Decoder

typealias SubscribeEndpointResponse = EndpointResponse<SubscribeResponse>

struct SubscribeDecoder: ResponseDecoder {
  typealias Payload = SubscribeResponse

  func decode(response: EndpointResponse<Data>) -> Result<SubscribeEndpointResponse, Error> {
    do {
      let decodedPayload = try Constant.jsonDecoder.decode(Payload.self, from: response.payload)

      let decodedResponse = EndpointResponse<Payload>(router: response.router,
                                                      request: response.request,
                                                      response: response.response,
                                                      data: response.data,
                                                      payload: decodedPayload)

      return .success(decodedResponse)
    } catch {
      // Atempt to parse out the timetoken protion of the payload to push ahead the subscribe loop
      if response.payload.count >= 37 {
        // The `0..<37` range represents the start of the subscribe response `{'t': {'t': 1234, 'r': 0}...`
        var truncatedData = response.payload[0 ..< 37]
        // `125` represents the close curley brace` }`, and the `36` position is the end of the `Data` blob
        truncatedData[36] = 125

        if let timetokenResponse = try? Constant.jsonDecoder.decode(
          Payload.self, from: truncatedData
        ).cursor {
          return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error,
                                      affected: [.subscribe(timetokenResponse)]))
        }
      }

      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }

  func decrypt(_ crypto: Crypto, message: SubscribeMessagePayload) -> SubscribeMessagePayload {
    // Convert base64 string into Data
    if let messageData = message.payload.dataOptional {
      // If a message fails we just return the original and move on
      do {
        let decryptedPayload = try crypto.decrypt(encrypted: messageData).get()
        if let decodedString = String(bytes: decryptedPayload, encoding: crypto.defaultStringEncoding) {
          // Create mutable copy of payload
          var message = message
          message.payload = AnyJSON(reverse: decodedString)

          return message
        } else {
          PubNub.log.error("\(ErrorDescription.cryptoStringEncodeFailed) \(decryptedPayload.base64EncodedString())")

          return message
        }
      } catch {
        PubNub.log.error("Subscribe message failed to decrypt due to \(error)")
      }
    }

    return message
  }

  func decrypt(response: SubscribeEndpointResponse) -> Result<SubscribeEndpointResponse, Error> {
    // End early if we don't have a cipher key
    guard let crypto = response.router.configuration.cipherKey else {
      return .success(response)
    }

    var messages = response.payload.messages
    for (index, message) in messages.enumerated() {
      switch message.messageType {
      case .message:
        messages[index] = decrypt(crypto, message: message)
      case .signal:
        messages[index] = decrypt(crypto, message: message)
      default:
        messages[index] = message
      }
    }

    let decryptedResponse = SubscribeEndpointResponse(
      router: response.router,
      request: response.request,
      response: response.response,
      data: response.data,
      payload: SubscribeResponse(cursor: response.payload.cursor, messages: messages)
    )

    return .success(decryptedResponse)
  }
}

struct SubscribeResponse: Codable, Hashable {
  let cursor: SubscribeCursor
  let messages: [SubscribeMessagePayload]

  enum CodingKeys: String, CodingKey {
    case cursor = "t"
    case messages = "m"
  }

  init(
    cursor: SubscribeCursor,
    messages: [SubscribeMessagePayload]
  ) {
    self.cursor = cursor
    self.messages = messages
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    cursor = try container.decode(SubscribeCursor.self, forKey: .cursor)
    messages = try container.decodeIfPresent([SubscribeMessagePayload].self, forKey: .messages) ?? []
  }

  // Synthesized `public func encode(to encoder: Encoder) throws`
}

// MARK: - Cursor Response

public struct SubscribeCursor: Codable, Hashable {
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

  public init?(timetoken: Timetoken? = nil, region: Int? = nil) {
    if timetoken != nil || region != nil {
      self.timetoken = timetoken ?? 0
      self.region = region ?? 0
    } else {
      return nil
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    region = try container.decodeIfPresent(Int.self, forKey: .region) ?? 0

    // We want the timetoken as a Int instead of a String
    let timetokenString = try container.decode(String.self, forKey: .timetoken)
    timetoken = Timetoken(timetokenString) ?? 0
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(region, forKey: .region)
    try container.encode(timetoken.description, forKey: .timetoken)
  }
}

struct SubscribeMessagePayload: Codable, Hashable {
  let shard: String
  let subscription: String?
  let channel: String
  var messageType: Action
  var payload: AnyJSON
  let flags: Int
  let publisher: String?
  let subscribeKey: String
  let originTimetoken: SubscribeCursor?
  let publishTimetoken: SubscribeCursor
  let metadata: AnyJSON?

  enum CodingKeys: String, CodingKey {
    case shard = "a"
    case subscription = "b"
    case channel = "c"
    case payload = "d"
    case messageType = "e"
    case flags = "f"
    case publisher = "i"
    case subscribeKey = "k"
    case originTimetoken = "o"
    case publishTimetoken = "p"
    case meta = "u"
  }

  enum Action: Int, Codable {
    case message = 0
    case signal = 1
    case object = 2
    case messageAction = 3
    /// Presence Event type
    /// - warning: This is a client-side type and will be encoded as nil
    case presence = 99
  }

  init(
    shard: String,
    subscription: String?,
    channel: String,
    messageType: Action,
    payload: AnyJSON,
    flags: Int,
    publisher: String?,
    subscribeKey: String,
    originTimetoken: SubscribeCursor?,
    publishTimetoken: SubscribeCursor,
    meta: AnyJSON?
  ) {
    self.shard = shard
    self.subscription = subscription
    self.channel = channel
    self.messageType = messageType
    self.payload = payload
    self.flags = flags
    self.publisher = publisher
    self.subscribeKey = subscribeKey
    self.originTimetoken = originTimetoken
    self.publishTimetoken = publishTimetoken
    metadata = meta
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    shard = try container.decode(String.self, forKey: .shard)
    subscription = try container
      .decodeIfPresent(String.self, forKey: .subscription)?
      .trimmingPresenceChannelSuffix
    payload = try container.decode(AnyJSON.self, forKey: .payload)
    flags = try container.decode(Int.self, forKey: .flags)
    publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
    subscribeKey = try container.decode(String.self, forKey: .subscribeKey)
    originTimetoken = try container.decodeIfPresent(SubscribeCursor.self, forKey: .originTimetoken)
    publishTimetoken = try container.decode(SubscribeCursor.self, forKey: .publishTimetoken)
    metadata = try container.decodeIfPresent(AnyJSON.self, forKey: .meta)

    let messageType = try container.decodeIfPresent(Int.self, forKey: .messageType)
    let fullChannel = try container.decode(String.self, forKey: .channel)

    if let messageType = messageType, let action = Action(rawValue: messageType) {
      self.messageType = action
    } else {
      // If channel endswith -pnpres we assume it's a presence event
      if fullChannel.isPresenceChannelName {
        self.messageType = .presence
      } else {
        self.messageType = .message
      }
    }

    channel = fullChannel.trimmingPresenceChannelSuffix
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(shard, forKey: .shard)
    try container.encode(subscription, forKey: .subscription)
    try container.encode(channel, forKey: .channel)
    try container.encode(payload, forKey: .payload)
    try container.encode(flags, forKey: .flags)
    try container.encode(publisher, forKey: .publisher)
    try container.encode(subscribeKey, forKey: .subscribeKey)
    try container.encode(originTimetoken, forKey: .originTimetoken)
    try container.encode(publishTimetoken, forKey: .publishTimetoken)
    try container.encode(metadata, forKey: .meta)

    // Presence isn't a server owned MessageType, so we don't encode it
    if messageType != .presence {
      try container.encode(messageType, forKey: .messageType)
    }
  }
}
