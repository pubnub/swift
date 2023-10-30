//
//  PubNubMembership.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
  /// The User half of the User-Space Membership relationship
  struct PartialUser {
    /// The associated User Entity
    public let user: PubNubUser
    /// The current state of the Membership
    public let status: String?
    /// All custom fields set on the Membership
    public let custom: FlatJSONCodable?
    /// The last updated timestamp for the Membership
    public let updated: Date?
    /// The caching identifier for the Membership
    public let eTag: String?

    public init(
      user: PubNubUser,
      status: String? = nil,
      custom: FlatJSONCodable? = nil,
      updated: Date? = nil,
      eTag: String? = nil
    ) {
      self.user = user
      self.status = status
      self.custom = custom
      self.updated = updated
      self.eTag = eTag
    }

    public init(
      userId: String,
      status: String? = nil,
      custom: FlatJSONCodable? = nil
    ) {
      self.init(
        user: .init(id: userId),
        status: status,
        custom: custom
      )
    }
  }

  /// The Space half of the User-Space Membership relationship
  struct PartialSpace {
    /// The associated Space Entity
    public let space: PubNubSpace
    /// The current state of the Membership
    public let status: String?
    /// All custom fields set on the Membership
    public let custom: FlatJSONCodable?
    /// The last updated timestamp for the Membership
    public let updated: Date?
    /// The caching identifier for the Membership
    public let eTag: String?

    public init(
      space: PubNubSpace,
      status: String? = nil,
      custom: FlatJSONCodable? = nil,
      updated: Date? = nil,
      eTag: String? = nil
    ) {
      self.space = space
      self.status = status
      self.custom = custom
      self.updated = updated
      self.eTag = eTag
    }

    public init(
      spaceId: String,
      status: String? = nil,
      custom: FlatJSONCodable? = nil
    ) {
      self.init(
        space: .init(id: spaceId),
        status: status,
        custom: custom
      )
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

  /// The Space half of this User-Space Membership relationship
  var partialSpace: PartialSpace {
    return .init(
      space: space,
      status: status,
      custom: custom,
      updated: updated,
      eTag: eTag
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

  /// The User half of this User-Space Membership relationship
  var partialUser: PartialUser {
    return .init(
      user: user,
      status: status,
      custom: custom,
      updated: updated,
      eTag: eTag
    )
  }
}

extension PubNubMembership.PartialUser: Codable, Hashable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubMembership.CodingKeys.self)

    user = try container.decode(PubNubUser.self, forKey: .user)
    status = try container.decodeIfPresent(String.self, forKey: .status)
    updated = try container.decodeIfPresent(Date.self, forKey: .updated)
    eTag = try container.decodeIfPresent(String.self, forKey: .eTag)
    custom = try container.decodeIfPresent(FlatJSON.self, forKey: .custom)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: PubNubMembership.CodingKeys.self)
    try container.encode(user, forKey: .user)
    try container.encode(status, forKey: .status)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)
    try container.encode(custom?.codableValue, forKey: .custom)
  }

  public static func == (
    lhs: PubNubMembership.PartialUser, rhs: PubNubMembership.PartialUser
  ) -> Bool {
    return lhs.user == rhs.user &&
      lhs.status == rhs.status &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag &&
      lhs.custom?.codableValue == rhs.custom?.codableValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(user)
    hasher.combine(status)
    hasher.combine(custom?.codableValue)
    hasher.combine(updated)
    hasher.combine(eTag)
  }
}

extension PubNubMembership.PartialSpace: Codable, Hashable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubMembership.CodingKeys.self)

    space = try container.decode(PubNubSpace.self, forKey: .space)
    status = try container.decodeIfPresent(String.self, forKey: .status)
    updated = try container.decodeIfPresent(Date.self, forKey: .updated)
    eTag = try container.decodeIfPresent(String.self, forKey: .eTag)
    custom = try container.decodeIfPresent(FlatJSON.self, forKey: .custom)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: PubNubMembership.CodingKeys.self)
    try container.encode(space, forKey: .space)
    try container.encode(status, forKey: .status)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)
    try container.encode(custom?.codableValue, forKey: .custom)
  }

  public static func == (
    lhs: PubNubMembership.PartialSpace, rhs: PubNubMembership.PartialSpace
  ) -> Bool {
    return lhs.space == rhs.space &&
      lhs.status == rhs.status &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag &&
      lhs.custom?.codableValue == rhs.custom?.codableValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(space)
    hasher.combine(status)
    hasher.combine(custom?.codableValue)
    hasher.combine(updated)
    hasher.combine(eTag)
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
