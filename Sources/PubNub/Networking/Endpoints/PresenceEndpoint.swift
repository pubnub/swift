//
//  PresenceEndpoint.swift
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

public typealias HereNowResponsePayload = AnyPresencePayload<HereNowPayload>

public struct HereNowPayload: Codable {
  public let totalOccupancy: Int
  public let totalChannels: Int
  public let channels: [String: HereNowChannelsPayload]

  enum CodingKeys: String, CodingKey {
    case totalOccupancy = "total_occupancy"
    case totalChannels = "total_channels"
    case channels
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

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: HereNowChannelsPayload.CodingKeys.self)
    occupancy = try container.decodeIfPresent(Int.self, forKey: .occupancy) ?? 0
    uuids = try container.decodeIfPresent([HereNowUUIDPayload].self, forKey: .uuids) ?? []
  }
}

public struct HereNowUUIDPayload: Codable {
  public let uuid: String
  // swiftlint:disable:next discouraged_optional_collection
  public let state: [String: AnyJSON]?
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
}
