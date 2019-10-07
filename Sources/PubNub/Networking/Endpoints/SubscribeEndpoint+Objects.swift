//
//  SubscribeEndpoint+Objects.swift
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

public enum ObjectAction: String, Codable, Hashable {
  case add = "create"
  case update
  case delete
}

public enum ObjectType: String, Codable, Hashable {
  case user
  case space
  case membership
}

public struct ObjectSubscribePayload: Codable {
  public let source: String
  public let version: String
  public let event: ObjectAction
  public let type: ObjectType
  public let data: AnyJSON
}

public struct IdentifierEvent: Codable, Hashable {
  public let id: String
}

// MARK: - Membership

public protocol MembershipIdentifiable {
  var userId: String { get }
  var spaceId: String { get }
}

public struct MembershipEvent: MembershipIdentifiable, Codable, Equatable {
  public let userId: String
  public let spaceId: String

  public let custom: [String: JSONCodableScalarType]
  public let updated: Date
  public let eTag: String

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    userId = try container.decode(String.self, forKey: .userId)
    spaceId = try container.decode(String.self, forKey: .spaceId)
    custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom) ?? [:]
    updated = try container.decodeIfPresent(Date.self, forKey: .updated) ?? Date.distantPast
    eTag = try container.decodeIfPresent(String.self, forKey: .eTag) ?? ""
  }
}
