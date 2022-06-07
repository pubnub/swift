//
//  PubNubMembership.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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

import PubNub
import PubNubSpace
import PubNubUser

/// A concrete representation of  a Membership entity in PubNub
public struct PubNubMembership {
  /// The associated User Entity
  public var user: PubNubUser
  /// The associated Space Entity
  public var space: PubNubSpace

  /// The current state of the Membership
  public var status: String?

  /// All custom fields set on the Membership
  public var custom: FlatJSONCodable?

  /// The last updated timestamp for the Membership
  public var updated: Date?
  /// The caching identifier for the Membership
  public var eTag: String?

  public init(
    user: PubNubUser,
    space: PubNubSpace,
    status: String? = nil,
    custom: FlatJSONCodable? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.user = user
    self.space = space
    self.status = status
    self.custom = custom
    self.updated = updated
    self.eTag = eTag
  }
}

// MARK: Hashable

extension PubNubMembership: Hashable {
  public static func == (lhs: PubNubMembership, rhs: PubNubMembership) -> Bool {
    return lhs.user == rhs.user &&
      lhs.space == rhs.space &&
      lhs.status == rhs.status &&
      lhs.custom?.codableValue == rhs.custom?.codableValue &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(user)
    hasher.combine(space)
    hasher.combine(status)
    hasher.combine(custom?.codableValue)
    hasher.combine(updated)
    hasher.combine(eTag)
  }
}

// MARK: Codable

extension PubNubMembership: Codable {
  /// Coding Keys used to serialize a PubNubMembership from JSON
  public enum CodingKeys: String, CodingKey {
    case user = "uuid"
    case space = "channel"
    case status
    case custom
    case updated
    case eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    user = try container.decode(PubNubUser.self, forKey: .user)
    space = try container.decode(PubNubSpace.self, forKey: .space)
    status = try container.decodeIfPresent(String.self, forKey: .status)
    custom = try container.decodeIfPresent(FlatJSON.self, forKey: .custom)
    updated = try container.decodeIfPresent(Date.self, forKey: .updated)
    eTag = try container.decodeIfPresent(String.self, forKey: .eTag)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(user, forKey: .user)
    try container.encode(space, forKey: .space)
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(custom?.codableValue, forKey: .custom)
    try container.encodeIfPresent(updated, forKey: .updated)
    try container.encodeIfPresent(eTag, forKey: .eTag)
  }
}

// MARK: Partial Links

public extension PubNubMembership {
  /// One half of the Membership relationship
  typealias Partial = (id: String, status: String?, custom: FlatJSONCodable?)

  struct PartialUser: Codable {
    public let user: PubNubUser
    public let status: String?
    public let custom: FlatJSON?
    public let updated: Date?
    public let eTag: String?

    public init(
      user: PubNubUser,
      status: String? = nil,
      custom: FlatJSONCodable? = nil
    ) {
      self.user = user
      self.status = status
      self.custom = FlatJSON(flatJSON: custom?.flatJSON)
      updated = nil
      eTag = nil
    }

    enum CodingKeys: String, CodingKey {
      case user = "uuid"
      case status
      case custom
      case updated
      case eTag
    }
  }

  struct PartialSpace: Codable {
    public let space: PubNubSpace
    public let status: String?
    public let custom: FlatJSON?
    public let updated: Date?
    public let eTag: String?

    public init(
      space: PubNubSpace,
      status: String? = nil,
      custom: FlatJSONCodable? = nil
    ) {
      self.space = space
      self.status = status
      self.custom = FlatJSON(flatJSON: custom?.flatJSON)
      updated = nil
      eTag = nil
    }

    enum CodingKeys: String, CodingKey {
      case space = "channel"
      case status
      case custom
      case updated
      case eTag
    }
  }

  init(user: PubNubUser, space partial: PartialSpace) {
    self.init(
      user: user,
      space: partial.space,
      status: partial.status,
      custom: partial.custom,
      updated: partial.updated,
      eTag: partial.eTag
    )
  }

  init(space: PubNubSpace, user partial: PartialUser) {
    self.init(
      user: partial.user,
      space: space,
      status: partial.status,
      custom: partial.custom,
      updated: partial.updated,
      eTag: partial.eTag
    )
  }
}

// MARK: Object v2 Migration

public extension PubNubMembershipMetadata {
  /// Converts Object V2 Membership Metadata to a Membership entity
  ///
  /// - returns: The `PubNubMembership` built from the Object V2 data
  func convert() -> PubNubMembership {
    return PubNubMembership(
      user: uuid?.convert() ?? PubNubUser(id: uuidMetadataId),
      space: channel?.convert() ?? PubNubSpace(id: channelMetadataId),
      status: status,
      custom: custom == nil ? nil : FlatJSON(flatJSON: custom),
      updated: updated,
      eTag: eTag
    )
  }
}
