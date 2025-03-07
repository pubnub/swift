//
//  SubscribeRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Router

struct SubscribeRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CaseAccessible, CustomStringConvertible {
    case subscribe(
      channels: [String], groups: [String], channelStates: [String: JSONCodable],
      timetoken: Timetoken?, region: String?,
      heartbeat: UInt?, filter: String?
    )

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
    case let .subscribe(channels, _, _, _, _, _, _):
      path = "/v2/subscribe/\(subscribeKey)/\(channels.commaOrCSVString.urlEncodeSlash)/0"
    }

    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .subscribe(_, groups, channelStates, timetoken, region, heartbeat, filter):
      query.appendIfNotEmpty(
        key: .channelGroup,
        value: groups
      )
      query.appendIfPresent(
        key: .timetokenShort,
        value: timetoken?.description
      )
      query.appendIfPresent(
        key: .regionShort,
        value: region?.description
      )
      query.appendIfPresent(
        key: .filterExpr,
        value: filter
      )
      query.appendIfPresent(
        key: .heartbeat,
        value: heartbeat?.description
      )
      query.append(
        key: .eventEngine,
        value: nil,
        when: configuration.enableEventEngine
      )
      query.appendIfPresent(
        key: .state,
        value: try? channelStates.mapValues { $0.codableValue }.encodableJSONString.get(),
        when: configuration.enableEventEngine && configuration.maintainPresenceState && !channelStates.isEmpty
      )
    }

    return .success(query)
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .subscribe(channels, groups, _, _, _, _, _):
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

      let decodedResponse = EndpointResponse<Payload>(
        router: response.router,
        request: response.request,
        response: response.response,
        data: response.data,
        payload: decodedPayload
      )

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
          return .failure(
            PubNubError(
              .jsonDataDecodingFailure,
              response: response,
              error: error,
              affected: [.subscribe(timetokenResponse)]
            )
          )
        }
      }

      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }

  func decrypt(_ cryptoModule: CryptoModule, message: SubscribeMessagePayload) -> SubscribeMessagePayload {
    var message = message
    // Convert Base64 string into Data
    if let messageData = message.payload.dataOptional {
      // If a message fails we just return the original and move on
      switch cryptoModule.decryptedString(from: messageData) {
      case .success(let decodedString):
        // Create mutable copy of payload
        message.payload = AnyJSON(reverse: decodedString)
        return message
      case .failure(let error):
        PubNub.log.warn(
          "Subscribe message failed to decrypt due to \(error)",
          category: .crypto
        )
        message.error = error
        return message
      }
    }
    message.error = PubNubError(
      .decryptionFailure,
      additional: ["Cannot decrypt message due to invalid Base-64 input"]
    )
    return message
  }

  func decrypt(response: SubscribeEndpointResponse) -> Result<SubscribeEndpointResponse, Error> {
    // End early if we don't have a cipher key
    guard let cryptoModule = response.router.configuration.cryptoModule else {
      return .success(response)
    }

    var messages = response.payload.messages
    for (index, message) in messages.enumerated() {
      switch message.messageType {
      case .message:
        messages[index] = decrypt(cryptoModule, message: message)
      case .signal:
        messages[index] = decrypt(cryptoModule, message: message)
      case .file:
        messages[index] = decrypt(cryptoModule, message: message)
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

public struct SubscribeMessagePayload: Codable, Hashable, CustomStringConvertible {
  public let shard: String
  public let subscription: String?
  public let channel: String
  public let messageType: Action
  public var customMessageType: String?
  public var payload: AnyJSON
  public let flags: Int
  public let publisher: String?
  public let subscribeKey: String
  public let originTimetoken: SubscribeCursor?
  public let publishTimetoken: SubscribeCursor
  public let metadata: AnyJSON?
  public var error: PubNubError?

  enum CodingKeys: String, CodingKey {
    case shard = "a"
    case subscription = "b"
    case channel = "c"
    case payload = "d"
    case messageType = "e"
    case customMessageType = "cmt"
    case flags = "f"
    case publisher = "i"
    case subscribeKey = "k"
    case originTimetoken = "o"
    case publishTimetoken = "p"
    case meta = "u"
  }

  public enum Action: Int, Codable {
    case message = 0
    case signal = 1
    case object = 2
    case messageAction = 3
    case file = 4
    /// Presence Event type
    /// - warning: This is a client-side type and will be encoded as nil
    case presence = 99

    var asPubNubMessageType: PubNubMessageType {
      switch self {
      case .message:
        return .message
      case .signal:
        return .signal
      case .object:
        return .object
      case .messageAction:
        return .messageAction
      case .file:
        return .file
      case .presence:
        return .unknown
      }
    }
  }

  init(
    shard: String,
    subscription: String?,
    channel: String,
    messageType: Action,
    customMessageType: String? = nil,
    payload: AnyJSON,
    flags: Int,
    publisher: String?,
    subscribeKey: String,
    originTimetoken: SubscribeCursor?,
    publishTimetoken: SubscribeCursor,
    meta: AnyJSON?,
    error: PubNubError?
  ) {
    self.shard = shard
    self.subscription = subscription
    self.channel = channel
    self.messageType = messageType
    self.customMessageType = customMessageType
    self.payload = payload
    self.flags = flags
    self.publisher = publisher
    self.subscribeKey = subscribeKey
    self.originTimetoken = originTimetoken
    self.publishTimetoken = publishTimetoken
    self.metadata = meta
    self.error = error
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    shard = try container.decode(String.self, forKey: .shard)
    subscription = try container.decodeIfPresent(String.self, forKey: .subscription)?.trimmingPresenceChannelSuffix
    payload = try container.decode(AnyJSON.self, forKey: .payload)
    flags = try container.decode(Int.self, forKey: .flags)
    publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
    subscribeKey = try container.decode(String.self, forKey: .subscribeKey)
    originTimetoken = try container.decodeIfPresent(SubscribeCursor.self, forKey: .originTimetoken)
    publishTimetoken = try container.decode(SubscribeCursor.self, forKey: .publishTimetoken)
    metadata = try container.decodeIfPresent(AnyJSON.self, forKey: .meta)
    customMessageType = try container.decodeIfPresent(String.self, forKey: .customMessageType)

    let pubNubMessageType = try container.decodeIfPresent(Int.self, forKey: .messageType)
    let fullChannel = try container.decode(String.self, forKey: .channel)

    if let pubNubMessageType = pubNubMessageType, let action = Action(rawValue: pubNubMessageType) {
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
    error = nil
  }

  public func encode(to encoder: Encoder) throws {
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

    try container.encode(customMessageType, forKey: .customMessageType)
  }

  public var description: String {
    String.formattedDescription(
      self,
      arguments: [
        ("shard", shard),
        ("subscription", subscription?.description ?? "nil"),
        ("channel", channel),
        ("messageType", messageType),
        ("customMessageType", customMessageType ?? "nil"),
        ("payload", payload.jsonStringify ?? ""),
        ("flags", flags),
        ("publisher", publisher ?? "nil"),
        ("subscribeKey", subscribeKey),
        ("originTimetoken", originTimetoken ?? "nil"),
        ("publishTimetoken", publishTimetoken),
        ("metadata", metadata?.jsonStringify ?? "nil"),
        ("error", error?.reason ?? "nil")
      ]
    )
  }

  // swiftlint:disable:next file_length
}
