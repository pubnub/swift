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

struct HereNowResponseDecoder: ResponseDecoder {
  typealias Payload = HereNowResponsePayload

  func decode(response: Response<Data>) -> Result<Response<Payload>, Error> {
    do {
      let hereNowPayload: HereNowResponsePayload

      // Single Channel w/o Group
      if let channels = response.endpoint.associatedValue["channels"] as? [String],
        channels.count == 1,
        let channel = channels.first,
        let groups = response.endpoint.associatedValue["groups"] as? [String],
        groups.isEmpty {
        hereNowPayload = try HereNowResponsePayload.response(for: channel,
                                                             from: response.payload,
                                                             using: Constant.jsonDecoder)
      } else {
        // Multi-Channel HereNow
        hereNowPayload = try Constant.jsonDecoder.decode(Payload.self, from: response.payload)
      }

      let decodedResponse = Response<Payload>(router: response.router,
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
}
