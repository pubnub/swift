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
}

// MARK: - Response Body

struct SubscriptionResponsePayload: Codable {
  // Root Level
  public let token: TimetokenResponse
  public let messages: [MessageResponse]

  enum CodingKeys: String, CodingKey {
    case token = "t"
    case messages = "m"
  }
}

struct TimetokenResponse: Codable {
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

struct MessageResponse: Codable {
  public let shard: String
  public let subscriptionMatch: String?
  public let channel: String
  public let payload: AnyJSON
  public let flags: Int
  public let issuer: String
  public let subscribeKey: String
  public let originTimetoken: TimetokenResponse?
  public let publishTimetoken: TimetokenResponse
  public let metadata: AnyJSON?

  enum CodingKeys: String, CodingKey {
    case shard = "a"
    case subscriptionMatch = "b"
    case channel = "c"
    case payload = "d"
    case flags = "f"
    case issuer = "i"
    case subscribeKey = "k"
    case originTimetoken = "o"
    case publishTimetoken = "p"
    case metadata = "u"
  }
}
