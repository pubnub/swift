//
//  Patcher+PubNubMembership.swift
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

public extension PubNubMembership {
  /// Object that can be used to apply an update to another Space
  struct Patcher {
    /// The unique identifier for the User half of this User-Space Membership relationship
    public let userId: String
    /// The unique identifier for the Space half of this User-Space Membership relationship
    public let spaceId: String
    /// The current state of the Space
    public let status: OptionalChange<String>
    /// All custom fields set on the User
    public let custom: OptionalChange<FlatJSONCodable>
    /// The timestamp of the change
    public let updated: Date
    /// The cache identifier of the change
    public let eTag: String

    public init(
      userId: String,
      spaceId: String,
      updated: Date,
      eTag: String,
      status: OptionalChange<String> = .noChange,
      custom: OptionalChange<FlatJSONCodable> = .noChange
    ) {
      self.userId = userId
      self.spaceId = spaceId
      self.updated = updated
      self.eTag = eTag
      self.status = status
      self.custom = custom
    }

    /// Should this patch update the target object.
    ///
    /// - Parameters:
    ///   - spaceId: The unique identifier for the Space half of this User-Space Membership relationship
    ///   - userId: The unique identifier for the User half of this User-Space Membership relationship
    ///   - eTag: The caching value of the target Space.  This is set by the PubNub server
    ///   - lastUpdated: The updated `Date` for the target Space.  This is set by the PubNub server.
    ///  - Returns:Whether the target Space should be patched
    public func shouldUpdate(
      userId: String, spaceId: String, eTag: String?, lastUpdated: Date?
    ) -> Bool {
      // eTag and lastUpdated are optionals to allow for patching to still occur on local
      // objects that haven't been synced with the server
      guard self.spaceId == spaceId, self.userId == userId, self.eTag != eTag,
            updated.timeIntervalSince(lastUpdated ?? .distantPast) > 0 else {
        return false
      }

      return true
    }

    /// Apply the patch to a target Space
    ///
    /// It's recommended to call ``shouldUpdate(spaceId:eTag:lastUpdated:)`` prior to using this method to ensure
    /// that the Patcher is valid for a given target Space.
    /// - Parameters:
    ///   - status: Closure that will be called if the `membership.status` should be updated
    ///   - custom: Closure that will be called if the `membership.custom` should be updated
    ///   - updated: Closure that will be called if the `membership.updated` should be updated
    ///   - eTag: Closure that will be called if the `membership.eTag` should be updated
    public func apply(
      status: (String?) -> Void,
      custom: (FlatJSONCodable?) -> Void,
      updated: (Date) -> Void,
      eTag: (String) -> Void
    ) {
      if self.status.hasChange {
        status(self.status.underlying)
      }
      if self.custom.hasChange {
        custom(self.custom.underlying)
      }
      updated(self.updated)
      eTag(self.eTag)
    }
  }
}

public extension PubNubMembership {
  /// Attempt to apply the updates from a ``Patcher`` to this `PubNubSpace`
  ///
  /// This will also validate that the ``Patcher`` should be applied to this Space
  /// - Parameter patch: ``Patcher`` that will attempt to be applied
  /// - returns: An updated `PubNubSpace` with the patched values, or the same object if no patch was applied.
  func apply(_ patch: PubNubMembership.Patcher) -> PubNubMembership {
    guard patch.shouldUpdate(
      userId: user.id, spaceId: space.id, eTag: eTag, lastUpdated: updated
    ) else {
      return self
    }

    var mutableSelf = self

    patch.apply(
      status: { mutableSelf.status = $0 },
      custom: { mutableSelf.custom = $0 },
      updated: { mutableSelf.updated = $0 },
      eTag: { mutableSelf.eTag = $0 }
    )

    return mutableSelf
  }
}

// MARK: Hashable

extension PubNubMembership.Patcher: Hashable {
  public static func == (lhs: PubNubMembership.Patcher, rhs: PubNubMembership.Patcher) -> Bool {
    return lhs.userId == rhs.userId &&
      lhs.spaceId == rhs.spaceId &&
      lhs.status == rhs.status &&
      lhs.custom.underlying?.codableValue == rhs.custom.underlying?.codableValue &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(userId)
    hasher.combine(spaceId)
    hasher.combine(status)
    hasher.combine(custom.underlying?.codableValue)
    hasher.combine(updated)
    hasher.combine(eTag)
  }
}

// MARK: Codable

extension PubNubMembership.Patcher: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubMembership.CodingKeys.self)
    userId = try container.decode(PubNubUser.self, forKey: .user).id
    spaceId = try container.decode(PubNubSpace.self, forKey: .space).id
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)

    // Change Options
    status = try container.decode(OptionalChange<String>.self, forKey: .status)
    custom = try container
      .decode(OptionalChange<[String: JSONCodableScalarType]>.self, forKey: .custom)
      .mapValue { FlatJSON(flatJSON: $0) }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: PubNubMembership.CodingKeys.self)
    try container.encode(PubNubUser(id: userId), forKey: .user)
    try container.encode(PubNubSpace(id: spaceId), forKey: .space)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)

    try container.encode(status, forKey: .status)
    try container.encode(
      custom.mapValue { $0.codableValue }, forKey: .custom
    )
  }
}
