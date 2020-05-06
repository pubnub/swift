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

public struct AnyPresencePayload<Payload>: Codable where Payload: Codable {
  public let status: Int
  public let message: String
  public let service: String
  public let payload: Payload
}

// MARK: - Heree Now Response

struct HereNowResponseDecoder: ResponseDecoder {
  typealias Payload = HereNowResponsePayload

  func decode(response: EndpointResponse<Data>) -> Result<EndpointResponse<Payload>, Error> {
    do {
      let hereNowPayload: HereNowResponsePayload

      // Single Channel w/o Group

      if let channels = (response.router as? PresenceRouter)?.endpoint.channels,
        channels.count == 1,
        let channel = channels.first,
        let groups = (response.router as? PresenceRouter)?.endpoint.groups,
        groups.isEmpty {
        hereNowPayload = try HereNowResponsePayload.response(for: channel,
                                                             from: response.payload,
                                                             using: Constant.jsonDecoder)
      } else {
        // Multi-Channel HereNow
        hereNowPayload = try Constant.jsonDecoder.decode(Payload.self, from: response.payload)
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

public struct HereNowSingleResponsePayload: Codable {
  public let status: Int
  public let message: String
  public let service: String
  public let occupancy: Int
  public let occupants: [String: [String: AnyJSON]?]

  public init(
    status: Int = 200,
    message: String = "OK",
    service: String = "Presence",
    occupancy: Int,
    occupants: [String: [String: AnyJSON]?]
  ) {
    self.status = status
    self.message = message
    self.service = service
    self.occupancy = occupancy
    self.occupants = occupants

    UUIDs = occupants.map { HereNowUUIDPayload(uuid: $0.key, state: $0.value) }
  }

  @available(*, deprecated, message: "Use the `occupants` dictionary instead")
  public var uuids: [HereNowUUIDPayload] {
    return UUIDs
  }

  private let UUIDs: [HereNowUUIDPayload]

  public enum CodingKeys: String, CodingKey {
    case status
    case message
    case service
    case occupancy
    case occupants = "uuids"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: HereNowSingleResponsePayload.CodingKeys.self)

    status = try container.decode(Int.self, forKey: .status)
    message = try container.decode(String.self, forKey: .message)
    service = try container.decode(String.self, forKey: .service)

    occupancy = try container.decode(Int.self, forKey: .occupancy)

    var occupants = [String: [String: AnyJSON]?]()
    if let stringList = try? container.decodeIfPresent([String].self, forKey: .occupants) {
      UUIDs = stringList.map { HereNowUUIDPayload(uuid: $0) }
    } else {
      UUIDs = try container.decodeIfPresent([HereNowUUIDPayload].self, forKey: .occupants) ?? []
    }
    UUIDs.forEach { occupants[$0.uuid] = $0.state }
    self.occupants = occupants
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(status, forKey: .status)
    try container.encode(message, forKey: .message)
    try container.encode(service, forKey: .service)
    try container.encode(occupancy, forKey: .occupancy)
    try container.encode(occupants.map { HereNowUUIDPayload(uuid: $0.key, state: $0.value) }, forKey: .occupants)
  }
}

public struct HereNowResponsePayload: Codable {
  public let status: Int
  public let message: String
  public let service: String
  public let payload: HereNowPayload

  public init(
    status: Int = 200,
    message: String = "OK",
    service: String = "Presence",
    payload: HereNowPayload
  ) {
    self.status = status
    self.message = message
    self.service = service
    self.payload = payload
  }

  public static func response(
    for channel: String,
    from data: Data,
    using decoder: JSONDecoder
  ) throws -> HereNowResponsePayload {
    let payload = try decoder.decode(HereNowSingleResponsePayload.self, from: data)

    let channels: [String: HereNowChannelsPayload]
    if payload.occupancy == 0 {
      channels = [:]
    } else {
      channels = [channel: HereNowChannelsPayload(occupancy: payload.occupancy, occupants: payload.occupants)]
    }

    let hereNowPayload = HereNowPayload(channels: channels,
                                        totalOccupancy: payload.occupancy,
                                        totalChannels: channels.count)

    return HereNowResponsePayload(status: payload.status,
                                  message: payload.message,
                                  service: payload.service,
                                  payload: hereNowPayload)
  }
}

public struct HereNowPayload: Codable {
  public let channels: [String: HereNowChannelsPayload]
  public let totalOccupancy: Int
  public let totalChannels: Int

  enum CodingKeys: String, CodingKey {
    case totalOccupancy = "total_occupancy"
    case totalChannels = "total_channels"
    case channels
  }

  public init(channels: [String: HereNowChannelsPayload], totalOccupancy: Int, totalChannels: Int) {
    self.channels = channels
    self.totalOccupancy = totalOccupancy
    self.totalChannels = totalChannels
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    totalOccupancy = try container.decodeIfPresent(Int.self, forKey: .totalOccupancy) ?? 0
    totalChannels = try container.decodeIfPresent(Int.self, forKey: .totalChannels) ?? 0

    // Server responses with empty list instead of empty object when channels is empty
    let anyChannels = try container.decode(AnyJSON.self, forKey: .channels)
    if !anyChannels.isEmpty, let channels = try? anyChannels.decode([String: HereNowChannelsPayload].self) {
      self.channels = channels
    } else {
      channels = [:]
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(totalOccupancy, forKey: .totalOccupancy)
    try container.encode(totalChannels, forKey: .totalChannels)

    if channels.isEmpty {
      // Empty channels encodes as empty list instead of empty object
      try container.encode([String](), forKey: .channels)
    } else {
      try container.encode(channels, forKey: .channels)
    }
  }
}

public struct HereNowChannelsPayload: Codable {
  public let occupancy: Int
  public let occupants: [String: [String: AnyJSON]?]

  // Deprecated
  @available(*, deprecated, message: "Use the `occupants` dictionary instead")
  public var uuids: [HereNowUUIDPayload] {
    return UUIDs
  }

  // Used to avoid having deprecated warnings internally
  private let UUIDs: [HereNowUUIDPayload]

  @available(*, deprecated, message: "Instead use `init(occupancy:occupants:)`")
  public init(occupancy: Int, uuids: [HereNowUUIDPayload]) {
    self.occupancy = occupancy
    UUIDs = uuids
    var occupants = [String: [String: AnyJSON]?]()
    uuids.forEach { occupants[$0.uuid] = $0.state }
    self.occupants = occupants
  }

  public init(occupancy: Int, occupants: [String: [String: AnyJSON]?]) {
    self.occupancy = occupancy
    self.occupants = occupants
    UUIDs = occupants.map { HereNowUUIDPayload(uuid: $0.key, state: $0.value) }
  }

  enum CodingKeys: String, CodingKey {
    case occupancy
    case occupants = "uuids"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    occupancy = try container.decode(Int.self, forKey: .occupancy)

    var occupants = [String: [String: AnyJSON]?]()
    if let stringList = try? container.decodeIfPresent([String].self, forKey: .occupants) {
      UUIDs = stringList.map { HereNowUUIDPayload(uuid: $0) }
    } else {
      UUIDs = try container.decodeIfPresent([HereNowUUIDPayload].self, forKey: .occupants) ?? []
    }
    UUIDs.forEach { occupants[$0.uuid] = $0.state }
    self.occupants = occupants
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(occupancy, forKey: .occupancy)
    try container.encode(occupants.map { HereNowUUIDPayload(uuid: $0.key, state: $0.value) }, forKey: .occupants)
  }
}

public struct HereNowUUIDPayload: Codable, Equatable {
  public let uuid: String
  public let state: [String: AnyJSON]?

  public init(uuid: String, state: [String: AnyJSON]? = nil) {
    self.uuid = uuid
    self.state = state?.mapValues { $0.codableValue }
  }

  public func encode(to encoder: Encoder) throws {
    if let state = state {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(uuid, forKey: .uuid)
      try container.encode(state, forKey: .state)
    } else {
      var container = encoder.singleValueContainer()

      try container.encode(uuid)
    }
  }
}

// MARK: Where Now Response

public typealias WhereNowResponsePayload = AnyPresencePayload<WhereNowPayload>

public struct WhereNowPayload: Codable {
  public let channels: [String]
}

struct SetPresenceStateResponseDecoder: ResponseDecoder {
  typealias Payload = SetPresenceStatePayload
}

// MARK: - Response Body

public struct SetPresenceStatePayload: Codable {
  public var status: Int
  public var message: String
  public var service: String
  public var payload: [String: AnyJSON]

  public init(
    status: Int = 200,
    message: String = "OK",
    service: String = "Presence",
    payload: [String: AnyJSON]
  ) {
    self.status = status
    self.message = message
    self.service = service
    self.payload = payload
  }
}

extension SetPresenceStatePayload {
  public func normalizedPayload(using channels: [String]) -> [String: [String: AnyJSON]] {
    var normalizedPayload = [String: [String: AnyJSON]]()
    channels.forEach { normalizedPayload[$0] = payload }
    return normalizedPayload
  }
}

// Get State Payloads

public struct SinglePresenceStatePayload: Codable {
  public var status: Int
  public var message: String
  public var service: String

  public var uuid: String

  public var channel: String
  public var payload: [String: AnyJSON]

  public init(
    status: Int = 200,
    message: String = "OK",
    service: String = "Presence",
    uuid: String,
    channel: String,
    payload: [String: AnyJSON]
  ) {
    self.status = status
    self.message = message
    self.service = service
    self.uuid = uuid
    self.channel = channel
    self.payload = payload
  }
}

extension SinglePresenceStatePayload {
  public var normalizedPayload: [String: [String: AnyJSON]] {
    return [channel: payload]
  }
}

public struct MultiPresenceStatePayload: Codable {
  public var status: Int
  public var message: String
  public var service: String
  public var payload: PresenceChannelsPayload

  public init(
    status: Int = 200,
    message: String = "OK",
    service: String = "Presence",
    channels: [String: [String: AnyJSON]]
  ) {
    self.status = status
    self.message = message
    self.service = service
    payload = PresenceChannelsPayload(channels: channels)
  }
}

extension MultiPresenceStatePayload {
  public var normalizedPayload: [String: [String: AnyJSON]] {
    return payload.channels
  }
}

public struct PresenceChannelsPayload: Codable, Equatable {
  public var channels: [String: [String: AnyJSON]]
  // swiftlint:disable:next file_length
}
