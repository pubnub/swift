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
      case .heartbeat(let channels, _, _):
        return channels
      case .leave(let channels, _):
        return channels
      case .hereNow(let channels, _, _, _):
        return channels
      case .getState(_, let channels, _):
        return channels
      case .setState(let channels, _, _):
        return channels
      default:
        return []
      }
    }

    var groups: [String] {
      switch self {
      case .heartbeat(_, let groups, _):
        return groups
      case let .leave(_, groups):
        return groups
      case .hereNow(_, let groups, _, _):
        return groups
      case let .getState(_, _, groups):
        return groups
      case .setState(_, let groups, _):
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
    case .heartbeat(let channels, _, _):
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels.commaOrCSVString.urlEncodeSlash)/heartbeat"
    case .leave(let channels, _):
      path = "/v2/presence/sub_key/\(subscribeKey)/channel/\(channels.commaOrCSVString.urlEncodeSlash)/leave"
    case .hereNow(let channels, _, _, _):
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels.csvString.urlEncodeSlash)"
    case .hereNowGlobal:
      path = "/v2/presence/sub-key/\(subscribeKey)"
    case let .whereNow(uuid):
      path = "/v2/presence/sub-key/\(subscribeKey)/uuid/\(uuid.urlEncodeSlash)"
    case let .getState(uuid, channels, _):
      let channels = channels.commaOrCSVString.urlEncodeSlash
      path = "/v2/presence/sub-key/\(subscribeKey)/channel/\(channels)/uuid/\(uuid.urlEncodeSlash)"
    case .setState(let channels, _, _):
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
  public let uuids: [HereNowUUIDPayload]

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: HereNowSingleResponsePayload.CodingKeys.self)

    status = try container.decode(Int.self, forKey: .status)
    message = try container.decode(String.self, forKey: .message)
    service = try container.decode(String.self, forKey: .service)

    occupancy = try container.decode(Int.self, forKey: .occupancy)

    if let stringList = try? container.decodeIfPresent([String].self, forKey: .uuids) {
      uuids = stringList.map { HereNowUUIDPayload(uuid: $0) }
    } else {
      uuids = try container.decodeIfPresent([HereNowUUIDPayload].self, forKey: .uuids) ?? []
    }
  }
}

public struct HereNowResponsePayload: Codable {
  public let status: Int
  public let message: String
  public let service: String
  public let payload: HereNowPayload

  static func response(
    for channel: String,
    from data: Data,
    using decoder: JSONDecoder
  ) throws -> HereNowResponsePayload {
    let payload = try decoder.decode(HereNowSingleResponsePayload.self, from: data)

    let channels: [String: HereNowChannelsPayload]
    if payload.occupancy == 0 {
      channels = [:]
    } else {
      channels = [channel: HereNowChannelsPayload(occupancy: payload.occupancy, uuids: payload.uuids)]
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
}

public struct HereNowChannelsPayload: Codable {
  public let occupancy: Int
  public let uuids: [HereNowUUIDPayload]

  public init(occupancy: Int, uuids: [HereNowUUIDPayload]) {
    self.occupancy = occupancy
    self.uuids = uuids
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: HereNowChannelsPayload.CodingKeys.self)

    occupancy = try container.decode(Int.self, forKey: .occupancy)

    if let stringList = try? container.decodeIfPresent([String].self, forKey: .uuids) {
      uuids = stringList.map { HereNowUUIDPayload(uuid: $0) }
    } else {
      uuids = try container.decodeIfPresent([HereNowUUIDPayload].self, forKey: .uuids) ?? []
    }
  }
}

public struct HereNowUUIDPayload: Codable {
  public let uuid: String
  public let state: [String: AnyJSON]?

  public init(uuid: String, state: [String: AnyJSON]? = nil) {
    self.uuid = uuid
    self.state = state
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
