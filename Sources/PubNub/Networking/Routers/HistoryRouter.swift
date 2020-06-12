//
//  HistoryRouter.swift
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

struct HistoryRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case fetch(channels: [String], max: Int?, start: Timetoken?, end: Timetoken?, includeMeta: Bool)
    case fetchWithActions(channel: String, max: Int?, start: Timetoken?, end: Timetoken?, includeMeta: Bool)
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
      case let .fetchWithActions(channel, _, _, _, _):
        return channel
      case let .fetch(channels, _, _, _, _):
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
    case let .fetchWithActions(channel, _, _, _, _):
      path = "/v3/history-with-actions/sub-key/\(subscribeKey)/channel/\(channel)"
    case let .fetch(channels, _, _, _, _):
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
    case let .fetchWithActions(_, max, start, end, includeMeta):
      query.appendIfPresent(key: .max, value: max?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .includeMeta, value: includeMeta.description)
    case let .fetch(_, max, start, end, includeMeta):
      query.appendIfPresent(key: .max, value: max?.description)
      query.appendIfPresent(key: .start, value: start?.description)
      query.appendIfPresent(key: .end, value: end?.description)
      query.appendIfPresent(key: .includeMeta, value: includeMeta.description)
    case let .delete(_, startTimetoken, endTimetoken):
      query.appendIfPresent(key: .start, value: startTimetoken?.description)
      query.appendIfPresent(key: .end, value: endTimetoken?.description)
    case let .messageCounts(_, timetoken, channelsTimetoken):
      query.appendIfPresent(key: .timetoken, value: timetoken?.description)
      query.appendIfPresent(key: .channelsTimetoken,
                            value: channelsTimetoken?.map { $0.description }.csvString)
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
    case let .fetchWithActions(channel, _, _, _, _):
      return isInvalidForReason((channel.isEmpty, ErrorDescription.emptyChannelString))
    case let .fetch(channels, _, _, _, _):
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
      let payload = try Constant.jsonDecoder.decode(MessageHistoryResponse.self, from: response.payload)
      let decodedResponse = EndpointResponse<MessageHistoryResponse>(router: response.router,
                                                                     request: response.request,
                                                                     response: response.response,
                                                                     data: response.data,
                                                                     payload: payload)

      // Attempt to decode message response

      return .success(decodedResponse)
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }

  func decrypt(
    response: EndpointResponse<MessageHistoryResponse>
  ) -> Result<EndpointResponse<MessageHistoryResponse>, Error> {
    // End early if we don't have a cipher key
    guard let crypto = response.router.configuration.cipherKey else {
      return .success(response)
    }

    let channels = response.payload.channels.mapValues { messages -> [MessageHistoryMessagePayload] in
      // Mutable Copy
      var messages = messages
      // Replace index with decrypted message
      for (index, message) in messages.enumerated() {
        // Convert base64 string into Data
        if let messageData = message.message.dataOptional {
          // If a message fails we just return the original and move on
          do {
            let decryptedPayload = try crypto.decrypt(encrypted: messageData).get()
            if let decodedString = String(bytes: decryptedPayload, encoding: crypto.defaultStringEncoding) {
              messages[index] = MessageHistoryMessagePayload(message: AnyJSON(reverse: decodedString),
                                                             timetoken: message.timetoken,
                                                             meta: message.meta)
            } else {
              // swiftlint:disable:next line_length
              PubNub.log.error("Decrypted History payload data failed to stringify for base64 encoded payload \(decryptedPayload.base64EncodedString())")
            }
          } catch {
            PubNub.log.error("History message failed to decrypt due to \(error)")
          }
        }
      }
      return messages
    }

    // Replace previous payload with decrypted one
    let decryptedPayload = MessageHistoryResponse(status: response.payload.status,
                                                  error: response.payload.error,
                                                  errorMessage: response.payload.errorMessage,
                                                  channels: channels)
    let decryptedResponse = EndpointResponse<MessageHistoryResponse>(router: response.router,
                                                                     request: response.request,
                                                                     response: response.response,
                                                                     data: response.data,
                                                                     payload: decryptedPayload)
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

  let message: AnyJSON
  let timetoken: Timetoken
  let meta: AnyJSON?
  let actions: RawMessageAction

  init(
    message: JSONCodable,
    timetoken: Timetoken = 0,
    meta: JSONCodable? = nil,
    actions: RawMessageAction = [:]
  ) {
    self.message = message.codableValue
    self.timetoken = timetoken
    self.meta = meta?.codableValue
    self.actions = actions
  }

  enum CodingKeys: String, CodingKey {
    case message
    case timetoken
    case meta
    case actions
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    message = try container.decode(AnyJSON.self, forKey: .message)
    meta = try container.decodeIfPresent(AnyJSON.self, forKey: .meta)
    timetoken = Timetoken(try container.decode(String.self, forKey: .timetoken)) ?? 0
    actions = try container.decodeIfPresent(RawMessageAction.self, forKey: .actions) ?? [:]
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(message, forKey: .message)
    try container.encode(timetoken.description, forKey: .timetoken)
    try container.encodeIfPresent(meta, forKey: .meta)
    try container.encode(actions, forKey: .actions)
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
}
