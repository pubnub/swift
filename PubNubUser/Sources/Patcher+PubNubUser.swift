//
//  Patcher+PubNubUser.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

public extension PubNubUser {
  /// Object that can be used to apply an update to another User
  struct Patcher {
    /// The unique identifier of the object that was changed
    public let id: String
    /// The name of the User
    public let name: OptionalChange<String>
    /// The classification of User
    public let type: OptionalChange<String>
    /// The current state of the User
    public let status: OptionalChange<String>
    /// The external identifier for the User
    public let externalId: OptionalChange<String>
    /// The profile URL for the User
    public let profileURL: OptionalChange<URL>
    /// The email address of the User
    public let email: OptionalChange<String>
    /// All custom fields set on the User
    public let custom: OptionalChange<FlatJSONCodable>
    /// The timestamp of the change
    public let updated: Date
    /// The cache identifier of the change
    public let eTag: String

    public init(
      id: String,
      updated: Date,
      eTag: String,
      name: OptionalChange<String> = .noChange,
      type: OptionalChange<String> = .noChange,
      status: OptionalChange<String> = .noChange,
      externalId: OptionalChange<String> = .noChange,
      profileURL: OptionalChange<URL> = .noChange,
      email: OptionalChange<String> = .noChange,
      custom: OptionalChange<FlatJSONCodable> = .noChange
    ) {
      self.id = id
      self.updated = updated
      self.eTag = eTag
      self.name = name
      self.type = type
      self.status = status
      self.externalId = externalId
      self.profileURL = profileURL
      self.email = email
      self.custom = custom
    }

    /// Apply the patch to a target User
    ///
    /// It's recommended to call ``shouldUpdate(userId:eTag:lastUpdated:)`` prior to using this method to ensure
    /// that the Patcher is valid for a given target User.
    /// - Parameters:
    ///   - name: Closure that will be called if the ``PubNubUser/name`` property should be updated
    ///   - type: Closure that will be called if the ``PubNubUser/type`` property should be updated
    ///   - status: Closure that will be called if the ``PubNubUser/status`` property should be updated
    ///   - externalId: Closure that will be called if the ``PubNubUser/externalId`` property should be updated
    ///   - profileURL: Closure that will be called if the ``PubNubUser/profileURL`` property should be updated
    ///   - email: Closure that will be called if the ``PubNubUser/email`` property should be updated
    ///   - custom: Closure that will be called if the ``PubNubUser/custom`` property should be updated
    ///   - updated: Closure that will be called if the ``PubNubUser/updated`` property should be updated
    ///   - eTag: Closure that will be called if the ``PubNubUser/eTag`` property should be updated
    public func apply(
      name: (String?) -> Void,
      type: (String?) -> Void,
      status: (String?) -> Void,
      externalId: (String?) -> Void,
      profileURL: (URL?) -> Void,
      email: (String?) -> Void,
      custom: (FlatJSONCodable?) -> Void,
      updated: (Date) -> Void,
      eTag: (String) -> Void
    ) {
      if self.name.hasChange {
        name(self.name.underlying)
      }
      if self.type.hasChange {
        type(self.type.underlying)
      }
      if self.status.hasChange {
        status(self.status.underlying)
      }
      if self.externalId.hasChange {
        externalId(self.externalId.underlying)
      }
      if self.profileURL.hasChange {
        profileURL(self.profileURL.underlying)
      }
      if self.email.hasChange {
        email(self.email.underlying)
      }
      if self.custom.hasChange {
        custom(self.custom.underlying)
      }
      updated(self.updated)
      eTag(self.eTag)
    }

    /// Should this patch update the target object.
    ///
    /// - Parameters:
    ///   - userId: The unique identifier of the target User
    ///   - eTag: The caching value of the target User.  This is set by the PubNub server
    ///   - lastUpdated: The updated `Date` for the target User.  This is set by the PubNub server.
    ///  - Returns:Whether the target User should be patched
    public func shouldUpdate(userId: String, eTag: String?, lastUpdated: Date?) -> Bool {
      // eTag and lastUpdated are optionals to allow for patching to still occur on local
      // objects that haven't been synced with the server
      guard id == userId,
            self.eTag != eTag,
            updated.timeIntervalSince(lastUpdated ?? .distantPast) > 0 else {
        return false
      }

      return true
    }
  }
}

public extension PubNubUser {
  /// Attempt to apply the updates from a ``Patcher`` to this `PubNubUser`
  ///
  /// This will also validate that the ``Patcher`` should be applied to this User
  /// - Parameter patch: ``Patcher`` that will attempt to be applied
  /// - returns: An updated `PubNubUser` with the patched values, or the same object if no patch was applied.
  func apply(_ patch: PubNubUser.Patcher) -> PubNubUser {
    guard patch.shouldUpdate(userId: id, eTag: eTag, lastUpdated: updated) else {
      return self
    }

    var mutableSelf = self

    patch.apply(
      name: { mutableSelf.name = $0 },
      type: { mutableSelf.type = $0 },
      status: { mutableSelf.status = $0 },
      externalId: { mutableSelf.externalId = $0 },
      profileURL: { mutableSelf.profileURL = $0 },
      email: { mutableSelf.email = $0 },
      custom: { mutableSelf.custom = $0 },
      updated: { mutableSelf.updated = $0 },
      eTag: { mutableSelf.eTag = $0 }
    )

    return mutableSelf
  }
}

// MARK: Hashable

extension PubNubUser.Patcher: Hashable {
  public static func == (lhs: PubNubUser.Patcher, rhs: PubNubUser.Patcher) -> Bool {
    return lhs.id == rhs.id &&
      lhs.name == rhs.name &&
      lhs.type == rhs.type &&
      lhs.status == rhs.status &&
      lhs.externalId == rhs.externalId &&
      lhs.profileURL == rhs.profileURL &&
      lhs.email == rhs.email &&
      lhs.custom.underlying?.codableValue == rhs.custom.underlying?.codableValue &&
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
    hasher.combine(custom.underlying?.codableValue)
    hasher.combine(updated)
    hasher.combine(eTag)
  }
}

// MARK: Codable

extension PubNubUser.Patcher: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubUser.CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)

    // Change Options
    name = try container.decode(OptionalChange<String>.self, forKey: .name)
    type = try container.decode(OptionalChange<String>.self, forKey: .type)
    status = try container.decode(OptionalChange<String>.self, forKey: .status)
    externalId = try container.decode(OptionalChange<String>.self, forKey: .externalId)
    email = try container.decode(OptionalChange<String>.self, forKey: .email)

    profileURL = try container
      .decode(OptionalChange<String>.self, forKey: .profileUrl)
      .mapValue {
        guard let url = URL(string: $0) else {
          throw DecodingError.valueNotFound(
            URL.self,
            DecodingError.Context(
              codingPath: [PubNubUser.CodingKeys.profileUrl],
              debugDescription: "String found at key `profileUrl` was not able to be decoded into a URL"
            )
          )
        }
        return url
      }

    custom = try container
      .decode(OptionalChange<[String: JSONCodableScalarType]>.self, forKey: .custom)
      .mapValue { FlatJSON(flatJSON: $0) }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: PubNubUser.CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)

    try container.encode(name, forKey: .name)
    try container.encode(type, forKey: .type)
    try container.encode(status, forKey: .status)
    try container.encode(externalId, forKey: .externalId)
    try container.encode(email, forKey: .email)
    try container.encode(
      profileURL.mapValue { $0.absoluteString }, forKey: .profileUrl
    )
    try container.encode(
      custom.mapValue { $0.codableValue }, forKey: .custom
    )
  }
}
