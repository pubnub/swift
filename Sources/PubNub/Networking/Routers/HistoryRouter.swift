//
//  HistoryRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Router

struct HistoryRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case fetch(
      channels: [String], max: Int?, start: Timetoken?, end: Timetoken?,
      includeMeta: Bool, includeMessageType: Bool, includeCustomMessageType: Bool, includeUUID: Bool
    )
    case fetchWithActions(
      channel: String, max: Int?, start: Timetoken?, end: Timetoken?,
      includeMeta: Bool, includeMessageType: Bool, includeCustomMessageType: Bool, includeUUID: Bool
    )
    case delete(channel: String, start: Timetoken?, end: Timetoken?)
    case messageCounts(channels: [String], timetoken: Timetoken?, channelsTimetoken: [Timetoken]?)

    var description: String {
      switch self {
      case .fetch:
        return "Fetch Message History"
      case .fetchWithActions:
        return "Fetch Message History with Message Actions"
      case .delete:
        return "Delete Message History"
      case .messageCounts:
        return "Message Counts"
      }
    }

    var firstChannel: String? {
      switch self {
      case let .fetchWithActions(channel, _, _, _, _, _, _, _):
        return channel
      case let .fetch(channels, _, _, _, _, _, _, _):
        return channels.first
      case let .delete(channel, _, _):
        return channel
      case let .messageCounts(channels, _, _):
        return channels.first
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
    return .history
  }

  var category: String {
    return endpoint.description
  }

  var path: Result<String, Error> {
    let path: String

    switch endpoint {
    case let .fetchWithActions(channel, _, _, _, _, _, _, _):
      path = "/v3/history-with-actions/sub-key/\(subscribeKey)/channel/\(channel)"
    case let .fetch(channels, _, _, _, _, _, _, _):
      path = "/v3/history/sub-key/\(subscribeKey)/channel/\(channels.csvString.urlEncodeSlash)"
    case let .delete(channel, _, _):
      path = "/v3/history/sub-key/\(subscribeKey)/channel/\(channel.urlEncodeSlash)"
    case let .messageCounts(channels, _, _):
      path = "/v3/history/sub-key/\(subscribeKey)/message-counts/\(channels.csvString.urlEncodeSlash)"
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .fetchWithActions(_, max, start, end, includeMeta, includeMessageType, includeCustomMessageType, includeUUID):
      query.appendIfPresent(key: .max, value: max?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .includeMeta, value: includeMeta.description)
      query.appendIfPresent(key: .includeMessageType, value: includeMessageType.description)
      query.appendIfPresent(key: .includeCustomMessageType, value: includeCustomMessageType.description)
      query.appendIfPresent(key: .includeUUID, value: includeUUID.description)
    case let .fetch(_, max, start, end, includeMeta, includeMessageType, includeCustomMessageType, includeUUID):
      query.appendIfPresent(key: .max, value: max?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .includeMeta, value: includeMeta.description)
      query.appendIfPresent(key: .includeMessageType, value: includeMessageType.description)
      query.appendIfPresent(key: .includeCustomMessageType, value: includeCustomMessageType.description)
      query.appendIfPresent(key: .includeUUID, value: includeUUID.description)
    case let .delete(_, startTimetoken, endTimetoken):
      query.appendIfPresent(key: .start, value: startTimetoken?.description)
      query.appendIfPresent(key: .end, value: endTimetoken?.description)
    case let .messageCounts(_, timetoken, channelsTimetoken):
      query.appendIfPresent(key: .timetoken, value: timetoken?.description)
      query.appendIfPresent(key: .channelsTimetoken, value: channelsTimetoken?.map { $0.description }.csvString)
    }

    return .success(query)
  }

  var method: HTTPMethod {
    switch endpoint {
    case .delete:
      return .delete
    default:
      return .get
    }
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .fetchWithActions(channel, _, _, _, _, _, _, _):
      return isInvalidForReason((channel.isEmpty, ErrorDescription.emptyChannelString))
    case let .fetch(channels, _, _, _, _, _, _, _):
      return isInvalidForReason((channels.isEmpty, ErrorDescription.emptyChannelArray))
    case let .delete(channel, _, _):
      return isInvalidForReason((channel.isEmpty, ErrorDescription.emptyChannelString))
    case let .messageCounts(channels, timetoken, timetokens):
      return isInvalidForReason(
        (channels.isEmpty, ErrorDescription.emptyChannelArray),
        (timetoken == nil && timetokens == nil, ErrorDescription.missingTimetoken),
        (channels.count != timetokens?.count && timetokens != nil,
         ErrorDescription.invalidHistoryTimetokens)
      )
    }
  }
}

// MARK: - Response Decoder

struct MessageHistoryResponseDecoder: ResponseDecoder {
  func decode(response: EndpointResponse<Data>) -> Result<EndpointResponse<MessageHistoryResponse>, Error> {
    do {
      // Version3
      return .success(
        EndpointResponse<MessageHistoryResponse>(
          router: response.router,
          request: response.request,
          response: response.response,
          data: response.data,
          payload: try Constant.jsonDecoder.decode(MessageHistoryResponse.self, from: response.payload)
        )
      )
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }

  func decrypt(
    response: EndpointResponse<MessageHistoryResponse>
  ) -> Result<EndpointResponse<MessageHistoryResponse>, Error> {
    // End early if we don't have a cipher key
    guard let cryptoModule = response.router.configuration.cryptoModule else {
      return .success(response)
    }

    let channels = response.payload.channels.mapValues { messages -> [MessageHistoryMessagePayload] in
      // Mutable Copy
      var messages = messages
      // Replace index with decrypted message
      for (index, message) in messages.enumerated() {
        // Convert Base64 string into Data
        if let messageData = message.message.dataOptional {
          // If a message fails we just return the original and move on
          switch cryptoModule.decryptedString(from: messageData) {
          case .success(let decodedString):
            messages[index] = MessageHistoryMessagePayload(
              message: AnyJSON(reverse: decodedString),
              timetoken: message.timetoken,
              meta: message.meta,
              uuid: message.uuid,
              messageType: message.messageType,
              customMessageType: message.customMessageType,
              error: nil
            )
          case .failure(let error):
            messages[index] = MessageHistoryMessagePayload(
              message: message.message,
              timetoken: message.timetoken,
              meta: message.meta,
              uuid: message.uuid,
              messageType: message.messageType,
              customMessageType: message.customMessageType,
              error: error
            )
            PubNub.log.warn(
              "History message failed to decrypt due to \(error)",
              category: .crypto
            )
          }
        } else {
          let error = PubNubError(
            PubNubError.Reason.decryptionFailure,
            additional: ["Cannot decrypt message due to invalid Base-64 input"]
          )
          messages[index] = MessageHistoryMessagePayload(
            message: message.message,
            timetoken: message.timetoken,
            meta: message.meta,
            uuid: message.uuid,
            messageType: message.messageType,
            customMessageType: message.customMessageType,
            error: error
          )
          PubNub.log.warn(
            "History message failed to decrypt due to \(error)",
            category: .crypto
          )
        }
      }

      return messages
    }

    // Replace previous payload with decrypted one
    let decryptedResponse = EndpointResponse<MessageHistoryResponse>(
      router: response.router,
      request: response.request,
      response: response.response,
      data: response.data,
      payload: MessageHistoryResponse(
        status: response.payload.status,
        error: response.payload.error,
        errorMessage: response.payload.errorMessage,
        channels: channels
      )
    )
    return .success(decryptedResponse)
  }
}

// MARK: - Response Body

struct MessageHistoryResponse: Codable {
  let status: Int
  let error: Bool
  let errorMessage: String
  let channels: [String: [MessageHistoryMessagePayload]]

  let start: Timetoken?

  enum CodingKeys: String, CodingKey {
    case errorMessage = "error_message"
    case error
    case status
    case channels
    case more
  }

  enum MoreCodingKeys: String, CodingKey {
    case start
  }

  init(
    status: Int = 200,
    error: Bool = false,
    errorMessage: String = "",
    channels: [String: [MessageHistoryMessagePayload]] = [:],
    start: Timetoken? = nil
  ) {
    self.status = status
    self.error = error
    self.errorMessage = errorMessage
    self.channels = channels
    self.start = start
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    status = try container.decode(Int.self, forKey: .status)
    error = try container.decode(Bool.self, forKey: .error)
    errorMessage = try container.decode(String.self, forKey: .errorMessage)
    channels = try container.decodeIfPresent([String: [MessageHistoryMessagePayload]].self, forKey: .channels) ?? [:]

    let moreContainer = try? container.nestedContainer(keyedBy: MoreCodingKeys.self, forKey: .more)
    start = Timetoken(try moreContainer?.decodeIfPresent(String.self, forKey: .start) ?? "")
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(status, forKey: .status)
    try container.encode(error, forKey: .error)
    try container.encode(errorMessage, forKey: .errorMessage)
    try container.encode(channels, forKey: .channels)

    var moreContainer = container.nestedContainer(keyedBy: MoreCodingKeys.self, forKey: .more)
    try moreContainer.encodeIfPresent(start?.description, forKey: .start)
  }
}

struct MessageHistoryMessagePayload: Codable {
  typealias ActionType = String
  typealias ActionValue = String
  typealias RawMessageAction = [ActionType: [ActionValue: [MessageHistoryMessageAction]]]
  typealias LegacyPubNubMessageType = SubscribeMessagePayload.Action

  let message: AnyJSON
  let timetoken: Timetoken
  let meta: AnyJSON?
  let uuid: String?
  let messageType: LegacyPubNubMessageType?
  let customMessageType: String?
  let actions: RawMessageAction
  let error: PubNubError?

  init(
    message: JSONCodable,
    timetoken: Timetoken = 0,
    meta: JSONCodable? = nil,
    uuid: String?,
    messageType: LegacyPubNubMessageType?,
    customMessageType: String? = nil,
    actions: RawMessageAction = [:],
    error: PubNubError?
  ) {
    self.message = message.codableValue
    self.timetoken = timetoken
    self.uuid = uuid
    self.messageType = messageType
    self.customMessageType = customMessageType
    self.meta = meta?.codableValue
    self.actions = actions
    self.error = error
  }

  enum CodingKeys: String, CodingKey {
    case message
    case timetoken
    case meta
    case uuid
    case messageType = "message_type"
    case customMessageType = "custom_message_type"
    case actions
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    message = try container.decode(AnyJSON.self, forKey: .message)
    meta = try container.decodeIfPresent(AnyJSON.self, forKey: .meta)
    uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
    timetoken = Timetoken(try container.decode(String.self, forKey: .timetoken)) ?? 0
    actions = try container.decodeIfPresent(RawMessageAction.self, forKey: .actions) ?? [:]
    messageType = try container.decodeIfPresent(LegacyPubNubMessageType.self, forKey: .messageType) ?? .message
    customMessageType = try container.decodeIfPresent(String.self, forKey: .customMessageType)
    error = nil
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(message, forKey: .message)
    try container.encode(timetoken.description, forKey: .timetoken)
    try container.encodeIfPresent(meta, forKey: .meta)
    try container.encodeIfPresent(uuid, forKey: .uuid)
    try container.encode(actions, forKey: .actions)
    try container.encodeIfPresent(messageType, forKey: .messageType)
    try container.encodeIfPresent(customMessageType, forKey: .customMessageType)
  }
}

struct MessageHistoryMessageAction: Codable, Hashable {
  let uuid: String
  let actionTimetoken: Timetoken

  init(uuid: String, actionTimetoken: Timetoken) {
    self.uuid = uuid
    self.actionTimetoken = actionTimetoken
  }

  enum CodingKeys: String, CodingKey {
    case uuid
    case actionTimetoken
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    uuid = try container.decode(String.self, forKey: .uuid)
    actionTimetoken = Timetoken(try container.decode(String.self, forKey: .actionTimetoken)) ?? 0
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(uuid, forKey: .uuid)
    try container.encode(actionTimetoken.description, forKey: .actionTimetoken)
  }
}

// MARK: - Message Count

struct MessageCountsResponseDecoder: ResponseDecoder {
  typealias Payload = MessageCountsResponsePayload
}

struct MessageCountsResponsePayload: Codable, Hashable {
  let status: Int
  let error: Bool
  let errorMessage: String
  let channels: [String: Int]

  enum CodingKeys: String, CodingKey {
    case status
    case error
    case errorMessage = "error_message"
    case channels
  }

  // swiftlint:disable:next file_length
}
