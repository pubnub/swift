//
//  PresenceRouter.swift
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

struct PresenceRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case heartbeat(channels: [String], groups: [String], presenceTimeout: UInt?)
    case leave(channels: [String], groups: [String])
    case hereNow(channels: [String], groups: [String], includeUUIDs: Bool, includeState: Bool)
    case hereNowGlobal(includeUUIDs: Bool, includeState: Bool)
    case whereNow(uuid: String)
    case getState(uuid: String, channels: [String], groups: [String])
    case setState(channels: [String], groups: [String], state: [String: JSONCodable])

    var description: String {
      switch self {
      case .heartbeat:
        return "Heartbeat"
      case .leave:
        return "Leave"
      case .setState:
        return "Set Presence State"
      case .getState:
        return "Get Presence State"
      case .hereNow:
        return "Here Now"
      case .hereNowGlobal:
        return "Global Here Now"
      case .whereNow:
        return "Where Now"
      }
    }

    var channels: [String] {
      switch self {
      case let .heartbeat(channels, _, _):
        return channels
      case let .leave(channels, _):
        return channels
      case let .hereNow(channels, _, _, _):
        return channels
      case let .getState(_, channels, _):
        return channels
      case let .setState(channels, _, _):
        return channels
      default:
        return []
      }
    }

    var groups: [String] {
      switch self {
      case let .heartbeat(_, groups, _):
        return groups
      case let .leave(_, groups):
        return groups
      case let .hereNow(_, groups, _, _):
        return groups
      case let .getState(_, _, groups):
        return groups
      case let .setState(_, groups, _):
        return groups
      default:
        return []
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
    return .presence
  }

  var category: String {
    return endpoint.description
  }

  var path: Result<String, Error> {
    let path: String

    switch endpoint {
    case let .heartbeat(channels, _, _):
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels.commaOrCSVString.urlEncodeSlash)/heartbeat"
    case let .leave(channels, _):
      path = "/v2/presence/sub_key/\(subscribeKey)/channel/\(channels.commaOrCSVString.urlEncodeSlash)/leave"
    case let .hereNow(channels, _, _, _):
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels.commaOrCSVString.urlEncodeSlash)"
    case .hereNowGlobal:
      path = "/v2/presence/sub-key/\(subscribeKey)"
    case let .whereNow(uuid):
      path = "/v2/presence/sub-key/\(subscribeKey)/uuid/\(uuid.urlEncodeSlash)"
    case let .getState(uuid, channels, _):
      let channels = channels.commaOrCSVString.urlEncodeSlash
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels)/uuid/\(uuid.urlEncodeSlash)"
    case let .setState(channels, _, _):
      let channels = channels.commaOrCSVString.urlEncodeSlash
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels)/uuid/\(configuration.uuid.urlEncodeSlash)/data"
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .heartbeat(_, groups, presenceTimeout):
      query.appendIfNotEmpty(key: .channelGroup, value: groups)
      query.appendIfPresent(key: .heartbeat, value: presenceTimeout?.description)
    case let .leave(_, groups):
      query.appendIfNotEmpty(key: .channelGroup, value: groups)
    case let .hereNow(_, groups, includeUUIDs, includeState):
      query.appendIfNotEmpty(key: .channelGroup, value: groups)
      query.append(URLQueryItem(key: .disableUUIDs, value: (!includeUUIDs).stringNumber))
      query.append(URLQueryItem(key: .state, value: includeState.stringNumber))
    case let .hereNowGlobal(includeUUIDs, includeState):
      query.append(URLQueryItem(key: .disableUUIDs, value: (!includeUUIDs).stringNumber))
      query.append(URLQueryItem(key: .state, value: includeState.stringNumber))
    case .whereNow:
      break
    case let .getState(_, _, groups):
      query.appendIfNotEmpty(key: .channelGroup, value: groups)
    case let .setState(_, groups, state):
      query.appendIfNotEmpty(key: .channelGroup, value: groups)
      if !state.isEmpty {
        return state.mapValues { $0.codableValue }.encodableJSONString.map { json in
          query.append(URLQueryItem(key: .state, value: json))
          return query
        }
      } else {
        query.append(URLQueryItem(key: .state, value: "{}"))
      }
    }

    return .success(query)
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .heartbeat(channels, groups, _):
      return isInvalidForReason(
        (channels.isEmpty && groups.isEmpty, ErrorDescription.missingChannelsAnyGroups))
    case let .leave(channels, groups):
      return isInvalidForReason(
        (channels.isEmpty && groups.isEmpty, ErrorDescription.missingChannelsAnyGroups))
    case let .hereNow(channels, groups, _, _):
      return isInvalidForReason(
        (channels.isEmpty && groups.isEmpty, ErrorDescription.missingChannelsAnyGroups))
    case .hereNowGlobal:
      return nil
    case let .whereNow(uuid):
      return isInvalidForReason((uuid.isEmpty, ErrorDescription.emptyUUIDString))
    case let .getState(uuid, channels, groups):
      return isInvalidForReason(
        (uuid.isEmpty, ErrorDescription.emptyUUIDString),
        (channels.isEmpty && groups.isEmpty, ErrorDescription.missingChannelsAnyGroups)
      )
    case let .setState(channels, groups, _):
      return isInvalidForReason(
        (channels.isEmpty && groups.isEmpty, ErrorDescription.missingChannelsAnyGroups))
    }
  }
}

// MARK: - Response Decoder

struct PresenceResponseDecoder<PresencePayload>: ResponseDecoder where PresencePayload: Codable {
  typealias Payload = PresencePayload
}

// MARK: - Generic Presence Response

struct AnyPresencePayload<Payload>: Codable where Payload: Codable {
  let status: Int
  let message: String
  let service: String
  let payload: Payload
}

// MARK: - Heree Now Response

struct HereNowResponseDecoder: ResponseDecoder {
  typealias Payload = [String: HereNowChannelsPayload]

  var channels: [String] = []
  var groups: [String] = []

  init(channels: [String], groups: [String]) {
    self.channels = channels
    self.groups = groups
  }

  func decode(response: EndpointResponse<Data>) -> Result<EndpointResponse<Payload>, Error> {
    do {
      let hereNowPayload: [String: HereNowChannelsPayload]

      // Single Channel w/o Groups
      if channels.count == 1, groups.isEmpty, let channel = channels.first {
        hereNowPayload = [channel: try Constant.jsonDecoder.decode(HereNowChannelsPayload.self, from: response.payload)]
      } else {
        // Multi-Channel HereNow
        hereNowPayload = try Constant.jsonDecoder.decode(
          AnyPresencePayload<AllHereNowPayload>.self, from: response.payload
        ).payload.channels
      }

      let decodedResponse = EndpointResponse<Payload>(router: response.router,
                                                      request: response.request,
                                                      response: response.response,
                                                      data: response.data,
                                                      payload: hereNowPayload)

      return .success(decodedResponse)
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }
}

struct AllHereNowPayload: Codable {
  let totalOccupancy: Int?
  let totalChannels: Int?

  var channels: [String: HereNowChannelsPayload]

  enum CodingKeys: String, CodingKey {
    case totalOccupancy = "total_occupancy"
    case totalChannels = "total_channels"
    case channels

    case occupancy
    case occupants = "uuids"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    totalOccupancy = try container.decodeIfPresent(Int.self, forKey: .totalOccupancy) ?? 0
    totalChannels = try container.decodeIfPresent(Int.self, forKey: .totalChannels) ?? 0
    channels = try container.decode([String: HereNowChannelsPayload].self, forKey: .channels)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(totalOccupancy, forKey: .totalOccupancy)
    try container.encode(totalChannels, forKey: .totalChannels)
    try container.encode(channels, forKey: .channels)
  }
}

struct HereNowChannelsPayload: Codable {
  let occupancy: Int
  let occupants: [String]
  let occupantsState: [String: JSONCodable]

  init(
    occupancy: Int,
    occupants: [String],
    occupantsState: [String: JSONCodable] = [:]
  ) {
    self.occupancy = occupancy
    self.occupants = occupants
    self.occupantsState = occupantsState
  }

  enum CodingKeys: String, CodingKey {
    case occupancy
    case occupants = "uuids"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    occupancy = try container.decode(Int.self, forKey: .occupancy)

    if let occupants = try? container.decodeIfPresent([String].self, forKey: .occupants) {
      self.occupants = occupants
      occupantsState = [:]
    } else {
      let occupantList = try container.decodeIfPresent([HereNowUUIDPayload].self, forKey: .occupants) ?? []

      var occupants = [String]()
      var occupantsState = [String: JSONCodable]()

      for occupant in occupantList {
        occupants.append(occupant.uuid)
        occupantsState[occupant.uuid] = occupant.state
      }
      self.occupants = occupants
      self.occupantsState = occupantsState
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(occupancy, forKey: .occupancy)

    if occupantsState.isEmpty {
      // Encode as a list of UUIDs
      try container.encode(occupants, forKey: .occupants)
    } else {
      // Encode as an UUID/State Object
      var occupantsContainer = container.nestedUnkeyedContainer(forKey: .occupants)
      for uuid in occupants {
        try occupantsContainer.encode(HereNowUUIDPayload(uuid: uuid, state: occupantsState[uuid]))
      }
    }
  }
}

struct HereNowUUIDPayload: Codable, Equatable {
  let uuid: String
  let state: AnyJSON?

  init(uuid: String, state: JSONCodable?) {
    self.uuid = uuid
    self.state = state?.codableValue
  }
}

// MARK: Where Now Response

typealias WhereNowResponsePayload = AnyPresencePayload<WhereNowPayload>

struct WhereNowPayload: Codable {
  let channels: [String]
}

// Get State Payloads

struct GetPresenceStateResponseDecoder: ResponseDecoder {
  typealias Payload = GetPresenceStatePayload
}

struct GetPresenceStatePayload: Codable {
  public var status: Int
  public var message: String
  public var service: String
  public var uuid: String
  public var channels: [String: AnyJSON]

  public init(
    status: Int = 200,
    message: String = "OK",
    service: String = "Presence",
    uuid: String,
    channels: [String: AnyJSON]
  ) {
    self.status = status
    self.message = message
    self.service = service
    self.uuid = uuid
    self.channels = channels
  }

  enum CodingKeys: String, CodingKey {
    case status
    case message
    case service
    case uuid

    case channel
    case payload
  }

  enum ChannelsCodingKeys: String, CodingKey {
    case channels
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    status = try container.decode(Int.self, forKey: .status)
    message = try container.decode(String.self, forKey: .message)
    service = try container.decode(String.self, forKey: .service)
    uuid = try container.decode(String.self, forKey: .uuid)

    if let channel = try? container.decode(String.self, forKey: .channel) {
      let payload = try container.decode(AnyJSON.self, forKey: .payload)
      channels = [channel: payload]
    } else {
      let channelsContainer = try container.nestedContainer(keyedBy: ChannelsCodingKeys.self, forKey: .payload)
      channels = try channelsContainer.decode([String: AnyJSON].self, forKey: .channels)
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(status, forKey: .status)
    try container.encode(message, forKey: .message)
    try container.encode(service, forKey: .service)
    try container.encode(uuid, forKey: .uuid)

    if channels.keys.count > 1 {
      var channelsContainer = container.nestedContainer(keyedBy: ChannelsCodingKeys.self, forKey: .payload)
      try channelsContainer.encode(channels, forKey: .channels)
    } else {
      try container.encodeIfPresent(channels.first?.key, forKey: .channel)
      try container.encodeIfPresent(channels.first?.value, forKey: .payload)
    }
  }

  // swiftlint:disable:next file_length
}
