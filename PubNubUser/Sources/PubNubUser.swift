//
//  PubNubUser.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

/// A concrete representation of  a User entity in PubNub
public struct PubNubUser {
  /// The unique identifier of the User
  public var id: String
  /// The name of the User
  public var name: String?
  /// The classification of User
  public var type: String?
  /// The current state of the User
  public var status: String?
  /// The external identifier for the User
  public var externalId: String?
  /// The profile URL for the User
  public var profileURL: URL?
  /// The email address of the User
  public var email: String?
  /// All custom properties set on the User
  public var custom: FlatJSONCodable?
  /// The last updated timestamp for the User
  public var updated: Date?
  /// The caching identifier for the User
  public var eTag: String?

  public init(
    id: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    externalId: String? = nil,
    profileURL: URL? = nil,
    email: String? = nil,
    custom: FlatJSONCodable? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.status = status
    self.externalId = externalId
    self.profileURL = profileURL
    self.email = email
    self.custom = custom
    self.updated = updated
    self.eTag = eTag
  }
}

// MARK: Hashable

extension PubNubUser: Hashable {
  public static func == (lhs: PubNubUser, rhs: PubNubUser) -> Bool {
    return lhs.id == rhs.id &&
      lhs.name == rhs.name &&
      lhs.type == rhs.type &&
      lhs.status == rhs.status &&
      lhs.externalId == rhs.externalId &&
      lhs.profileURL == rhs.profileURL &&
      lhs.email == rhs.email &&
      lhs.custom?.codableValue == rhs.custom?.codableValue &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(type)
    hasher.combine(status)
    hasher.combine(externalId)
    hasher.combine(profileURL)
    hasher.combine(email)
    hasher.combine(custom?.codableValue)
    hasher.combine(updated)
    hasher.combine(eTag)
  }
}

// MARK: Codable

extension PubNubUser: Codable {
  /// Coding Keys used to serialize a PubNubUser from JSON
  public enum CodingKeys: String, CodingKey {
    case id
    case name
    case type
    case status
    case externalId
    case profileUrl
    case email
    case custom
    case updated
    case eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    type = try container.decodeIfPresent(String.self, forKey: .type)
    status = try container.decodeIfPresent(String.self, forKey: .status)
    externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
    if let profileURL = try container.decodeIfPresent(String.self, forKey: .profileUrl) {
      self.profileURL = URL(string: profileURL)
    }
    email = try container.decodeIfPresent(String.self, forKey: .email)
    custom = try container.decodeIfPresent(FlatJSON.self, forKey: .custom)
    updated = try container.decodeIfPresent(Date.self, forKey: .updated)
    eTag = try container.decodeIfPresent(String.self, forKey: .eTag)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encodeIfPresent(name, forKey: .name)
    try container.encodeIfPresent(type, forKey: .type)
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(externalId, forKey: .externalId)
    try container.encodeIfPresent(profileURL?.absoluteString, forKey: .profileUrl)
    try container.encodeIfPresent(email, forKey: .email)
    try container.encodeIfPresent(custom?.codableValue, forKey: .custom)
    try container.encodeIfPresent(updated, forKey: .updated)
    try container.encodeIfPresent(eTag, forKey: .eTag)
  }
}

// MARK: Object v2 Migration

public extension PubNubUUIDMetadata {
  /// Converts Object V2 UUID Metadata to a Space entity
  ///
  /// - returns: The `PubNubUser` built from the Object V2 data
  func convert() -> PubNubUser {
    return PubNubUser(
      id: metadataId,
      name: name,
      type: type,
      status: status,
      externalId: externalId,
      profileURL: URL(string: profileURL ?? ""),
      email: email,
      custom: custom == nil ? nil : FlatJSON(flatJSON: custom),
      updated: updated,
      eTag: eTag
    )
  }
}
